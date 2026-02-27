# Skill Hunter

[![GitHub](https://img.shields.io/badge/GitHub-CE0Alex%2Fskill--hunter-blue)](https://github.com/CE0Alex/skill-hunter)

An agent skill that analyzes your project and recommends a curated stack of **external skills** from trusted registries.

## What It Does

Skill Hunter helps you discover and install the best skills for your project:

1. **Analyzes your project** — scans your codebase to understand the stack, workflows, and constraints
2. **Asks clarifying questions** — confirms your goals, trust preferences, and category focus before searching
3. **Searches skill registries** — queries Context7, skills.sh, and GitHub for relevant skills
4. **Inspects candidates** — verifies each skill's source, maintainer, and compatibility
5. **Recommends a stack** — presents a minimal set of skills with confidence ratings and tradeoffs
6. **Installs after confirmation** — only installs skills you approve, using verified methods

For the complete workflow and rules, see [SKILL.md](SKILL.md).

## When to Use

Invoke Skill Hunter when you want to find **new external skills**:
- "Find the best skills for this project"
- "Recommend external skills for TypeScript testing"
- "What skills exist for CI/CD automation?"

**Do not use** for questions about already-installed skills — Skill Hunter is for discovery, not usage guidance.

## Compatibility

This skill follows the [Agent Skills](https://agentskills.io) format and works with any agent that supports skills.

### Tested Agents
| Agent | Version Tested | Status |
|-------|----------------|--------|
| Claude Code (CLI) | 2.1.34 | ✅ Supported |
| Codex CLI | 0.98.0 | ✅ Supported |
| Claude (Web/Desktop) | — | ✅ Supported (ZIP upload) |

### Other Agents
Skill Hunter supports 50+ agents via the [Skills CLI](https://github.com/vercel-labs/skills) registry. See [references/agent-skills.md](references/agent-skills.md) for the full list of supported agents and their skill paths.

## Installing Skill Hunter

These instructions are for installing **Skill Hunter itself** as a skill in your agent. Once installed, you can invoke Skill Hunter to discover and install other skills for your project.

### Quick Install (Skills CLI)

If your agent supports the [Skills CLI](https://skills.sh):

```bash
npx skills add CE0Alex/skill-hunter --skill skill-hunter -a <your-agent> -y
```

Replace `<your-agent>` with your agent name (e.g., `claude-code`, `codex`, `cursor`). This command installs **this repo** (`CE0Alex/skill-hunter`) as a skill. See [references/agent-skills.md](references/agent-skills.md) for the full list of supported agent names and paths.

**Recommended for most users.** This installs the complete `skill-hunter` package (including `references/`).

### Claude Code (CLI)

**From GitHub (recommended):**
```bash
# Project-level
mkdir -p .claude/skills && git clone https://github.com/CE0Alex/skill-hunter.git .claude/skills/skill-hunter

# Or global (available in all projects)
mkdir -p ~/.claude/skills && git clone https://github.com/CE0Alex/skill-hunter.git ~/.claude/skills/skill-hunter
```

**Manual copy (if you already have the files):**
```bash
mkdir -p .claude/skills
cp -R skill-hunter .claude/skills/
```

### Codex CLI

**From GitHub:**
```bash
mkdir -p .codex/skills && git clone https://github.com/CE0Alex/skill-hunter.git .codex/skills/skill-hunter
```

**Using the built-in skill installer:**
```
$skill-installer install the skill-hunter skill from CE0Alex/skill-hunter
```

> **Note:** Restart Codex after installing new skills.

### Claude (Web/Desktop)

1. Download or clone this repository
2. Create a ZIP file containing the `skill-hunter` folder (include all files: `SKILL.md`, `README.md`, `references/`, etc.)
3. In Claude, go to **Settings > Capabilities**
4. Upload the ZIP file

> Skills and Code Execution must be enabled (org admins may need to enable this).

### Other Agents

For Cursor, Windsurf, Cline, and 50+ other agents, see [references/agent-skills.md](references/agent-skills.md) for paths. The general pattern is:

```bash
mkdir -p .<agent>/skills && git clone https://github.com/CE0Alex/skill-hunter.git .<agent>/skills/skill-hunter
```

Paths vary by agent (some use `.agents/skills` or `.augment/rules`), so use the reference file for accuracy.

### Verifying Installation

After installing, ask your agent:
> "What skills do you have available?"

or

> "Do you have the Skill Hunter skill?"

If installed correctly, the agent should recognize Skill Hunter and describe what it does.

---

## How Skill Hunter Installs Discovered Skills

Once Skill Hunter is installed and you invoke it, it uses these tools to find and install skills for your project:

| Tool | Purpose |
|------|---------|
| [Skills CLI](https://skills.sh) (`npx skills`) | Primary discovery and installation |
| [Context7 CLI](https://context7.com) (`ctx7`) | Secondary registry search |
| GitHub search | Fallback for gaps not in registries |

Skill Hunter handles the installation commands automatically after you confirm the recommended stack. For the full CLI reference used internally, see [references/installation.md](references/installation.md).

Note: detailed Skills CLI safety rules (like verifying a repo with `--list` before install) live in `references/installation.md` to keep this README focused on user setup.

## Example Usage

Once installed, invoke Skill Hunter with a prompt like:

> "Find the best skills for this project"

Skill Hunter will:
1. Analyze your codebase
2. Ask about your goals and preferences
3. Search skill registries (Context7, skills.sh, GitHub)
4. Present a recommended stack with confidence ratings
5. Install your chosen skills after confirmation

For the complete workflow, see [SKILL.md](SKILL.md).

## Repo Structure

| File | Purpose |
|------|---------|
| `SKILL.md` | The skill itself — workflow rules and instructions for the agent |
| `README.md` | This file — user documentation |
| `AGENTS.md` | Contributor guide for maintaining Skill Hunter |
| `references/installation.md` | Agent reference: CLI commands for installing discovered skills |
| `references/agent-skills.md` | Agent reference: paths, formats, and supported agents |

## Changelog

- **v1.0.24** — Update tested versions (Claude Code 2.1.34, Codex 0.98.0), add `ctx7 skills suggest` as discovery source, update Skills CLI reference to v1.3.7 features, fix Replit path, add Skills Directory as optional registry, rebuild dist package.
- **v1.0.21** — Adopt clarified README structure, add explicit repo reference in Quick Install, and link detailed CLI safety rules from references.
- **v1.0.20** — Align with latest Skills CLI guidance (source formats, options, maintenance commands) and expand supported agents/discovery locations.

## Spec Evolution

The [Agent Skills specification](https://agentskills.io) continues to evolve. Notable proposals under discussion include inter-skill relationships (`prerequisite-skills`, `related-skills`) in [agentskills/agentskills#90](https://github.com/agentskills/agentskills/issues/90). Skill Hunter will adopt new spec features as they are merged.

## License

MIT
