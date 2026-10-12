#!/usr/bin/env bash
# check-vendors.sh — vendor-neutrality gate for skill texts (allowlist, default-deny).
#
# A token in a vendor slot must be neutral placeholder vocabulary:
#   acme | vendor          (case-insensitive)
# or the vendor the skill declares in its SKILL.md frontmatter as
# `metadata.vendor: <name>`. Every other token in a vendor slot is a violation:
# nothing is denylisted, everything not allowed is forbidden.
#
# Vendor slots checked:
#   1. module path prefix   local/modules/<vendor>.   bitrix/modules/<vendor>.
#   2. AJAX action prefix   runAction('<vendor>:     action=<vendor>:
#   3. module load id       includeModule('<vendor>.<module>')
#
# Not checked (known coverage limits): namespace roots (Bitrix\, Main\, Acme\ ...)
# denote platform namespaces, not vendors; and a module-segment followed by a
# known file extension (bitrix/modules/error.log) is a file path, not a module.
#
# The declared vendor is read once from each skill's SKILL.md and applies to the
# whole skill folder (SKILL.md plus rules/* and references/*).
#
# Usage:
#   check-vendors.sh [--root DIR] [skill ...]
#   No skill args -> every folder under <root>/skills/.
# Exit codes: 0 pass, 1 violations, 2 usage/environment error.
set -euo pipefail

usage() {
  cat <<'EOF'
check-vendors.sh — vendor-neutrality gate for skill texts (allowlist, default-deny).

Usage:
  check-vendors.sh [--root DIR] [skill ...]

  --root DIR   repo root to scan (default: git top level, else this script's repo)
  skill ...    one or more skill folder names under <root>/skills/ to scan
               (omit to scan every skill)

Allowed in a vendor slot: acme, vendor, or the skill's declared metadata.vendor.
Exit codes: 0 pass, 1 violations, 2 usage/environment error.
EOF
}

ROOT=""
SKILLS=()
while (($#)); do
  case "$1" in
    --root) ROOT="${2:?--root needs a value}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    --) shift; while (($#)); do SKILLS+=("$1"); shift; done ;;
    -*) echo "unknown option: $1" >&2; usage >&2; exit 2 ;;
    *) SKILLS+=("$1"); shift ;;
  esac
done

if [[ -z "$ROOT" ]]; then
  ROOT="$(git rev-parse --show-toplevel 2>/dev/null || true)"
fi
if [[ -z "$ROOT" ]]; then
  ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
fi
ROOT="$(cd "$ROOT" && pwd)"

ALLOW_RE='^(acme|vendor)$'
# A module segment that is really a file name (bitrix/modules/error.log).
FILE_EXT_RE='^(log|php|txt|json|lock|pid|conf|ini|bak|gz|html|htm|js|css|xml|yml|yaml|sql|inc|md|sh)$'

declare -a FINDINGS=()
SCANNED=0

# Frontmatter `vendor:` value (lowercased) or empty.
declared_vendor() {
  [[ -f "$1" ]] || return 0
  awk '
    NR==1 && $0 !~ /^---[[:space:]]*$/ { exit }
    NR==1 { infm=1; next }
    infm && /^---[[:space:]]*$/ { exit }
    infm { print }
  ' "$1" 2>/dev/null \
    | sed -nE 's/^[[:space:]]*vendor:[[:space:]]*"?([^"[:space:]]+)"?.*/\1/p' \
    | head -n1 | tr '[:upper:]' '[:lower:]'
}

check_token() {
  local file="$1" ln="$2" tok="$3" reason="$4" dv="$5" lc
  lc="$(printf '%s' "$tok" | tr '[:upper:]' '[:lower:]')"
  [[ -z "$lc" ]] && return 0
  [[ "$lc" =~ $ALLOW_RE ]] && return 0
  [[ -n "$dv" && "$lc" == "$dv" ]] && return 0
  FINDINGS+=("${file#"$ROOT"/}:$ln  vendor '$tok'  ($reason)")
}

# emit_slot FILE GREP_ERE SED_EXTRACT_ERE REASON DECLARED_VENDOR
emit_slot() {
  local file="$1" re="$2" xf="$3" reason="$4" dv="$5" hit ln match tok
  while IFS= read -r hit; do
    [[ -z "$hit" ]] && continue
    ln="${hit%%:*}"
    match="${hit#*:}"
    tok="$(printf '%s' "$match" | sed -nE "$xf")"
    check_token "$file" "$ln" "$tok" "$reason" "$dv"
  done < <(grep -nIoE "$re" "$file" 2>/dev/null || true)
}

scan_file() {
  local file="$1" dv="$2" hit ln match parts tok ext
  # slot 1: module path prefix — skip module segments that are file names
  while IFS= read -r hit; do
    [[ -z "$hit" ]] && continue
    ln="${hit%%:*}"
    match="${hit#*:}"
    parts="$(printf '%s' "$match" | sed -nE 's#.*/modules/([A-Za-z0-9_]+)\.([A-Za-z0-9_]+).*#\1 \2#p')"
    [[ -z "$parts" ]] && continue
    tok="${parts%% *}"
    ext="${parts#* }"
    [[ "$ext" =~ $FILE_EXT_RE ]] && continue
    check_token "$file" "$ln" "$tok" 'module path prefix' "$dv"
  done < <(grep -nIoE '(local|bitrix)/modules/[A-Za-z0-9_]+\.[A-Za-z0-9_]+' "$file" 2>/dev/null || true)

  emit_slot "$file" "runAction\('[A-Za-z0-9_]+:" \
    "s#.*runAction\('([A-Za-z0-9_]+):.*#\1#p" 'AJAX action prefix' "$dv"
  emit_slot "$file" 'action=[A-Za-z0-9_]+:' \
    's#.*action=([A-Za-z0-9_]+):.*#\1#p' 'AJAX action prefix' "$dv"
  emit_slot "$file" "includeModule\('[A-Za-z0-9_]+\." \
    "s#.*includeModule\('([A-Za-z0-9_]+)\..*#\1#p" 'module load id' "$dv"
  SCANNED=$((SCANNED + 1))
}

declare -a DIRS=()
if ((${#SKILLS[@]})); then
  for s in "${SKILLS[@]}"; do
    if [[ -d "$ROOT/skills/$s" ]]; then DIRS+=("$ROOT/skills/$s")
    elif [[ -d "$ROOT/$s" ]]; then DIRS+=("$ROOT/$s")
    elif [[ -d "$s" ]]; then DIRS+=("$s")
    else echo "no such skill dir: $s" >&2; exit 2
    fi
  done
else
  for d in "$ROOT"/skills/*/; do [[ -d "$d" ]] && DIRS+=("${d%/}"); done
fi

for dir in "${DIRS[@]}"; do
  DV="$(declared_vendor "$dir/SKILL.md")"
  while IFS= read -r -d '' file; do
    scan_file "$file" "$DV"
  done < <(find "$dir" -type f ! -path '*/scripts/*' -print0)
done

if ((${#FINDINGS[@]})); then
  echo "vendor check FAILED — ${#FINDINGS[@]} non-allowed vendor token(s):" >&2
  printf '  %s\n' "${FINDINGS[@]}" >&2
  echo "fix: use 'acme'/'vendor', or declare the vendor via 'metadata.vendor' in the skill's SKILL.md frontmatter" >&2
  exit 1
fi
echo "vendor check OK — $SCANNED file(s) scanned, 0 violations"
