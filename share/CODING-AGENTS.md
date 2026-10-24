# Coding-agent setup with bootstrap scripts

The [workstation bootstrap scripts](../README.md#bootstrap-scripts) run [`bootstrap/coding-agents.sh`](../bootstrap/coding-agents.sh). Herdr's Codex, Claude Code, OpenCode, and Copilot setup requires Python 3.11+ and jq; the bootstrap scripts do not install or upgrade Python automatically.

To provision coding agents separately, run from the repository root:

```sh
./bootstrap/coding-agents.sh
```

## Authentication

Start each agent and follow its authentication flow:

```sh
claude
codex
opencode
pi
```

Omarchy installs these agents through its existing `mise` launchers the first time each command runs. Other platforms use the agents' official installers when the bootstrap scripts run.

## Herdr installation and updates

The bootstrap scripts also install [Herdr](https://herdr.dev/docs/install/): the Homebrew formula `herdr` on macOS, or the official checksum-verifying installer on Ubuntu, Fedora, Arch, and Omarchy. The Linux installer selects the x86-64 or ARM64 release and defaults to `~/.local/bin/herdr`; Omarchy keeps its existing agent launchers. Existing Herdr commands on `PATH` are left untouched, regardless of installation method. Start it manually with `herdr`; the bootstrap scripts install its Pi, Codex, Claude Code, OpenCode, and GitHub Copilot CLI integrations but do not launch Herdr, install integrations for other agents, or replace tmux.

Update Homebrew installations with `./update.sh` or `brew upgrade herdr`, not `herdr update`. Direct Linux installations use `herdr update` separately; `./update.sh` does not update those installations. Intel Macs may require a source build with Rust and Zig when no Homebrew bottle is available.

## Pi installation and migration

For a missing Pi installation, the bootstrap scripts use the [pi.dev installer](https://pi.dev/docs/latest/quickstart#1-install-pi), which pins all dependencies; update it later with `pi update`. The installer may prompt to start Pi immediately: choose **n** to let the bootstrap scripts continue. Existing Pi installations are left untouched. To migrate an existing npm installation to the managed installer, run `curl -fsSL https://pi.dev/install.sh | sh` separately and confirm migration; the installer verifies the managed release before removing the npm installation. Direct npm installation remains supported upstream but no longer pins transitive dependencies.

## RevDiff and Pi packages

The bootstrap scripts also install [RevDiff](https://github.com/umputun/revdiff). macOS uses its Homebrew formula; Linux installs the checksummed release archive in `~/.local/bin`. Claude Code and Codex receive the `revdiff` and `revdiff-planning` marketplace plugins. Pi receives the RevDiff package plus the [pi-subagents](https://github.com/nicobailon/pi-subagents), [pi-web-access](https://github.com/nicobailon/pi-web-access), [pi-intercom](https://github.com/nicobailon/pi-intercom), and [pi-voice-stt](https://github.com/cgarrot/pi-voice-stt) npm packages. OpenCode receives the RevDiff command, tool, and plan-review plugin. Start a new agent session after running the bootstrap scripts; in Codex, open `/hooks` and trust the RevDiff planning hook before using automatic Plan-mode review.

## Shared harness configuration

The bootstrap scripts clone [drafael/coding-harness](https://github.com/drafael/coding-harness) to `~/code/harness`, preferring SSH and warning before falling back to HTTPS. Existing HTTPS or SSH checkouts are left at their current revision.

The bootstrap scripts link the harness skills into `~/.agents/skills` and `~/.claude/skills`. They also link the shared Pi themes, prompts, `stt.json`, and `AGENTS.md` under `~/.pi/agent`, create `~/.agents/AGENTS.md`, and link `CLAUDE.md` to `~/.claude/CLAUDE.md`. These conflicting paths are backed up under `~/.dotfiles-backups/` before replacement.

### Pi extension links

Pi's `extensions/` stays a real, machine-local directory. The bootstrap scripts link each Git-tracked, direct `.ts` or `.js` harness extension individually; untracked source experiments are not linked. Herdr generates its own regular `herdr-agent-state.ts` there, outside the harness checkout. `PI_CODING_AGENT_DIR` overrides the extension directory and Herdr integration destination; the other harness links keep their existing destinations. Do not also load the linked files through Pi's `settings.extensions` or a local package declaration, which can load them twice.

An existing whole-directory symlink is migrated only if it points to the expected harness directory and contains no extra entries. The old link is backed up without changing its target. Identical regular extension copies are backed up and replaced with file links. Modified files, foreign links, directories at extension filenames, and a versioned `herdr-agent-state.ts` are conflicts: the bootstrap scripts stop for manual resolution rather than overwriting them. Unrelated local extensions stay untouched. Backups live outside Pi's discovery directory; their location is printed by the bootstrap scripts. After a source rename or removal, broken extension links are reported and left for manual retirement.

## Herdr integrations

### Pi

After establishing the links, the bootstrap scripts run `herdr integration install pi` only if the integration is missing. Existing regular integration files are preserved. After upgrading Herdr, refresh explicitly with the same command, then restart Pi or run `/reload`. `herdr integration status` reports the integration version; the bootstrap scripts do not parse that human-readable output or upgrade integrations automatically. Live status reporting and session resume require Pi to run inside Herdr.

### Codex

Codex integration setup requires Python 3.11+ (standard-library TOML parsing) and jq on `PATH`; the bootstrap scripts check this prerequisite rather than installing or upgrading Python automatically. They inspect `${CODEX_HOME:-$HOME/.codex}/herdr-agent-state.sh`, `hooks.json`, and `config.toml` before invoking Herdr. A structurally complete integration is left untouched. A missing or recognized partial integration is installed or repaired with `herdr integration install codex`, after backing up existing affected files under `~/.dotfiles-backups/`. Herdr merges its SessionStart registration and enables `[features].hooks`; unrelated settings and hooks are preserved by its native installer.

Malformed configuration, symlinked managed paths, an unrecognized script at Herdr's filename, and explicitly disabled `features.hooks = false` stop Codex setup before native writes. If hooks are disabled intentionally, review that choice before enabling them and rerunning. The bootstrap scripts validate all three artifacts after installation: Herdr's own status can report "current" even when the hook registration is missing. Native installation is not a multi-file transaction; on failure, inspect the reported partial state and backups before retrying. Native uninstall leaves `config.toml` unchanged and is not a rollback substitute. Do not run the bootstrap scripts concurrently with other Codex configuration writers. Integration versions are not upgraded automatically; refresh explicitly after Herdr upgrades, as with Pi.

### Claude Code

Claude Code integration setup uses the same Python 3.11+ and jq prerequisites. The bootstrap scripts inspect `${CLAUDE_CONFIG_DIR:-$HOME/.claude}/hooks/herdr-agent-state.sh` and `settings.json`. A complete integration is left untouched, including older script versions. Missing or recognized partial installations are backed up and installed or repaired with `herdr integration install claude`. Herdr merges its SessionStart registration while preserving unrelated settings, plugins, and hooks. The generated script and its directory stay machine-local; existing harness skills and instruction links are unchanged, including their destinations when `CLAUDE_CONFIG_DIR` is set.

Claude setup stops before Herdr writes if settings are malformed, `disableAllHooks` is true, managed paths are symlinks, the script is unrecognized, or a registration for that script has a custom command or matcher. The bootstrap scripts preserve Herdr's native `^(startup|resume|clear|compact|fork)$` matcher rather than broadening it. Resolve custom or legacy registrations manually before rerunning; the bootstrap scripts will not silently broaden their scope. Installation is validated structurally; Herdr's status alone does not detect missing registration or disabled hooks.

Claude backups are saved under `~/.dotfiles-backups/`, with their location printed. On installation failure, inspect both affected paths and the backups before retrying; the bootstrap scripts do not automatically uninstall or restore files. Do not run the bootstrap scripts concurrently with other Claude settings writers. After upgrading Herdr, refresh explicitly with `herdr integration install claude`; the bootstrap scripts do not upgrade complete integrations automatically or restart sessions. Verify activation with a new Claude session inside Herdr. The hook reports session identity; managed or project policies can still prevent execution, and the bootstrap scripts do not validate live hook delivery or session resume.

### OpenCode

OpenCode integration setup also requires Python 3.11+ and jq. It checks three generated files (`plugins/herdr-agent-state.js`, `herdr-tui-session.js`, and `herdr-opencode/tui.js`), the V1 registration in `tui.jsonc` or `tui.json`, and the V2 registration in `cli.json` when migration allows it. These cover the server plugin and both TUI entrypoints. Complete installations are left untouched, regardless of script version; missing or recognized partial installations are backed up and installed or repaired with `herdr integration install opencode`. Native merging preserves unrelated plugin entries, options, and JSONC comments. Other OpenCode configuration files and local plugins are not replaced.

Herdr intentionally leaves `cli.json` absent while V1 preferences in `tui.json` or `${XDG_STATE_HOME:-$HOME/.local/state}/opencode/kv.json` await migration. This is a complete V1 installation, not an error, and does not block the later Copilot integration step. To enable V2, start `opencode2` once to migrate preferences, then rerun the bootstrap scripts. An existing `cli.json` without the Herdr registration still needs repair; the bootstrap scripts do not create placeholder preferences to bypass migration.

Herdr setup selects `OPENCODE_CONFIG_DIR` first, then `$XDG_CONFIG_HOME/opencode`, then `~/.config/opencode`. Herdr's current installer hardcodes `HOME/.config/opencode`, so the bootstrap scripts use a temporary HOME alias for custom destinations and remove it afterward. The alias retains the real state-home path for migration checks. Generated references stay relative; no temporary paths are stored in the integration. These overrides apply to Herdr setup; other OpenCode setup steps are unchanged.

Malformed JSON/JSONC, invalid plugin lists, symlinked managed paths, unrecognized generated files, and custom Herdr references or options stop setup before native writes. Legacy `herdr-agent-state.ts` in `plugins/`, or `herdr-agent-state.js`/`.ts` in `plugin/`, must be retired manually to avoid duplicate discovery. Existing affected files are copied to `~/.dotfiles-backups/` before changes. On failure, inspect the reported paths and backups before retrying; the bootstrap scripts validate generated files and applicable registrations but do not roll back automatically. Avoid concurrent OpenCode configuration writers. The bootstrap scripts do not restart sessions or upgrade complete integrations automatically. Verify live reporting and session selection with a new OpenCode session inside Herdr; the bootstrap scripts check structural installation, not live TUI behavior.

After upgrading Herdr, refresh explicitly with `herdr integration install opencode` for the default destination. For a custom destination, back up the five affected files first, then use this native refresh command; it does not perform the bootstrap scripts' preflight or backups:

```sh
(
  set -eu
  config_dir=${OPENCODE_CONFIG_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/opencode}
  config_dir=$(CDPATH= cd -- "$config_dir" && pwd)
  state_home=${XDG_STATE_HOME:-$HOME/.local/state}
  native_home=$(mktemp -d "${TMPDIR:-/tmp}/herdr-opencode-home.XXXXXX")
  trap 'rm -rf "$native_home"' EXIT
  trap 'exit 1' HUP INT TERM
  mkdir "$native_home/.config"
  ln -s "$config_dir" "$native_home/.config/opencode"
  HOME="$native_home" XDG_STATE_HOME="$state_home" herdr integration install opencode
)
```

### GitHub Copilot CLI

GitHub Copilot CLI integration setup uses the same Python 3.11+ and jq prerequisites. It selects `${COPILOT_HOME:-$HOME/.copilot}` and inspects `hooks/herdr-agent-state.sh` plus `settings.json`. Copilot uses a flat `hooks.SessionStart` array with `type: "command"`, a `bash` command, and `timeoutSec`; it does not use Claude's nested hook groups or the script's `session` argument. The bootstrap scripts configure the integration without installing or authenticating Copilot CLI, and they do not configure an editor extension. New Copilot home directories are created with mode 700; existing directory permissions are unchanged. Copilot's `config.json` and repository-level hooks are not modified.

Complete Copilot integrations are left untouched, including older script versions and local script edits. Missing or recognized partial installations are backed up and installed or repaired with `herdr integration install copilot`. Unrelated settings, Bash hooks, and PowerShell hooks are preserved. Invalid configuration, symlinked managed paths, unrecognized scripts, `disableAllHooks: true`, duplicate Herdr registrations, and custom Herdr commands or matchers stop setup before native writes. Herdr compares command text when merging: an equivalent non-native command spelling is preserved when complete, but a missing script with that registration requires manual resolution to avoid appending a duplicate hook.

Existing affected files are copied to `~/.dotfiles-backups/`, with their location printed. The bootstrap scripts validate both artifacts after native installation; on failure, inspect the reported partial state and backups before retrying. There is no automatic uninstall or rollback. Avoid concurrent Copilot settings writers. After upgrading Herdr, refresh explicitly with `herdr integration install copilot`, setting `COPILOT_HOME` for custom destinations. The bootstrap scripts do not upgrade complete integrations automatically or restart sessions. The hook reports session identity; verify live delivery and resume with a new Copilot session inside Herdr. Structural checks do not prove live integration behavior.

## Pi Voice STT

Pi Voice STT uses the harness provider profiles and the plugin's platform capture defaults: `avfoundation` / `:0` on macOS and `pulse` / `default` on Linux (PulseAudio or PipeWire's PulseAudio compatibility service). Microphone capture requires `ffmpeg`, a working input device, and the selected provider's API key (the shared default uses `GROQ_API_KEY`). On Linux, check that `ffmpeg -devices` lists `pulse`; ALSA-only systems can use `capture.inputFormat: "alsa"` and `capture.input: "default"` in a machine-specific config selected with `PI_STT_CONFIG`. Audio-file transcription does not require microphone capture. The bootstrap scripts do not test microphones or configure audio services. If an older harness checkout lacks `stt.json`, the bootstrap scripts warn and leave the local STT config untouched; update the checkout manually and rerun the bootstrap scripts.
