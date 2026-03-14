# Claude Health

Configuration health audit skill for Claude Code.

## Structure

- `skills/health/SKILL.md` -- the only source file, contains all audit logic
- Four parallel agents: A (context layer), B (control + verification), C (behavior patterns), D (skill security & quality)

## Verification

```bash
# Syntax check: bash scripts in SKILL.md should parse
grep -Pzo '```bash\n([\s\S]*?)```' skills/health/SKILL.md | bash -n

# Word count: SKILL.md should stay under 3000 words
wc -w skills/health/SKILL.md

# Version consistency: frontmatter version, VER variable and marketplace.json must match
grep 'version:' skills/health/SKILL.md | head -1
grep 'VER=' skills/health/SKILL.md
grep '"version"' .claude-plugin/marketplace.json
```

## Commit Convention

`{type}: {description}` -- types: feat, fix, refactor, docs, chore

## Release Convention (tw93/miaoyan style)

- Title: `V{version} {Codename} {emoji}` (e.g., V1.3.0 Guardian)
- Tag: `v{version}` (lowercase v)
- Body: HTML format, bilingual (English Changelog + 中文更新日志), one-to-one
- Each item: `<li><strong>Category</strong>: description.</li>`
- Footer: update command `npx skills add tw93/claude-health@latest` + star + repo link
