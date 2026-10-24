import importlib.util
import json
import os
from pathlib import Path
import shlex
import tempfile
import unittest


MODULE = Path(__file__).resolve().parents[1] / "bootstrap/herdr-copilot-state.py"
spec = importlib.util.spec_from_file_location("herdr_copilot_state", MODULE)
state = importlib.util.module_from_spec(spec)
spec.loader.exec_module(state)


class CopilotStateTest(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix="copilot-state-test-")
        self.addCleanup(self.temporary.cleanup)
        self.home = Path(self.temporary.name) / "Copilot's home"
        self.script = self.home / "hooks/herdr-agent-state.sh"
        self.settings_path = self.home / "settings.json"

    def complete(self):
        self.script.parent.mkdir(parents=True)
        self.script.write_text(
            "#!/bin/sh\n# installed by herdr\n# HERDR_INTEGRATION_ID=copilot\n"
            "# HERDR_INTEGRATION_VERSION=1\n"
        )
        self.hook = {
            "type": "command",
            "bash": "bash '" + str(self.script).replace("'", "'\"'\"'") + "'",
            "timeoutSec": 10,
        }
        self.settings = {"hooks": {"SessionStart": [self.hook]}}
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

    def test_absent_home_is_missing_without_creation(self):
        self.assert_state("missing")
        self.assertFalse(self.home.exists())

    def test_complete_is_not_a_version_freshness_check(self):
        self.complete()
        self.assert_state("complete")

    def test_flat_registration_without_script_is_partial(self):
        self.complete()
        self.script.unlink()
        self.assert_state("partial")

    def test_missing_settings_or_registration_is_partial(self):
        self.complete()
        self.settings_path.unlink()
        self.assert_state("partial")
        self.settings = {"model": "fixture-model"}
        self.write_settings()
        self.assert_state("partial")

    def test_disabled_hooks_are_a_conflict(self):
        self.complete()
        self.settings["disableAllHooks"] = True
        self.write_settings()
        self.assert_state("conflict")

    def test_explicitly_enabled_hooks_are_complete(self):
        self.complete()
        self.settings["disableAllHooks"] = False
        self.write_settings()
        self.assert_state("complete")

    def test_invalid_json_is_a_conflict_without_echoing_contents(self):
        self.complete()
        self.settings_path.write_text('{invalid "private_value":"do-not-print"}')
        inspected = self.assert_state("conflict")
        self.assertNotIn("do-not-print", json.dumps(inspected))

    def test_non_json_numeric_constants_are_conflicts(self):
        self.complete()
        for constant in ("NaN", "Infinity", "-Infinity"):
            with self.subTest(constant=constant):
                self.settings_path.write_text('{"unrelated":' + constant + '}')
                self.assert_state("conflict")

    def test_invalid_relevant_shapes_and_claude_groups_are_conflicts(self):
        self.complete()
        for settings in ([], {"hooks": []}, {"hooks": {"SessionStart": {}}},
                         {"hooks": {"SessionStart": [None]}},
                         {"hooks": {"SessionStart": [{"hooks": []}]}},
                         {"hooks": {"SessionStart": [{"type": "command", "bash": 7}]}},
                         {"hooks": {"SessionStart": [{"type": "command"}]}},
                         {"disableAllHooks": "false"}):
            with self.subTest(settings=settings):
                self.settings_path.write_text(json.dumps(settings))
                self.assert_state("conflict")

    def test_unrelated_hooks_powershell_and_config_are_not_modified(self):
        self.complete()
        self.settings["model"] = "fixture-model"
        self.settings["hooks"]["SessionStart"].extend([
            {"type": "command", "bash": "echo $'can\\'t'"},
            {"type": "command", "powershell": "Write-Output fixture"},
        ])
        self.settings["hooks"]["Stop"] = [{"type": "command", "bash": "echo fixture-stop"}]
        self.write_settings()
        (self.home / "config.json").write_text('{untouched config is outside this inspector}')
        self.assert_state("complete")

    def test_unrelated_hooks_without_herdr_are_missing(self):
        self.complete()
        self.script.unlink()
        self.hook["bash"] = "echo unrelated"
        self.write_settings()
        self.assert_state("missing")

    def test_non_native_command_spelling_is_preserved_when_complete(self):
        self.complete()
        self.hook["bash"] = shlex.join(["/bin/bash", str(self.script)])
        self.write_settings()
        self.assert_state("complete")

    def test_non_native_command_spelling_cannot_be_repaired_without_duplication(self):
        self.complete()
        self.hook["bash"] = shlex.join(["/bin/bash", str(self.script)])
        self.write_settings()
        self.script.unlink()
        self.assert_state("conflict")

    def test_native_paths_with_redundant_components_are_not_registered_twice(self):
        self.complete()
        redundant = str(self.script.parent) + "/./" + self.script.name
        self.hook["bash"] = "bash '" + redundant.replace("'", "'\"'\"'") + "'"
        self.write_settings()
        self.assert_state("complete")
        self.script.unlink()
        self.assert_state("conflict")

    def test_custom_commands_and_matchers_are_conflicts(self):
        self.complete()
        original = self.hook["bash"]
        self.hook["bash"] = shlex.join(["bash", str(self.script), "custom"])
        self.write_settings()
        self.assert_state("conflict")
        self.hook["bash"] = original
        self.hook["matcher"] = "resume"
        self.write_settings()
        self.assert_state("conflict")

    def test_unparseable_herdr_command_is_a_conflict(self):
        self.complete()
        self.hook["bash"] = 'bash "' + str(self.script)
        self.write_settings()
        self.assert_state("conflict")

    def test_duplicate_managed_registrations_are_conflicts(self):
        self.complete()
        self.settings["hooks"]["SessionStart"].append(dict(self.hook))
        self.write_settings()
        self.assert_state("conflict")

    def test_unrecognized_or_wrong_agent_scripts_are_conflicts(self):
        self.complete()
        for content in ("#!/bin/sh\necho local-customization\n",
                        "# installed by herdr\n# HERDR_INTEGRATION_ID=claude\n"):
            with self.subTest(content=content):
                self.script.write_text(content)
                self.assert_state("conflict")

    def test_invalid_utf8_is_a_conflict(self):
        self.complete()
        for path in (self.script, self.settings_path):
            with self.subTest(path=path):
                content = path.read_bytes()
                path.write_bytes(b"\xff")
                self.assert_state("conflict")
                path.write_bytes(content)

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
        for path in (self.script.parent, self.home):
            with self.subTest(path=path):
                target = path.with_name(path.name + "-target")
                path.rename(target)
                path.symlink_to(target, target_is_directory=True)
                self.assert_state("conflict")
                path.unlink()
                target.rename(path)

    def test_broken_links_and_wrong_path_types_are_conflicts(self):
        self.home.mkdir()
        for path in (self.home / "hooks", self.settings_path):
            with self.subTest(path=path):
                path.symlink_to(self.home / "absent")
                self.assert_state("conflict")
                path.unlink()
        self.settings_path.mkdir()
        self.assert_state("conflict")

    def test_relative_home_is_reported_as_absolute(self):
        relative = Path(os.path.relpath(self.home))
        self.assertEqual(state.inspect(relative)["home"], str(self.home))


if __name__ == "__main__":
    unittest.main()
