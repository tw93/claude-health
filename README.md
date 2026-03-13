<div align="center">
  <img src="https://cdn.tw93.fun//uPic/Wbrr2J.png" width="120" />
  <h1>Claude Health</h1>
  <p><em>Audit your Claude Code configuration health across all layers.</em></p>
  <a href="https://github.com/tw93/claude-health/stargazers"><img src="https://img.shields.io/github/stars/tw93/claude-health?style=flat-square" alt="Stars"></a>
  <a href="https://github.com/tw93/claude-health/releases"><img src="https://img.shields.io/github/v/tag/tw93/claude-health?label=version&style=flat-square" alt="Version"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue.svg?style=flat-square" alt="License"></a>
  <a href="https://twitter.com/AiTw93"><img src="https://img.shields.io/badge/follow-Tw93-red?style=flat-square&logo=Twitter" alt="Twitter"></a>
</div>

<br/>

A Claude Code [skill](https://docs.anthropic.com/en/docs/claude-code/skills) that systematically reviews your project's setup using the six-layer framework: `CLAUDE.md → rules → skills → hooks → subagents → verifiers`. It detects project complexity, runs three parallel diagnostic agents, and outputs a prioritized report telling you what to fix first.

## Install

### Using `npx skills` (third-party CLI)

```bash
npx skills add tw93/claude-health
```

> **Note:** `npx skills` installs to `.agents/skills/`, but Claude Code reads skills from `.claude/skills/`. You may need to move the files manually after installation:
> ```bash
> mkdir -p .claude/skills && cp -r .agents/skills/health .claude/skills/health
> ```

### Manual install (recommended)

```bash
# Clone into the correct Claude Code skills directory
mkdir -p .claude/skills/health
curl -fsSL https://raw.githubusercontent.com/tw93/claude-health/main/skills/health/SKILL.md \
  -o .claude/skills/health/SKILL.md
```

## Usage

In any Claude Code session, run `/health` or just say:

> "Run a health check on my Claude Code config"

The skill automatically detects your project tier (Simple / Standard / Complex) and calibrates checks accordingly — it won't flag missing layers that aren't needed for your project size.

## What Gets Checked

| Layer | Checks |
| :--- | :--- |
| **CLAUDE.md** | Signal-to-noise ratio, missing Verification/Compact Instructions, prose bloat |
| **rules/** | Language-specific rules placement, coverage gaps |
| **skills/** | Description token count, trigger clarity, auto-invoke strategy, frequency-based optimization |
| **hooks** | Pattern field presence, file-type coverage, stale entries |
| **MCP** | Server count, token cost estimation, context pressure detection |
| **allowedTools** | Dangerous or stale one-time commands |
| **Prompt Cache** | Dynamic timestamps, tool reordering, mid-session model switching |
| **Three-Layer Defense** | Critical rules covered by CLAUDE.md + Skill + Hook together |
| **Behavior** | Rules violated in practice, repeated corrections, context hygiene habits |

## Output

Results are grouped into three priority levels:

- **Critical** — Fix now: rule violations, dangerous permissions, cache-breaking patterns, MCP overhead >12.5%
- **Structural** — Fix soon: misplaced content, missing hooks, single-layer critical rules
- **Incremental** — Nice to have: context hygiene, HANDOFF.md adoption, skill frequency tuning

## Background

Built on the six-layer framework described in [this blog post](https://tw93.fun/2026-03-12/claude.html). If you've read the post and want to know how your config measures up, `/health` is the fastest way to find out.

## License

MIT License, feel free to enjoy and participate in open source.
