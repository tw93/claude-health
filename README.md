<div align="center">
  <img src="https://gw.alipayobjects.com/zos/k/2h/waza.svg" width="120" />
  <h1>Waza</h1>
  <p><b>Engineering habits you already know, turned into skills AI agents can run.</b></p>
  <p><a href="llms.txt">LLM guide</a></p>
  <a href="https://github.com/tw93/Waza/actions/workflows/test.yml"><img src="https://img.shields.io/github/actions/workflow/status/tw93/Waza/test.yml?branch=main&style=flat-square&label=tests" alt="Tests"></a>
  <a href="https://github.com/tw93/Waza/stargazers"><img src="https://img.shields.io/github/stars/tw93/Waza?style=flat-square" alt="Stars"></a>
  <a href="https://github.com/tw93/Waza/releases"><img src="https://img.shields.io/github/v/tag/tw93/Waza?label=version&style=flat-square" alt="Version"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue.svg?style=flat-square" alt="License"></a>
  <a href="https://twitter.com/HiTw93"><img src="https://img.shields.io/badge/follow-Tw93-red?style=flat-square&logo=Twitter" alt="Twitter"></a>
</div>

<br/>

<div align="center">
  <img src="assets/waza_skills.svg" width="1000" />
</div>

## Skills

Each engineering habit gets an installed skill. In Claude Code, type the slash command. In Codex, invoke the installed skill by name and follow the same playbook.

| Skill | When | What it does |
| :--- | :--- | :--- |
| [`/think`](skills/think/SKILL.md) | Before building anything new | Challenges the problem, pressure-tests the design, and produces a decision-complete plan another agent can implement. |
| [`/ui`](skills/ui/SKILL.md) | Building frontend interfaces | Produces distinctive UI, including screenshot-driven aesthetic iteration, with a committed direction rather than generic defaults. |
| [`/check`](skills/check/SKILL.md) | After a task, before merging or release | Reviews the diff against project constraints, verifies the result, and handles approved release and maintainer actions. |
| [`/hunt`](skills/hunt/SKILL.md) | Any bug, regression, or unexpected behavior | Systematic debugging. Root cause confirmed before any fix is applied, especially when something used to work. |
| [`/write`](skills/write/SKILL.md) | Writing or editing prose | Rewrites prose to sound natural in Chinese and English. Cuts stiff, formulaic phrasing. |
| [`/learn`](skills/learn/SKILL.md) | Diving into an unfamiliar domain | Six-phase research workflow: collect, digest, outline, fill in, refine, then self-review and publish. |
| [`/read`](skills/read/SKILL.md) | Any URL or PDF | Returns a concise summary, or clean Markdown for conversion, quotes, citations, saving, or further research. |
| [`/health`](skills/health/SKILL.md) | Auditing Agent Health | Checks Codex, Claude Code, project instructions, verifier output, and AI maintainability with a budget-aware summary pass before deep inspection. |

Each skill is a folder with reference docs, helper scripts, and gotchas from real failures.

## Install

**Claude Code, Codex, Cursor, and other agents**

```bash
npx skills add tw93/Waza -a claude-code codex cursor -g -y
```

One copy lands in `~/.agents/skills`, the shared skills directory. Claude Code is symlinked in; Codex, Cursor, Gemini CLI, Copilot, Amp, Kimi Code CLI, and every other agent that reads that directory picks the eight skills up as `/check`, `/think`, and so on. Agents with a private skills directory take their id after `-a` (for example `antigravity-cli` or `qwen-code`). Update with `npx skills update -g -y`.

**Host plugin**, if you prefer the host's own update command (skills are namespaced, `/waza:check`)

```bash
# Claude Code (update: claude plugin update waza)
/plugin marketplace add tw93/Waza
/plugin install waza@waza

# Codex (update: codex plugin marketplace upgrade waza, then codex plugin add waza@waza)
codex plugin marketplace add tw93/Waza
codex plugin add waza@waza
```

**Claude Desktop**: download [waza.zip](https://github.com/tw93/Waza/releases/latest/download/waza.zip), open Customize > Skills > "+" > Create skill, and upload the ZIP. To update, click "..." on the skill card, choose Replace, and upload the latest ZIP.

**Pi**: `pi install npm:@tw93/waza`, update with `pi update npm:@tw93/waza`.

## Chaining Skills

You decide how skills chain together. Each skill stops at the requested outcome; an explicitly authorized workflow continues without asking you to approve every transition.

**Common workflows:**

- **Plan a feature**: `/think` → approve → say "implement X" → `/check` → merge
- **Ship a fix**: `/hunt` → fix → `/check` → release/publish/push/issue follow-through
- **Research and write**: `/read` (fetch sources) → `/learn` (synthesize) → `/write` (polish)
- **Debug and verify**: `/hunt` (find root cause) → fix → `/check` (review changes)

## Project Context

Waza ships only generic engineering habits. `/check` becomes project-aware at runtime by reading the target repository's public context (READMEs, package manifests, Makefiles, CI workflows) and your task constraints, never private paths, credentials, or tokens. See [`skills/check/references/project-context.md`](skills/check/references/project-context.md) for the review context template.

## Extras

### Statusline

A minimal statusline for Claude Code: context window, 5-hour quota, and 7-day quota. Color-coded by usage, no progress bars, no noise.

<div align="center">
  <img src="https://gw.alipayobjects.com/zos/k/y9/RUgevg.png" width="1000" />
</div>

```bash
(
  set -e
  WAZA_STATUSLINE_SCRIPT="$(mktemp -t waza-statusline.XXXXXX)"
  trap 'rm -f "$WAZA_STATUSLINE_SCRIPT"' EXIT
  curl -fL https://github.com/tw93/Waza/releases/latest/download/setup-statusline.sh -o "$WAZA_STATUSLINE_SCRIPT"
  # review it first: less "$WAZA_STATUSLINE_SCRIPT"
  bash "$WAZA_STATUSLINE_SCRIPT"
)
```

**Codex** has native statusline items. Add to `~/.codex/config.toml`:

```toml
[tui]
status_line = ["model-with-reasoning", "current-dir", "context-used", "five-hour-limit", "weekly-limit"]
status_line_use_colors = true
```

Codex shows remaining quota; the Claude Code statusline above shows used percentage (upstream does not yet expose `five-hour-used` / `weekly-used`).

### Optional Rules

Three independent toggles. Copy the ones you want (swap `claude-code` for `codex` or `antigravity-cli` on those agents):

```bash
(
  set -e
  WAZA_RULE_SCRIPT="$(mktemp -t waza-rule.XXXXXX)"
  trap 'rm -f "$WAZA_RULE_SCRIPT"' EXIT
  curl -fL https://github.com/tw93/Waza/releases/latest/download/setup-rule.sh -o "$WAZA_RULE_SCRIPT"
  # review it first: less "$WAZA_RULE_SCRIPT"

  # English coaching: appends a short 😇 correction when your prompt has an English mistake
  bash "$WAZA_RULE_SCRIPT" english claude-code

  # Anti-patterns: always-on cross-skill guardrails (read before acting, no scope creep, no unsolicited summaries)
  bash "$WAZA_RULE_SCRIPT" anti-patterns claude-code

  # Routing hint: tells non-Claude hosts to prefer Waza skills when a request matches their triggers
  bash "$WAZA_RULE_SCRIPT" waza-routing claude-code
)
```

<div align="center">
  <img src="https://gw.alipayobjects.com/zos/k/24/vfkGOi.png" width="1000" />
</div>

Curl URLs use the latest GitHub release asset. Set `WAZA_REF=main` before the command if you want bleeding-edge scripts.

## Why

Waza (技, わざ) is a Japanese martial arts term for technique: a move practiced until it becomes instinct.

A good engineer does more than write code. They pressure-test requirements, debug to root cause, review their own diffs, and read primary sources. AI has the raw output for all of it, but without structure that output drifts into generic, imprecise work. Each Waza skill states the outcome, the red lines, and how the result gets verified, then steps back and lets the model choose the path. As models improve, that restraint pays compound interest.

Tools like Superpowers and gstack are powerful but heavy: too many skills, too much configuration. Waza stays small, eight skills for the habits that actually matter, each with one job and a clear trigger. Built from real projects and refined through 300+ sessions across 7 projects, every gotcha traces to a real failure. The `/health` skill grew from the six-layer Claude Code framework in [this post](https://tw93.fun/en/2026-03-12/claude.html).

Part of a trilogy: [Kaku](https://github.com/tw93/Kaku) (書く) writes code, [Waza](https://github.com/tw93/Waza) (技) drills habits, [Kami](https://github.com/tw93/Kami) (紙) ships documents. Think of them as a family: Kaku is the dad, Waza the big sister, Kami the little sister.

## Uninstall

```bash
npx skills remove tw93/Waza -g
rm -f ~/.claude/statusline.sh
rm -f ~/.claude/rules/english.md
rm -f ~/.claude/rules/anti-patterns.md
rm -f ~/.claude/rules/waza-routing.md
```

For Claude Desktop, delete Waza from Customize > Skills. For Codex rule installs, remove the marked Waza blocks from `~/.codex/AGENTS.md`.

## Support

- The most direct way to support me is getting [Mole for Mac](https://mole.fit), my paid Mac cleanup app.
- If Waza helped you, give it a star, [share it](https://twitter.com/intent/tweet?url=https://github.com/tw93/Waza&text=Waza%20-%20AI%20coding%20skills%20for%20the%20complete%20engineer.), or open an issue or PR.
- I have two cats, TangYuan and Coke. If you think Waza delights your life, you can feed them <a href="https://cats.tw93.fun?name=Waza" target="_blank">canned food 🥩</a>.

<details>
<summary>These lovely people already did 🐱</summary>
<br/>
<div align="center">
  <a href="https://cats.tw93.fun?name=Waza"><img src="https://cdn.jsdelivr.net/gh/tw93/sponsors@main/assets/sponsors.svg" width="1000" loading="lazy" /></a>
</div>
</details>

## License

MIT License. Feel free to use Waza and contribute.
