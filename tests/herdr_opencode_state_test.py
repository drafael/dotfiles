import importlib.util
import json
import os
from pathlib import Path
import tempfile
import unittest


MODULE = Path(__file__).resolve().parents[1] / "bootstrap/herdr-opencode-state.py"
spec = importlib.util.spec_from_file_location("herdr_opencode_state", MODULE)
state = importlib.util.module_from_spec(spec)
spec.loader.exec_module(state)


class JsoncTest(unittest.TestCase):
    def test_comments_trailing_commas_and_strings(self):
        text = r'''
        // fixture comment
        {
          "url": "https://fixture.invalid/a//b/*c*/",
          "quoted": "a\"b\\c,]}",
          "plugin": ["fixture", /* comment */],
          "nested": {"values": [true, false, null, 1, -1.2e3,],},
        }
        '''
        parsed = state.parse_jsonc(text)
        self.assertEqual(parsed["url"], "https://fixture.invalid/a//b/*c*/")
        self.assertEqual(parsed["quoted"], 'a"b\\c,]}')
        self.assertEqual(parsed["plugin"], ["fixture"])
        self.assertEqual(parsed["nested"], {"values": [True, False, None, 1, -1200]})

    def test_strict_json_values_are_unchanged(self):
        values = [None, True, False, 0, -1.2e20, {}, [],
                  {"empty": "", "text": "// /* */ ,]} \" \\ \n café", "array": [{}, []]}]
        for value in values:
            with self.subTest(value=value):
                self.assertEqual(state.parse_jsonc(json.dumps(value)), value)

    def test_invalid_jsonc_is_not_repaired_into_valid_json(self):
        for text in ('{,}', '[,]', '[1,,]', '{"key":,}', '[1 2]',
                     '/* unfinished', '{"key":"unfinished}', '{"key":undefined}',
                     '{"key":NaN}', '{"key":Infinity}', '{"key":-Infinity}',
                     '\ufeff{}'):
            with self.subTest(text=text):
                with self.assertRaises(ValueError):
                    state.parse_jsonc(text)


class OpenCodeStateTest(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix="opencode-state-test-")
        self.addCleanup(self.temporary.cleanup)
        self.home = Path(self.temporary.name) / "OpenCode's home"
        self.generated = {
            "plugins/herdr-agent-state.js": "opencode",
            "herdr-tui-session.js": "opencode-tui",
            "herdr-opencode/tui.js": "opencode-tui-v2",
        }
        self.configs = {
            "tui.jsonc": ("plugin", "./herdr-tui-session.js"),
            "cli.json": ("plugins", "./herdr-opencode"),
        }

    def complete(self):
        for relative, integration_id in self.generated.items():
            path = self.home / relative
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(
                f"// installed by herdr\n// HERDR_INTEGRATION_ID={integration_id}\n"
                "// HERDR_INTEGRATION_VERSION=1\n"
            )
        for relative, (key, reference) in self.configs.items():
            (self.home / relative).write_text(json.dumps({key: [reference]}))

    def assert_state(self, expected):
        before = {path: path.read_bytes() for path in self.home.rglob("*") if path.is_file()}
        inspected = state.inspect(self.home)
        self.assertEqual(inspected["state"], expected, inspected)
        self.assertEqual(inspected["home"], str(self.home))
        self.assertEqual(before, {path: path.read_bytes() for path in self.home.rglob("*") if path.is_file()})
        return inspected

    def test_absent_home_is_missing_and_not_created(self):
        self.assert_state("missing")
        self.assertFalse(self.home.exists())

    def test_complete_does_not_require_latest_plugin_version(self):
        self.complete()
        self.assert_state("complete")

    def test_each_missing_generated_file_is_partial(self):
        self.complete()
        for relative in self.generated:
            with self.subTest(relative=relative):
                path = self.home / relative
                content = path.read_bytes()
                path.unlink()
                self.assert_state("partial")
                path.write_bytes(content)

    def test_each_missing_config_is_partial(self):
        self.complete()
        for relative in self.configs:
            with self.subTest(relative=relative):
                path = self.home / relative
                content = path.read_bytes()
                path.unlink()
                self.assert_state("partial")
                path.write_bytes(content)

    def test_each_missing_registration_is_partial(self):
        self.complete()
        for relative in self.configs:
            with self.subTest(relative=relative):
                path = self.home / relative
                content = path.read_bytes()
                path.write_text('{}')
                self.assert_state("partial")
                path.write_bytes(content)

    def test_registrations_without_plugins_are_partial(self):
        self.complete()
        for relative in self.generated:
            (self.home / relative).unlink()
        self.assert_state("partial")

    def test_unrelated_configs_and_plugins_are_not_owned(self):
        self.home.mkdir()
        (self.home / "tui.jsonc").write_text('// fixture\n{"plugin":["user-plugin", ["other", {"option":true}]],}')
        (self.home / "opencode.jsonc").write_text('{untouched by Herdr')
        self.assert_state("missing")

    def test_jsonc_comments_and_unrelated_options_remain_complete(self):
        self.complete()
        (self.home / "tui.jsonc").write_text(
            '// fixture comment\n{"theme":"fixture", "plugin":["./herdr-tui-session.js", "user-plugin",],}\n'
        )
        self.assert_state("complete")

    def test_malformed_configs_do_not_echo_contents(self):
        self.complete()
        for relative in self.configs:
            with self.subTest(relative=relative):
                path = self.home / relative
                content = path.read_bytes()
                path.write_text('{invalid "private_value":"do-not-print"}')
                inspected = self.assert_state("conflict")
                self.assertNotIn("do-not-print", json.dumps(inspected))
                path.write_bytes(content)

    def test_invalid_plugin_shapes_are_conflicts(self):
        self.complete()
        path = self.home / "tui.jsonc"
        for config in ([], {"plugin": False}, {"plugin": [None]},
                       {"plugin": [["fixture"]]}, {"plugin": [["fixture", False]]},
                       {"plugin": [{"path": "fixture"}]}):
            with self.subTest(config=config):
                path.write_text(json.dumps(config))
                self.assert_state("conflict")

    def test_custom_herdr_options_require_manual_review(self):
        self.complete()
        for relative, (key, reference) in self.configs.items():
            with self.subTest(relative=relative):
                path = self.home / relative
                content = path.read_bytes()
                path.write_text(json.dumps({key: [[reference, {"enabled": False}]]}))
                self.assert_state("conflict")
                path.write_bytes(content)

    def test_custom_herdr_references_are_not_duplicated(self):
        self.complete()
        for relative, (key, reference) in self.configs.items():
            with self.subTest(relative=relative):
                path = self.home / relative
                content = path.read_bytes()
                absolute = self.home / reference.removeprefix("./")
                for entry in (str(absolute), absolute.as_uri(), reference.removeprefix("./")):
                    path.write_text(json.dumps({key: [entry]}))
                    self.assert_state("conflict")
                path.write_bytes(content)

    def test_unrecognized_generated_files_are_conflicts(self):
        self.complete()
        for relative in self.generated:
            with self.subTest(relative=relative):
                path = self.home / relative
                content = path.read_bytes()
                path.write_text('// local customization without Herdr ownership\n')
                self.assert_state("conflict")
                path.write_bytes(content)

    def test_legacy_autoloaded_plugins_are_conflicts(self):
        self.complete()
        for relative in ("plugins/herdr-agent-state.ts", "plugin/herdr-agent-state.js", "plugin/herdr-agent-state.ts"):
            with self.subTest(relative=relative):
                path = self.home / relative
                path.parent.mkdir(exist_ok=True)
                path.write_text('// legacy fixture\n')
                self.assert_state("conflict")
                path.unlink()

    def test_symlinked_managed_files_are_conflicts(self):
        self.complete()
        for relative in (*self.generated, *self.configs):
            with self.subTest(relative=relative):
                path = self.home / relative
                target = path.with_suffix(".original")
                path.rename(target)
                path.symlink_to(target)
                self.assert_state("conflict")
                path.unlink()
                target.rename(path)

    def test_symlinked_managed_directories_are_conflicts(self):
        self.complete()
        for relative in ("plugins", "herdr-opencode", "."):
            with self.subTest(relative=relative):
                path = self.home / relative
                target = path.with_name(path.name + "-target")
                path.rename(target)
                path.symlink_to(target, target_is_directory=True)
                self.assert_state("conflict")
                path.unlink()
                target.rename(path)

    def test_broken_managed_or_legacy_symlinks_are_conflicts(self):
        self.home.mkdir()
        for relative in ("tui.jsonc", "plugins", "plugin/herdr-agent-state.ts"):
            with self.subTest(relative=relative):
                path = self.home / relative
                path.parent.mkdir(exist_ok=True)
                path.symlink_to(self.home / "absent")
                self.assert_state("conflict")
                path.unlink()

    def test_wrong_path_types_are_conflicts(self):
        self.home.mkdir()
        (self.home / "plugins").write_text('not a directory')
        self.assert_state("conflict")
        (self.home / "plugins").unlink()
        (self.home / "cli.json").mkdir()
        self.assert_state("conflict")

    def test_invalid_utf8_is_a_conflict(self):
        self.complete()
        for relative in ("plugins/herdr-agent-state.js", "tui.jsonc"):
            with self.subTest(relative=relative):
                path = self.home / relative
                content = path.read_bytes()
                path.write_bytes(b"\xff")
                self.assert_state("conflict")
                path.write_bytes(content)

    def test_relative_home_is_reported_as_absolute(self):
        relative = Path(os.path.relpath(self.home))
        self.assertEqual(state.inspect(relative)["home"], str(self.home))


if __name__ == "__main__":
    unittest.main()
