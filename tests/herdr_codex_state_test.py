import importlib.util
import json
from pathlib import Path
import shlex
import tempfile
import unittest


MODULE = Path(__file__).resolve().parents[1] / "bootstrap/herdr-codex-state.py"
spec = importlib.util.spec_from_file_location("herdr_codex_state", MODULE)
state = importlib.util.module_from_spec(spec)
spec.loader.exec_module(state)


class CodexStateTest(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix="codex-state-test-")
        self.addCleanup(self.temporary.cleanup)
        self.home = Path(self.temporary.name) / "Codex's home"

    def complete(self):
        self.home.mkdir(parents=True)
        (self.home / "herdr-agent-state.sh").write_text(
            "#!/bin/sh\n# installed by herdr\n# HERDR_INTEGRATION_ID=codex\n"
            "# HERDR_INTEGRATION_VERSION=1\n"
        )
        self.hooks = {
            "hooks": {"SessionStart": [{"hooks": [{
                "type": "command",
                "command": shlex.join(["bash", str(self.home / "herdr-agent-state.sh"), "session"]),
                "timeout": 10,
            }]}]}
        }
        self.write_hooks()
        (self.home / "config.toml").write_text('[features]\nhooks = true\n')

    def write_hooks(self):
        (self.home / "hooks.json").write_text(json.dumps(self.hooks))

    def assert_state(self, expected):
        before = {
            path: path.read_bytes()
            for path in self.home.glob("*") if path.is_file()
        }
        inspected = state.inspect(self.home)
        self.assertEqual(inspected["state"], expected, inspected)
        self.assertEqual(Path(inspected["home"]), self.home)
        self.assertEqual(before, {path: path.read_bytes() for path in before})
        return inspected

    def test_absent_home_is_missing_and_not_created(self):
        self.assert_state("missing")
        self.assertFalse(self.home.exists())

    def test_complete_is_not_a_version_freshness_check(self):
        self.complete()
        self.assert_state("complete")

    def test_missing_script_is_partial(self):
        self.complete()
        (self.home / "herdr-agent-state.sh").unlink()
        self.assert_state("partial")

    def test_missing_hooks_file_is_partial(self):
        self.complete()
        (self.home / "hooks.json").unlink()
        self.assert_state("partial")

    def test_missing_config_is_partial(self):
        self.complete()
        (self.home / "config.toml").unlink()
        self.assert_state("partial")

    def test_missing_feature_flag_is_partial(self):
        self.complete()
        (self.home / "config.toml").write_text('model = "fixture-model"\n')
        self.assert_state("partial")

    def test_explicit_disable_is_a_conflict(self):
        self.complete()
        (self.home / "config.toml").write_text('[features]\nhooks = false\n')
        self.assert_state("conflict")

    def test_invalid_toml_is_a_conflict_without_echoing_contents(self):
        self.complete()
        (self.home / "config.toml").write_text('[features\nprivate_value = "do-not-print"\n')
        inspected = self.assert_state("conflict")
        self.assertNotIn("do-not-print", json.dumps(inspected))

    def test_invalid_json_is_a_conflict(self):
        self.complete()
        (self.home / "hooks.json").write_text('{invalid JSON')
        self.assert_state("conflict")

    def test_non_json_numeric_constants_are_conflicts(self):
        self.complete()
        for constant in ("NaN", "Infinity", "-Infinity"):
            with self.subTest(constant=constant):
                (self.home / "hooks.json").write_text('{"unrelated":' + constant + '}')
                self.assert_state("conflict")

    def test_invalid_relevant_shapes_are_conflicts(self):
        self.complete()
        for hooks in ([], {"hooks": []}, {"hooks": {"SessionStart": {}}},
                      {"hooks": {"SessionStart": [None]}}):
            with self.subTest(hooks=hooks):
                (self.home / "hooks.json").write_text(json.dumps(hooks))
                self.assert_state("conflict")

    def test_unrecognized_script_is_a_conflict(self):
        self.complete()
        (self.home / "herdr-agent-state.sh").write_text('#!/bin/sh\necho local-customization\n')
        self.assert_state("conflict")

    def test_registration_for_another_home_is_not_complete(self):
        self.complete()
        self.hooks["hooks"]["SessionStart"][0]["hooks"][0]["command"] = 'bash /another/home/herdr-agent-state.sh session'
        self.write_hooks()
        self.assert_state("partial")

    def test_restricted_matcher_is_not_complete(self):
        self.complete()
        self.hooks["hooks"]["SessionStart"][0]["matcher"] = "resume"
        self.write_hooks()
        self.assert_state("partial")

    def test_unrelated_shell_commands_are_not_reparsed_as_herdr(self):
        self.complete()
        self.hooks["hooks"]["SessionStart"].append({"hooks": [{
            "type": "command", "command": "echo $'can\\'t'"
        }]})
        self.write_hooks()
        self.assert_state("complete")

    def test_unrelated_hooks_without_herdr_are_missing(self):
        self.complete()
        (self.home / "herdr-agent-state.sh").unlink()
        self.hooks["hooks"]["SessionStart"][0]["hooks"][0]["command"] = "echo unrelated"
        self.write_hooks()
        self.assert_state("missing")

    def test_symlinked_managed_files_are_conflicts(self):
        self.complete()
        for name in ("config.toml", "hooks.json", "herdr-agent-state.sh"):
            with self.subTest(name=name):
                file = self.home / name
                target = self.home / (name + ".original")
                file.rename(target)
                file.symlink_to(target)
                self.assert_state("conflict")
                file.unlink()
                target.rename(file)

    def test_symlinked_home_is_a_conflict(self):
        self.complete()
        alias = self.home.parent / "alias"
        alias.symlink_to(self.home, target_is_directory=True)
        self.assertEqual(state.inspect(alias)["state"], "conflict")

    def test_directory_at_managed_filename_is_a_conflict(self):
        self.complete()
        (self.home / "hooks.json").unlink()
        (self.home / "hooks.json").mkdir()
        self.assert_state("conflict")


if __name__ == "__main__":
    unittest.main()
