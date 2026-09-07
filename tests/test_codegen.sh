#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test_helpers.sh"

tmpdir=$(make_tmpdir)

# Clean working copy: --check must succeed.
copy_repo "$tmpdir/repo"
(cd "$tmpdir/repo" && python3 scripts/build_metadata.py --check >"$tmpdir/clean.out" 2>"$tmpdir/clean.err")
grep -q 'matches generator' "$tmpdir/clean.out"
(cd "$tmpdir/repo" && python3 -S scripts/build_metadata.py --check >"$tmpdir/no-site.out" 2>"$tmpdir/no-site.err")
grep -q 'installer defaults pinned' "$tmpdir/no-site.out"

# Tampered marketplace.json: --check must detect drift.
copy_repo "$tmpdir/drift"
python3 -c "
import json
p = '$tmpdir/drift/.claude-plugin/marketplace.json'
d = json.load(open(p))
d['plugins'][0]['description'] = 'tampered'
open(p, 'w').write(json.dumps(d, indent=2) + '\n')
"
if (cd "$tmpdir/drift" && python3 scripts/build_metadata.py --check >"$tmpdir/drift.out" 2>"$tmpdir/drift.err"); then
  echo "build_metadata --check should detect tampered marketplace.json"; exit 1
fi
grep -q 'DRIFT:' "$tmpdir/drift.err"

# Tampered Codex plugin metadata must also detect drift.
copy_repo "$tmpdir/codex-drift"
python3 -c "
import json
p = '$tmpdir/codex-drift/plugins/waza/.codex-plugin/plugin.json'
d = json.load(open(p))
d['interface']['displayName'] = 'Tampered'
open(p, 'w').write(json.dumps(d, indent=2) + '\n')
p = '$tmpdir/codex-drift/.agents/plugins/marketplace.json'
d = json.load(open(p))
d['plugins'][0]['category'] = 'Tampered'
open(p, 'w').write(json.dumps(d, indent=2) + '\n')
"
if (cd "$tmpdir/codex-drift" && python3 scripts/build_metadata.py --check >"$tmpdir/codex-drift.out" 2>"$tmpdir/codex-drift.err"); then
  echo "build_metadata --check should detect tampered Codex plugin metadata"; exit 1
fi
grep -q 'plugins/waza/.codex-plugin/plugin.json is out of sync' "$tmpdir/codex-drift.err"
grep -q '.agents/plugins/marketplace.json is out of sync' "$tmpdir/codex-drift.err"

# Extra files in the generated Codex plugin tree must not linger.
copy_repo "$tmpdir/codex-extra"
mkdir -p "$tmpdir/codex-extra/plugins/waza/tmp"
printf '%s\n' 'stale' > "$tmpdir/codex-extra/plugins/waza/tmp/stale.txt"
if (cd "$tmpdir/codex-extra" && python3 scripts/build_metadata.py --check >"$tmpdir/codex-extra.out" 2>"$tmpdir/codex-extra.err"); then
  echo "build_metadata --check should detect extra generated Codex plugin files"; exit 1
fi
grep -q 'extra file in the generated Codex plugin tree' "$tmpdir/codex-extra.err"

# Default --write mode regenerates from frontmatter + VERSION.
copy_repo "$tmpdir/regen"
printf '%s\n' '{"plugins": []}' > "$tmpdir/regen/.claude-plugin/marketplace.json"
rm -rf "$tmpdir/regen/.codex-plugin" "$tmpdir/regen/.agents" "$tmpdir/regen/plugins"
(cd "$tmpdir/regen" && python3 scripts/build_metadata.py >"$tmpdir/regen.out")
test "$(jq '.plugins | length' "$tmpdir/regen/.claude-plugin/marketplace.json")" -eq 9
test "$(jq -r '.name' "$tmpdir/regen/plugins/waza/.codex-plugin/plugin.json")" = "waza"
test "$(jq -r '.skills' "$tmpdir/regen/plugins/waza/.codex-plugin/plugin.json")" = "./skills/"
test -f "$tmpdir/regen/plugins/waza/skills/check/SKILL.md"
test -f "$tmpdir/regen/plugins/waza/rules/waza-routing.md"
test "$(jq -r '.plugins[0].source.path' "$tmpdir/regen/.agents/plugins/marketplace.json")" = "./plugins/waza"
test "$(jq -r '.plugins[0].policy.installation' "$tmpdir/regen/.agents/plugins/marketplace.json")" = "AVAILABLE"
test "$(jq -r '.name' "$tmpdir/regen/package.json")" = "@tw93/waza"
test "$(jq -r '.homepage' "$tmpdir/regen/package.json")" = "https://github.com/tw93/Waza"
test "$(jq -r '.files | index("llms.txt") != null' "$tmpdir/regen/package.json")" = "true"
test "$(jq -r '.pi.skills[0]' "$tmpdir/regen/package.json")" = "./skills"
test "$(jq -r '.publishConfig.access' "$tmpdir/regen/package.json")" = "public"

# README installer URLs should use latest release assets. The installer scripts
# themselves still pin WAZA_REF to VERSION.
copy_repo "$tmpdir/readme"
version=$(cat "$tmpdir/readme/VERSION")
sed -i.bak \
  "s|https://github.com/tw93/Waza/releases/latest/download/setup-rule.sh|https://raw.githubusercontent.com/tw93/Waza/v${version}/scripts/setup-rule.sh|g; s|https://github.com/tw93/Waza/releases/latest/download/setup-statusline.sh|https://raw.githubusercontent.com/tw93/Waza/v${version}/scripts/setup-statusline.sh|g" \
  "$tmpdir/readme/README.md"
rm "$tmpdir/readme/README.md.bak"
if (cd "$tmpdir/readme" && python3 scripts/build_metadata.py --check >"$tmpdir/readme.out" 2>"$tmpdir/readme.err"); then
  echo "build_metadata --check should detect raw README installer URLs"; exit 1
fi
grep -q "README.md installer URLs must use latest release assets" "$tmpdir/readme.err"
(cd "$tmpdir/readme" && python3 scripts/build_metadata.py >"$tmpdir/readme-regen.out")
grep -q "tw93/Waza/releases/latest/download/setup-rule.sh" "$tmpdir/readme/README.md"
grep -q "tw93/Waza/releases/latest/download/setup-statusline.sh" "$tmpdir/readme/README.md"
if grep -q "raw.githubusercontent.com/tw93/Waza/.*/scripts/setup-" "$tmpdir/readme/README.md"; then
  echo "README still has raw installer URLs after regen"; exit 1
fi

# package.json is generated too; package version and Pi metadata must stay
# lock-step with VERSION.
copy_repo "$tmpdir/package"
version=$(cat "$tmpdir/package/VERSION")
python3 -c "
import json
p = '$tmpdir/package/package.json'
d = json.load(open(p))
d['version'] = '0.0.0'
d['pi'] = {'skills': ['./wrong']}
d['publishConfig'] = {'access': 'private'}
open(p,'w').write(json.dumps(d, indent=2) + '\n')
"
if (cd "$tmpdir/package" && python3 scripts/build_metadata.py --check >"$tmpdir/package.out" 2>"$tmpdir/package.err"); then
  echo "build_metadata --check should detect stale package.json metadata"; exit 1
fi
grep -q 'package.json is out of sync' "$tmpdir/package.err"
(cd "$tmpdir/package" && python3 scripts/build_metadata.py >"$tmpdir/package-regen.out")
test "$(jq -r '.version' "$tmpdir/package/package.json")" = "$version"
test "$(jq -r '.pi.skills[0]' "$tmpdir/package/package.json")" = "./skills"
test "$(jq -r '.publishConfig.access' "$tmpdir/package/package.json")" = "public"

# Installer scripts must also default to the current release tag; overriding
# WAZA_REF=main remains available for bleeding-edge installs.
copy_repo "$tmpdir/scripts"
version=$(cat "$tmpdir/scripts/VERSION")
sed -i.bak 's|WAZA_REF="${WAZA_REF:-v'"$version"'}"|WAZA_REF="${WAZA_REF:-main}"|g' \
  "$tmpdir/scripts/scripts/setup-rule.sh" \
  "$tmpdir/scripts/scripts/setup-statusline.sh"
rm "$tmpdir/scripts/scripts/setup-rule.sh.bak" "$tmpdir/scripts/scripts/setup-statusline.sh.bak"
if (cd "$tmpdir/scripts" && python3 scripts/build_metadata.py --check >"$tmpdir/scripts.out" 2>"$tmpdir/scripts.err"); then
  echo "build_metadata --check should detect unpinned installer WAZA_REF"; exit 1
fi
grep -q 'default WAZA_REF is not pinned' "$tmpdir/scripts.err"
(cd "$tmpdir/scripts" && python3 scripts/build_metadata.py >"$tmpdir/scripts-regen.out")
grep -q 'WAZA_REF="${WAZA_REF:-v'"$version"'}"' "$tmpdir/scripts/scripts/setup-rule.sh"
grep -q 'WAZA_REF="${WAZA_REF:-v'"$version"'}"' "$tmpdir/scripts/scripts/setup-statusline.sh"

# Dispatcher routing table is also generated; tampering the committed copy
# (or deleting it) must trip drift detection.
copy_repo "$tmpdir/dispatcher"
sed -i.bak 's| think | tampered |g' "$tmpdir/dispatcher/scripts/dispatcher.md"
rm "$tmpdir/dispatcher/scripts/dispatcher.md.bak"
if (cd "$tmpdir/dispatcher" && python3 scripts/build_metadata.py --check >"$tmpdir/dispatcher.out" 2>"$tmpdir/dispatcher.err"); then
  echo "build_metadata --check should detect tampered dispatcher.md"; exit 1
fi
grep -q 'routing table is out of sync' "$tmpdir/dispatcher.err"
(cd "$tmpdir/dispatcher" && python3 scripts/build_metadata.py >"$tmpdir/dispatcher-regen.out")
grep -q '| think | `skills/think/SKILL.md` |' "$tmpdir/dispatcher/scripts/dispatcher.md"

echo "codegen smoke: ok"
