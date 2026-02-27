# Agent Skills Reference (Install Paths + Format)

Use this reference only **after** a skill source has been verified (official repo, Skills CLI listing, or vendor-provided ZIP). Do **not** reconstruct skills by hand—only copy the exact skill folder and all required files from the source.

## Supported Agents (Skills CLI registry)

Skills can be installed to these agents. Paths shown are project‑level and global locations.

| Agent | `--agent` | Project Path | Global Path |
|-------|-----------|--------------|-------------|
| Amp, Kimi Code CLI | `amp`, `kimi-cli` | `.agents/skills/` | `~/.config/agents/skills/` |
| Antigravity | `antigravity` | `.agent/skills/` | `~/.gemini/antigravity/global_skills/` |
| Augment | `augment` | `.augment/rules/` | `~/.augment/rules/` |
| Claude Code | `claude-code` | `.claude/skills/` | `~/.claude/skills/` |
| OpenClaw | `openclaw` | `skills/` | `~/.moltbot/skills/` |
| Cline | `cline` | `.cline/skills/` | `~/.cline/skills/` |
| CodeBuddy | `codebuddy` | `.codebuddy/skills/` | `~/.codebuddy/skills/` |
| Codex | `codex` | `.codex/skills/` | `~/.codex/skills/` |
| Command Code | `command-code` | `.commandcode/skills/` | `~/.commandcode/skills/` |
| Continue | `continue` | `.continue/skills/` | `~/.continue/skills/` |
| Crush | `crush` | `.crush/skills/` | `~/.config/crush/skills/` |
| Cursor | `cursor` | `.cursor/skills/` | `~/.cursor/skills/` |
| Droid | `droid` | `.factory/skills/` | `~/.factory/skills/` |
| Gemini CLI | `gemini-cli` | `.gemini/skills/` | `~/.gemini/skills/` |
| GitHub Copilot | `github-copilot` | `.github/skills/` | `~/.copilot/skills/` |
| Goose | `goose` | `.goose/skills/` | `~/.config/goose/skills/` |
| Junie | `junie` | `.junie/skills/` | `~/.junie/skills/` |
| iFlow CLI | `iflow-cli` | `.iflow/skills/` | `~/.iflow/skills/` |
| Kilo Code | `kilo` | `.kilocode/skills/` | `~/.kilocode/skills/` |
| Kiro CLI | `kiro-cli` | `.kiro/skills/` | `~/.kiro/skills/` |
| Kode | `kode` | `.kode/skills/` | `~/.kode/skills/` |
| MCPJam | `mcpjam` | `.mcpjam/skills/` | `~/.mcpjam/skills/` |
| Mistral Vibe | `mistral-vibe` | `.vibe/skills/` | `~/.vibe/skills/` |
| Mux | `mux` | `.mux/skills/` | `~/.mux/skills/` |
| OpenCode | `opencode` | `.opencode/skills/` | `~/.config/opencode/skills/` |
| OpenClaude IDE | `openclaude` | `.openclaude/skills/` | `~/.openclaude/skills/` |
| OpenHands | `openhands` | `.openhands/skills/` | `~/.openhands/skills/` |
| Pi | `pi` | `.pi/skills/` | `~/.pi/agent/skills/` |
| Qoder | `qoder` | `.qoder/skills/` | `~/.qoder/skills/` |
| Qwen Code | `qwen-code` | `.qwen/skills/` | `~/.qwen/skills/` |
| Replit | `replit` | `.agents/skills/` | N/A (project-only) |
| Roo Code | `roo` | `.roo/skills/` | `~/.roo/skills/` |
| Trae | `trae` | `.trae/skills/` | `~/.trae/skills/` |
| Trae CN | `trae-cn` | `.trae/skills/` | `~/.trae-cn/skills/` |
| Windsurf | `windsurf` | `.windsurf/skills/` | `~/.codeium/windsurf/skills/` |
| Zencoder | `zencoder` | `.zencoder/skills/` | `~/.zencoder/skills/` |
| Neovate | `neovate` | `.neovate/skills/` | `~/.neovate/skills/` |
| Pochi | `pochi` | `.pochi/skills/` | `~/.pochi/skills/` |
| AdaL | `adal` | `.adal/skills/` | `~/.adal/skills/` |

> If the current agent isn’t listed, installation support is unverified. Ask for official guidance or use the agent’s documented project‑level skills path.

Kiro CLI note:
After installing skills, add them to your custom agent’s `resources` in `.kiro/agents/<agent>.json`:
```json
{
  "resources": ["skill://.kiro/skills/**/SKILL.md"]
}
```

## Creating / Formatting Skills

Skills are directories containing a `SKILL.md` file with YAML frontmatter:

```markdown
---
name: my-skill
description: What this skill does and when to use it
---

# My Skill

Instructions for the agent to follow when this skill is activated.
```

Required frontmatter fields:
- `name` (unique identifier; lowercase + hyphens)
- `description` (when to use the skill)

Spec highlights (Agent Skills):
- `name`: max 64 chars; lowercase letters, numbers, hyphens; must not start/end with a hyphen.
- `description`: max 1024 chars; non‑empty; describe what the skill does and when to use it.
- Optional frontmatter fields commonly used: `license`, `metadata`, `compatibility`, `allowed-tools`.
- Optional directories: `scripts/`, `references/`, `assets/` (include them when copying a skill).

Optional (Skills CLI‑specific):
- `metadata.internal: true` hides the skill from default discovery; only visible when internal skills are enabled.

## Skill Discovery Locations (Skills CLI)

The Skills CLI looks for skills in these locations in a repo:

- Root (if it contains `SKILL.md`)
- `skills/`
- `skills/.curated/`
- `skills/.experimental/`
- `skills/.system/`
- `.agents/skills/`
- `.agent/skills/`
- `.augment/rules/`
- `.claude/skills/`
- `.cline/skills/`
- `.codebuddy/skills/`
- `.codex/skills/`
- `.commandcode/skills/`
- `.continue/skills/`
- `.crush/skills/`
- `.cursor/skills/`
- `.factory/skills/`
- `.gemini/skills/`
- `.github/skills/`
- `.goose/skills/`
- `.junie/skills/`
- `.iflow/skills/`
- `.kilocode/skills/`
- `.kiro/skills/`
- `.kode/skills/`
- `.mcpjam/skills/`
- `.vibe/skills/`
- `.mux/skills/`
- `.opencode/skills/`
- `.openclaude/skills/`
- `.openhands/skills/`
- `.pi/skills/`
- `.qoder/skills/`
- `.qwen/skills/`
- `.roo/skills/`
- `.trae/skills/`
- `.windsurf/skills/`
- `.zencoder/skills/`
- `.neovate/skills/`
- `.pochi/skills/`
- `.adal/skills/`

If no skills are found in standard locations, a recursive search is performed.

## Multi‑skill repos and shared files

- If the source repo contains multiple skills **or** you are installing a specific skill by name, list available skills first (Skills CLI `--list` or the repo’s `skills/` index) and install only the selected skill.
- Manual copy fallback applies **only** when the user explicitly requests a skill from that repo and the exact files can be verified.
- Copy the **entire** skill folder plus any shared files explicitly referenced in the skill’s docs. If shared dependencies are unclear, stop and request authoritative install guidance.

## Compatibility

Skills follow the Agent Skills specification, but some features can be agent‑specific. This table reflects feature support reported by the Skills CLI ecosystem at time of writing:

| Feature         | OpenCode | OpenHands | Claude Code | Cline | CodeBuddy | Codex | Command Code | Kiro CLI | Cursor | Antigravity | Roo Code | GitHub Copilot | Amp | Clawdbot | Neovate | Pi | Qoder | Zencoder |
| --------------- | -------- | --------- | ----------- | ----- | --------- | ----- | ------------ | -------- | ------ | ----------- | -------- | -------------- | --- | -------- | ------- | -- | ----- | -------- |
| Basic skills    | Yes      | Yes       | Yes         | Yes   | Yes       | Yes   | Yes          | Yes      | Yes    | Yes         | Yes      | Yes            | Yes | Yes      | Yes     | Yes | Yes   | Yes      |
| `allowed-tools` | Yes      | Yes       | Yes         | Yes   | Yes       | Yes   | Yes          | No       | Yes    | Yes         | Yes      | Yes            | Yes | Yes      | Yes     | Yes | Yes   | No       |
| `context: fork` | No       | No        | Yes         | No    | No        | No    | No           | No       | No     | No          | No       | No             | No  | No       | No      | No | No    | No       |
| Hooks           | No       | No        | Yes         | Yes   | No        | No    | No           | No       | No     | No          | No       | No             | No  | No       | No      | No | No    | No       |

> Agents not listed in this table support basic skills. If an agent's feature support is unknown, assume basic skills only.

## Troubleshooting

- **No skills found**: ensure `SKILL.md` contains valid YAML frontmatter with `name` and `description`.
- **Skill not loading**: confirm the target path is correct and restart the agent if required.
- **Permission errors**: verify write access to the target directory.

## Environment Variables (Skills CLI)

- `INSTALL_INTERNAL_SKILLS=1` to show/install skills marked `metadata.internal: true`
- `DISABLE_TELEMETRY=1` or `DO_NOT_TRACK=1` to disable telemetry (if supported by CLI)

## Telemetry

The Skills CLI may collect anonymous usage data to improve the tool. Telemetry is typically disabled in CI environments.

## Related Links

Prefer official docs for the current agent and the Agent Skills spec when available.

- Agent Skills Specification: https://agentskills.io
- Skills Directory (skills.sh): https://skills.sh
- Skills Directory (curated): https://skillsdirectory.com
- Vercel Agent Skills Repository: https://github.com/vercel-labs/agent-skills
- Amp Skills Documentation: https://ampcode.com/manual#agent-skills
- Antigravity Skills Documentation: https://antigravity.google/docs/skills
- Claude Code Skills Documentation: https://code.claude.com/docs/en/skills
- Clawdbot Skills Documentation: https://docs.clawd.bot/tools/skills
- Cline Skills Documentation: https://docs.cline.bot/features/skills
- CodeBuddy Skills Documentation: https://www.codebuddy.ai/docs/ide/Features/Skills
- Codex Skills Documentation: https://developers.openai.com/codex/skills
- Command Code Skills Documentation: https://commandcode.ai/docs/skills
- Crush Skills Documentation: https://github.com/charmbracelet/crush?tab=readme-ov-file#agent-skills
- Cursor Skills Documentation: https://cursor.com/docs/context/skills
- Factory AI / Droid Skills Documentation: https://docs.factory.ai/cli/configuration/skills
- Gemini CLI Skills Documentation: https://geminicli.com/docs/cli/skills/
- GitHub Copilot Agent Skills: https://docs.github.com/en/copilot/concepts/agents/about-agent-skills
- Goose Skills Documentation: https://block.github.io/goose/docs/guides/context-engineering/using-skills/
- iFlow CLI Skills Documentation: https://platform.iflow.cn/en/cli/examples/skill
- Junie Guidelines Documentation: https://www.jetbrains.com/help/junie/customize-guidelines.html
- Kilo Code Skills Documentation: https://kilo.ai/docs/features/skills
- Kimi Code CLI Skills Documentation: https://moonshotai.github.io/kimi-cli/en/customization/skills.html
- Kiro CLI Skills Documentation: https://kiro.dev/docs/cli/custom-agents/configuration-reference/#skill-resources
- Kode Skills Documentation: https://github.com/shareAI-lab/kode/blob/main/docs/skills.md
- Mux Skills Documentation: https://cmux.io/
- OpenCode Skills Documentation: https://opencode.ai/docs/skills
- OpenHands Skills Documentation: https://docs.openhands.ai/modules/usage/how-to/using-skills
- Pi Skills Documentation: https://github.com/badlogic/pi-mono/blob/main/packages/coding-agent/docs/skills.md
- Qoder Skills Documentation: https://docs.qoder.com/cli/Skills
- Qwen Code Skills Documentation: https://qwenlm.github.io/qwen-code-docs/en/users/features/skills/
- Replit Skills Documentation: https://docs.replit.com/replitai/skills
- Roo Code Skills Documentation: https://docs.roocode.com/features/skills
- Trae Skills Documentation: https://docs.trae.ai/ide/skills
