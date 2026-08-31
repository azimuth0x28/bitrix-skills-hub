# Agent Prompts

Self-contained agent prompts for Bitrix/D7 development. Each file is a complete, standalone system prompt with frontmatter, merged from verified sources.

## Catalog

| Agent | Role | Purpose |
| --- | --- | --- |
| [`bitrix-coder`](bitrix-coder.md) | Bitrix Framework Expert | Secure, performant D7 development with verified patterns, DI boundaries, and 42-skill index |

## How to use

1. Copy the agent prompt into your project's `AGENTS.md` or equivalent rule file.
2. Install skills from the hub: `npx skills add azimuth0x28/bitrix-skills-hub --all`.
3. The agent prompt references skills by name; the agent loads only the ones it needs for the current task.

## Source merge

Each agent prompt is aggregated from multiple sources with clear conflict resolution:

- **Canon** (`bitrix-coder.md`): persona, version policy, priorities, DI boundaries, hard canons, skill index.
- **Challenge** (`bxmaximum/bitrix_ai_challenge`): `/local/` tree, PHP code style, `make:*` generators, Messenger details, expanded checklist and anti-patterns.

On any conflict the canon wins (newer, verified against main 26.650.100).
