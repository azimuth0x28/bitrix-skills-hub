#!/usr/bin/env bash
# check-budgets.sh — line-count budget gate with a ratchet baseline.
# Run from repo root. Exits 0 on pass, 1 on new or stale violations.
#
# Budgets:
#   skills/<n>/SKILL.md with rules/ dir  -> router,  max 60 lines
#   skills/<n>/SKILL.md without rules/   -> monolith, min 100, max 310 lines
#   skills/<n>/rules/*.md                -> min 45, max 135 lines
#
# Ratchet semantics: .github/scripts/budget-baseline.txt records the known
# violations (one "<path> <count>" per line). The baseline only ever shrinks:
#   - violation NOT in baseline            -> ::error, exit 1
#   - baseline entry no longer a violation -> ::error (stale), exit 1
#   - violation IN baseline                -> ::warning, tallied
# Fixes must remove their line from the baseline (never add to it).
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$REPO_ROOT"

BASELINE_FILE=".github/scripts/budget-baseline.txt"

# --- Load baseline: path -> count ---
declare -A BASELINE
while read -r path count; do
  [[ -z "$path" || -z "$count" ]] && continue
  BASELINE["$path"]="$count"
done < "$BASELINE_FILE"

# --- Collect live violations: "<path> <count> (<budget>)" ---
VIOLATIONS=()
while IFS= read -r file; do
  count=$(wc -l < "$file")
  if [[ "$file" == */SKILL.md ]]; then
    dir="${file%/SKILL.md}"
    if [[ -d "$dir/rules" ]]; then
      if (( count > 60 )); then
        VIOLATIONS+=("$file $count (router max 60)")
      fi
    else
      if (( count < 100 )); then
        VIOLATIONS+=("$file $count (monolith min 100)")
      fi
      if (( count > 310 )); then
        VIOLATIONS+=("$file $count (monolith max 310)")
      fi
    fi
  elif [[ "$file" == */rules/*.md ]]; then
    if (( count < 45 )); then
      VIOLATIONS+=("$file $count (rule min 45)")
    fi
    if (( count > 135 )); then
      VIOLATIONS+=("$file $count (rule max 135)")
    fi
  fi
done < <(find skills -type f \( -name 'SKILL.md' -o -path '*/rules/*.md' \) | sort)

FAILED=false
WARNINGS=0

echo "--- Line budget gate (ratchet) ---"

# --- 1. Live violations: in baseline -> warning, else error ---
for entry in "${VIOLATIONS[@]}"; do
  path="${entry%% *}"
  if [[ -n "${BASELINE[$path]:-}" ]]; then
    echo "::warning file=$path::$entry (in baseline)"
    WARNINGS=$((WARNINGS + 1))
  else
    echo "::error file=$path::$entry (not in baseline)"
    FAILED=true
  fi
done

# --- 2. Baseline entries that no longer violate -> stale, error ---
for path in "${!BASELINE[@]}"; do
  matched=false
  for entry in "${VIOLATIONS[@]}"; do
    if [[ "${entry%% *}" == "$path" ]]; then
      matched=true
      break
    fi
  done
  if [[ "$matched" == "false" ]]; then
    echo "::error::stale baseline entry — remove it"
    FAILED=true
  fi
done

echo "Violations: ${#VIOLATIONS[@]} total, $WARNINGS in baseline (warned), $(( ${#VIOLATIONS[@]} - WARNINGS )) new (errored)"

# --- Final verdict ---
if [[ "$FAILED" == "true" ]]; then
  echo ""
  echo "::error::Line budget gate FAILED"
  exit 1
fi

echo ""
echo "✓ Line budget gate passed ($WARNINGS baseline violations tolerated)"