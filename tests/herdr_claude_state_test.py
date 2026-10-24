import importlib.util
import json
import os
from pathlib import Path
import shlex
import tempfile
import unittest


MODULE = Path(__file__).resolve().parents[1] / "bootstrap/herdr-claude-state.py"
spec = importlib.util.spec_from_file_location("herdr_claude_state", MODULE)
state = importlib.util.module_from_spec(spec)
spec.loader.exec_module(state)


class ClaudeStateTest(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix="claude-state-test-")
        self.addCleanup(self.temporary.cleanup)
        self.home = Path(self.temporary.name) / "Claude's home"
        self.script = self.home / "hooks/herdr-agent-state.sh"
        self.settings_path = self.home / "settings.json"

    def complete(self):
        self.script.parent.mkdir(parents=True)
        self.script.write_text(
            "#!/bin/sh\n# installed by herdr\n# HERDR_INTEGRATION_ID=claude\n"
            "# HERDR_INTEGRATION_VERSION=1\n"
        )
        self.settings = {
            "hooks": {"SessionStart": [{
                "matcher": "^(startup|resume|clear|compact|fork)$",
                "hooks": [{
                    "type": "command",
                    "command": shlex.join(["bash", str(self.script), "session"]),
                    "timeout": 10,
                }],
            }]}
        }
        self.write_settings()

    def write_settings(self):
        self.settings_path.write_text(json.dumps(self.settings))

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

    def test_complete_does_not_require_latest_script_version(self):
        self.complete()
        self.assert_state("complete")

    def test_explicitly_enabled_hooks_are_complete(self):
        self.complete()
        self.settings["disableAllHooks"] = False
        self.write_settings()
        self.assert_state("complete")

    def test_missing_script_is_partial(self):
        self.complete()
        self.script.unlink()
        self.assert_state("partial")

    def test_missing_settings_are_partial(self):
        self.complete()
        self.settings_path.unlink()
        self.assert_state("partial")

    def test_missing_registration_is_partial(self):
        self.complete()
        self.settings = {"model": "fixture-model"}
        self.write_settings()
        self.assert_state("partial")

    def test_disabled_hooks_are_a_conflict(self):
        self.complete()
        self.settings["disableAllHooks"] = True
        self.write_settings()
        self.assert_state("conflict")

    def test_invalid_json_does_not_echo_settings(self):
        self.complete()
        self.settings_path.write_text('{invalid "private_value": "do-not-print"}')
        inspected = self.assert_state("conflict")
        self.assertNotIn("do-not-print", json.dumps(inspected))

    def test_non_json_numeric_constants_are_conflicts(self):
        self.complete()
        for constant in ("NaN", "Infinity", "-Infinity"):
            with self.subTest(constant=constant):
                self.settings_path.write_text('{"unrelated":' + constant + '}')
                self.assert_state("conflict")

    def test_invalid_relevant_shapes_are_conflicts(self):
        self.complete()
        for settings in ([], {"hooks": []}, {"hooks": {"SessionStart": {}}},
                         {"hooks": {"SessionStart": [None]}},
                         {"hooks": {"SessionStart": [{"hooks": [None]}]}},
                         {"hooks": {"SessionStart": [{"hooks": [{"type": "command", "command": 7}]}]}},
                         {"disableAllHooks": "false"}):
            with self.subTest(settings=settings):
                self.settings_path.write_text(json.dumps(settings))
                self.assert_state("conflict")

    def test_invalid_utf8_is_a_conflict(self):
        self.complete()
        for path in (self.script, self.settings_path):
            with self.subTest(path=path):
                original = path.read_bytes()
                path.write_bytes(b"\xff")
                self.assert_state("conflict")
                path.write_bytes(original)

    def test_unrecognized_or_wrong_agent_script_is_a_conflict(self):
        self.complete()
        for script in ("#!/bin/sh\necho local-customization\n",
                       "# installed by herdr\n# HERDR_INTEGRATION_ID=codex\n"):
            with self.subTest(script=script):
                self.script.write_text(script)
                self.assert_state("conflict")

    def test_custom_or_legacy_matchers_are_not_silently_changed(self):
        self.complete()
        rule = self.settings["hooks"]["SessionStart"][0]
        for matcher in (None, "", "*", "resume", "startup|resume|clear|compact|fork"):
            with self.subTest(matcher=matcher):
                if matcher is None:
                    rule.pop("matcher", None)
                else:
                    rule["matcher"] = matcher
                self.write_settings()
                self.assert_state("conflict")

    def test_custom_commands_are_not_silently_changed(self):
        self.complete()
        hook = self.settings["hooks"]["SessionStart"][0]["hooks"][0]
        for arguments in (["bash", str(self.script), "custom"],
                          ["env", "bash", str(self.script), "session"]):
            with self.subTest(arguments=arguments):
                hook["command"] = shlex.join(arguments)
                self.write_settings()
                self.assert_state("conflict")

    def test_unparseable_herdr_command_is_a_conflict(self):
        self.complete()
        # No apostrophe in this path, so the literal filename remains recognizable.
        plain_home = self.home.parent / "plain-home"
        plain_home.mkdir()
        command = 'bash "' + str(plain_home / "hooks/herdr-agent-state.sh")
        self.settings["hooks"]["SessionStart"][0]["hooks"][0]["command"] = command
        (plain_home / "settings.json").write_text(json.dumps(self.settings))
        self.assertEqual(state.inspect(plain_home)["state"], "conflict")

    def test_bin_bash_invocation_is_complete(self):
        self.complete()
        self.settings["hooks"]["SessionStart"][0]["hooks"][0]["command"] = shlex.join(
            ["/bin/bash", str(self.script), "session"]
        )
        self.write_settings()
        self.assert_state("complete")

    def test_unrelated_hooks_and_settings_are_untouched(self):
        self.complete()
        self.settings["enabledPlugins"] = {"fixture@local": True}
        self.settings["hooks"]["Stop"] = [{"hooks": [{"type": "command", "command": "echo stop-hook"}]}]
        self.settings["hooks"]["SessionStart"].append({"hooks": [
            {"type": "command", "command": "echo $'can\\'t'"},
            {"type": "prompt", "prompt": "fixture prompt"},
        ]})
        self.write_settings()
        self.assert_state("complete")

    def test_unrelated_registration_is_missing_not_owned(self):
        self.complete()
        self.script.unlink()
        self.settings["hooks"]["SessionStart"][0]["hooks"][0]["command"] = "echo unrelated"
        self.write_settings()
        self.assert_state("missing")

    def test_symlinked_managed_files_are_conflicts(self):
        self.complete()
        for path in (self.script, self.settings_path):
            with self.subTest(path=path):
                target = path.with_suffix(".original")
                path.rename(target)
                path.symlink_to(target)
                self.assert_state("conflict")
                path.unlink()
                target.rename(path)

    def test_symlinked_directories_are_conflicts(self):
        self.complete()
        for directory in (self.script.parent, self.home):
            with self.subTest(directory=directory):
                target = directory.with_name(directory.name + "-target")
                directory.rename(target)
                directory.symlink_to(target, target_is_directory=True)
                self.assert_state("conflict")
                directory.unlink()
                target.rename(directory)

    def test_broken_symlinks_are_conflicts(self):
        self.home.mkdir()
        for path in (self.home / "hooks", self.settings_path):
            with self.subTest(path=path):
                path.symlink_to(self.home / "absent")
                self.assert_state("conflict")
                path.unlink()

    def test_wrong_path_types_are_conflicts(self):
        self.home.mkdir()
        for path in (self.home / "hooks", self.settings_path):
            with self.subTest(path=path):
                if path.name == "hooks":
                    path.write_text("not a directory")
                else:
                    path.mkdir()
                self.assert_state("conflict")
                if path.is_dir():
                    path.rmdir()
                else:
                    path.unlink()

    def test_relative_home_is_reported_as_absolute(self):
        relative = Path(os.path.relpath(self.home))
        self.assertEqual(state.inspect(relative)["home"], str(self.home))


if __name__ == "__main__":
    unittest.main()
