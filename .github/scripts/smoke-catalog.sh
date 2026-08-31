#!/usr/bin/env bash
# smoke-catalog.sh — Verify README catalogs match skills/ folders and SKILL.md files exist.
# Run from repo root. Exits 0 on success, 1 on mismatch.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$REPO_ROOT"

# --- 1. Collect actual skill folders (base names only) ---
mapfile -t FOLDERS < <(ls -d skills/*/ 2>/dev/null | xargs -I{} basename {} | sort)
FOLDER_COUNT=${#FOLDERS[@]}

if [[ $FOLDER_COUNT -eq 0 ]]; then
  echo "::error::No skill folders found under skills/"
  exit 1
fi
echo "Found $FOLDER_COUNT skill folders under skills/"

# --- 2. Extract catalog entries from each README ---
extract_skills() {
  local file="$1"
  # Two extraction strategies unioned (produces bare base names):
  #   a) skills/<name> path refs  (future 3-col linked format)
  #   b) backtick-quoted names   (current 2-col inline-code format)
  {
    grep -oE 'skills/[a-z0-9][a-z0-9-]*' "$file" 2>/dev/null | sed 's|^skills/||' || true
    grep -oE '`[a-z0-9][a-z0-9-]*`'    "$file" 2>/dev/null | sed 's/`//g'           || true
  } | sort -u
}

compare_sets() {
  local label="$1" file="$2"
  mapfile -t README_SKILLS < <(extract_skills "$file")
  local readme_count=${#README_SKILLS[@]}

  if [[ $readme_count -eq 0 ]]; then
    echo "::warning::No skill entries found in $file"
    return 0
  fi
  echo "$file: $readme_count catalog entries"

  local in_folders_not_readme in_readme_not_folders
  in_folders_not_readme=$(comm -23 <(printf '%s\n' "${FOLDERS[@]}" | sort) <(printf '%s\n' "${README_SKILLS[@]}" | sort) || true)
  in_readme_not_folders=$(comm -13 <(printf '%s\n' "${FOLDERS[@]}" | sort) <(printf '%s\n' "${README_SKILLS[@]}" | sort) || true)

  local ok=true
  if [[ -n "$in_folders_not_readme" ]]; then
    echo "::error::$file — folders present in skills/ but NOT in $file:"
    echo "$in_folders_not_readme" | sed 's/^/  - skills\//'
    ok=false
  fi
  if [[ -n "$in_readme_not_folders" ]]; then
    echo "::error::$file — entries in $file but NOT in skills/:"
    echo "$in_readme_not_folders" | sed 's/^/  - skills\//'
    ok=false
  fi

  if [[ "$ok" == "false" ]]; then
    return 1
  fi
  echo "  ✓ Set match OK"
  return 0
}

FAILED=false

echo "--- README.md ---"
compare_sets "README.md" README.md || FAILED=true

echo "--- README.ru.md ---"
compare_sets "README.ru.md" README.ru.md || FAILED=true

# --- 3. Verify every referenced SKILL.md exists ---
echo "--- SKILL.md existence check ---"
MISSING_SKILLS=()
for skill in "${FOLDERS[@]}"; do
  if [[ ! -f "skills/$skill/SKILL.md" ]]; then
    MISSING_SKILLS+=("skills/$skill/SKILL.md")
  fi
done

if [[ ${#MISSING_SKILLS[@]} -gt 0 ]]; then
  echo "::error::Missing SKILL.md files:"
  printf '  %s\n' "${MISSING_SKILLS[@]}"
  FAILED=true
else
  echo "  ✓ All $FOLDER_COUNT SKILL.md files present"
fi

# --- Final verdict ---
if [[ "$FAILED" == "true" ]]; then
  echo ""
  echo "::error::Catalog smoke test FAILED"
  exit 1
fi

echo ""
echo "✓ Catalog smoke test passed ($FOLDER_COUNT folders, both READMEs match)"
