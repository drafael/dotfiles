# Installation Guide (Agent-Agnostic)

Use this reference only **after** the user confirms the stack.

## Preferred (source-aware, multi-agent)
Use the Skills CLI only when the skill is known to be supported by it (e.g., discovered via `npx skills find` or listed on skills.sh). Do **not** default to Skills CLI for arbitrary repos.

```bash
npx skills add owner/repo --skill skill-name -a <current-agent> -y
```

Notes:
- `-a` targets agents; use `--all` to install to all detected agents.
- If a user wants project-level only, use the agent’s project skills path instead.
- If the skill did **not** come from Skills CLI discovery, use a source-verified install method instead (see below).
- Do **not** rely on auto‑detect when installing. Always pass `-a <current-agent>` unless the user explicitly asks for multi‑agent installs.
- If a skill was not found via `npx skills find`, verify availability with `npx skills add <repo> --list` before installing via Skills CLI.

## Skills CLI essentials (skills.sh)
Use these only for skills discoverable via Skills CLI (skills.sh).

Source formats:
```bash
# GitHub shorthand (owner/repo)
npx skills add vercel-labs/agent-skills

# Full GitHub URL
npx skills add https://github.com/vercel-labs/agent-skills

# Direct path to a skill in a repo
npx skills add https://github.com/vercel-labs/agent-skills/tree/main/skills/web-design-guidelines

# GitLab URL (including subgroups)
npx skills add https://gitlab.com/org/repo
npx skills add https://gitlab.com/org/subgroup/repo

# Any git URL (including custom Git hosts)
npx skills add git@github.com:vercel-labs/agent-skills.git

# Local path
npx skills add ./my-local-skills
```

Key options (verify in `npx skills --help` if unsure):
- `-g, --global` install to user directory instead of project
- `-a, --agent <agents...>` target specific agents (supports fuzzy matching)
- `-s, --skill <skills...>` install specific skills (use `'*'` for all skills)
- `-l, --list` list available skills without installing
- `-y, --yes` skip confirmation prompts
- `--all` install all skills to all agents without prompts
- `--full-depth` deep directory scanning for repos with nested skills

> **Note:** `npx add-skill` is deprecated. Use `npx skills` for all operations.

```bash
# Search
npx skills find typescript

# List skills in a repo
npx skills add owner/repo --list

# Install specific skills
npx skills add owner/repo --skill skill-a --skill skill-b -a <current-agent> -y

# Install to global scope
npx skills add owner/repo --skill skill-a -g -a <current-agent> -y

# Check for updates / update
npx skills check
npx skills update

# Initialize a new skill
npx skills init my-skill

# Remove skills
npx skills remove web-design-guidelines
```

Installation methods (interactive):
- **Symlink** (recommended): single source of truth, easier updates
- **Copy**: use when symlinks are not supported

## Context7-sourced skills
If a skill came from Context7, follow Context7’s install guidance or CLI output. Do not use `npx skills add` unless the skill is also listed by Skills CLI.

Context7 CLI basics (from official docs):
```bash
# Install the CLI (optional) or run via npx
npm install -g ctx7
npx ctx7 skills search pdf

# Suggest skills based on project dependencies (scans package.json, requirements.txt, pyproject.toml)
ctx7 skills suggest
ctx7 skills suggest --claude

# Install skills from a project
ctx7 skills install /anthropics/skills
ctx7 skills install /anthropics/skills pdf
ctx7 skills install /anthropics/skills pdf commit

# Target a specific client (--claude, --cursor, --codex, --opencode, --amp, --antigravity)
ctx7 skills install /anthropics/skills pdf --cursor
ctx7 skills install /anthropics/skills pdf --claude

# Install globally (home directory)
ctx7 skills install /anthropics/skills pdf --global

# List installed skills
ctx7 skills list
ctx7 skills list --claude
ctx7 skills list --cursor
ctx7 skills list --global

# Show info / remove
ctx7 skills info /anthropics/skills
ctx7 skills remove pdf
ctx7 skills remove pdf --claude
ctx7 skills remove pdf --global
```

Context7 scope note:
- Context7 CLI auto‑detects supported clients and installs to those it recognizes.
- If the current agent is not supported by Context7, do **not** use ctx7 install; fall back to source‑verified manual install or the agent’s documented path.

## Codex CLI
Project-level path:
```
<repo>/.codex/skills/<skill-name>/
```

Install via Codex’s built-in skill installer (preferred for repo-based skills):
```
$skill-installer install https://github.com/owner/repo/tree/main/path/to/skill
```

Or describe it:
```
$skill-installer install the <skill-name> skill from owner/repo
```

Manual install:
```
mkdir -p .codex/skills
cp -R skill-name .codex/skills/
```

**Note:** Restart Codex after installing new skills.

## Claude Code (CLI)
Project-level (recommended):
```
<repo>/.claude/skills/<skill-name>/
```

Global:
```
~/.claude/skills/<skill-name>/
```

GitHub install:
```bash
# Project-level
mkdir -p .claude/skills && git clone https://github.com/owner/repo-name.git .claude/skills/skill-name

# Global
mkdir -p ~/.claude/skills && git clone https://github.com/owner/repo-name.git ~/.claude/skills/skill-name
```

## Claude (Web/Desktop)
Package the skill folder as a ZIP and upload via **Settings > Capabilities**.

## Other Clients
Ask for the official project-level skills path or CLI. If no official guidance exists, present a best-effort option and mark it unverified.

## Fallback (only if verified)
If install methods are unclear, **do not** hand-write or reconstruct a skill. Ask for an authoritative source (official repo, ZIP, or Skills CLI listing) and only install from that source.

If you must manually copy a verified skill, consult `references/agent-skills.md` for agent-specific paths, skill format, and discovery locations.
