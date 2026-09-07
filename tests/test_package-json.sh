#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test_helpers.sh"

tmpdir=$(make_tmpdir)
copy_repo "$tmpdir/repo"

version=$(cat "$tmpdir/repo/VERSION")
test "$(jq -r '.name' "$tmpdir/repo/package.json")" = "@tw93/waza"
test "$(jq -r '.homepage' "$tmpdir/repo/package.json")" = "https://github.com/tw93/Waza"
test "$(jq -r '.files | index("llms.txt") != null' "$tmpdir/repo/package.json")" = "true"
test "$(jq -r '.version' "$tmpdir/repo/package.json")" = "$version"
test "$(jq -r '.pi.skills[0]' "$tmpdir/repo/package.json")" = "./skills"
# Pi scans root-level *.md as skills; the routing index must be excluded.
test "$(jq -r '.pi.skills | index("!skills/RESOLVER.md")' "$tmpdir/repo/package.json")" != "null"
test "$(jq -r '.keywords[]' "$tmpdir/repo/package.json" | grep -c '^pi-package$')" -eq 1
test "$(jq -r '.keywords[]' "$tmpdir/repo/package.json" | grep -c '^antigravity$')" -eq 1
test "$(jq -r '.keywords[]' "$tmpdir/repo/package.json" | grep -c '^opencode$')" -eq 1
test "$(jq -r '.publishConfig.access' "$tmpdir/repo/package.json")" = "public"

if ! command -v npm >/dev/null 2>&1; then
  echo "package-json smoke: skipped npm pack --dry-run (npm not installed)"
  exit 0
fi

(cd "$tmpdir/repo" && npm pack --dry-run --json > "$tmpdir/npm-pack.json")

python3 - "$tmpdir/npm-pack.json" <<'PY'
import json
import sys

data = json.load(open(sys.argv[1]))
files = {item["path"] for item in data[0]["files"]}

required = {
    "package.json",
    "README.md",
    "LICENSE",
    "rules/anti-patterns.md",
    "scripts/statusline.sh",
    "skills/check/SKILL.md",
}
missing = sorted(required - files)
if missing:
    raise SystemExit(f"missing expected npm package files: {missing}")

unexpected = sorted(path for path in files if path.endswith("check-update.sh"))
if unexpected:
    raise SystemExit(f"automatic update checker leaked into npm package: {unexpected}")

forbidden = {
    ".claude-plugin/marketplace.json",
    ".agents/plugins/marketplace.json",
    "plugins/waza/.codex-plugin/plugin.json",
    ".github/workflows/test.yml",
    "dist/waza.zip",
    "tests/test_package.sh",
    "packaging.allowlist",
    "scripts/build_metadata.py",
    "scripts/check_routing_drift.py",
    "scripts/dispatcher-template.md",
    "scripts/dispatcher.md",
    "scripts/package-skill.sh",
    "scripts/packaging_filter.py",
    "scripts/skill_checks.py",
    "scripts/skill_frontmatter.py",
    "scripts/validate_package.py",
    "scripts/verify_skills.py",
}
leaked = sorted(forbidden & files)
if leaked:
    raise SystemExit(f"forbidden npm package files leaked: {leaked}")

pycache = sorted(path for path in files if "__pycache__" in path or path.endswith(".pyc"))
if pycache:
    raise SystemExit(f"python cache files leaked into npm package: {pycache[:5]}")
PY

echo "package-json smoke: ok"
