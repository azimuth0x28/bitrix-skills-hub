#!/usr/bin/env python3
"""check-versions.py — enforce per-skill semantic versioning (PR gate).

Policy: any file change under skills/<name>/ requires a metadata.version
bump in skills/<name>/SKILL.md frontmatter. Semver components (see AGENTS.md
authoring pipeline): patch for fixes/doc edits, minor for new content within
a skill, major for breaking reorganizations.

Usage: check-versions.py <BASE_SHA>   (or env BASE_SHA when arg omitted)
Compares the version gate between BASE_SHA and HEAD:

  - diff skills/ between BASE and HEAD -> changed skill folders
  - HEAD metadata.version must exist and match ^\\d+\\.\\d+\\.\\d+$
  - new skill (no SKILL.md at BASE) -> pass
  - existing skill: HEAD version must be strictly greater than BASE
    numerically, component-wise (major, minor, patch)

Exit 0 on pass; exit 1 with `::error` GitHub annotations otherwise.
"""

import os
import re
import subprocess
import sys

import yaml

SEMVER_RE = re.compile(r"^\d+\.\d+\.\d+$")
FRONTMATTER_DELIM = "---"


def git(args):
    """Run a git command, return CompletedProcess (text, captured)."""
    return subprocess.run(["git"] + args, capture_output=True, text=True)


def extract_frontmatter(text):
    """Return the YAML frontmatter block of a SKILL.md blob, or None."""
    lines = text.splitlines()
    if not lines or lines[0].strip() != FRONTMATTER_DELIM:
        return None
    for i in range(1, len(lines)):
        if lines[i].strip() == FRONTMATTER_DELIM:
            return "\n".join(lines[1:i])
    return None


def load_version(blob):
    """Extract metadata.version from a SKILL.md blob; None if absent/invalid shape."""
    fm = extract_frontmatter(blob)
    if fm is None:
        return None
    try:
        data = yaml.safe_load(fm)
    except yaml.YAMLError:
        return None
    if not isinstance(data, dict):
        return None
    meta = data.get("metadata")
    if not isinstance(meta, dict):
        return None
    version = meta.get("version")
    if version is None:
        return None
    return str(version)


def compare_versions(head_version, base_version):
    """+1 if head > base, -1 if head < base, 0 if equal (component-wise)."""
    head = tuple(int(p) for p in head_version.split("."))
    base = tuple(int(p) for p in base_version.split("."))
    return (head > base) - (head < base)


def changed_skill_folders(base):
    """Sorted set of skill folder names touched between base and HEAD."""
    diff = git(["diff", "--name-only", base, "HEAD", "--", "skills/"])
    folders = set()
    for line in diff.stdout.splitlines():
        parts = line.split("/", 2)
        if len(parts) >= 3 and parts[0] == "skills":
            folders.add(parts[1])
    return sorted(folders)


def main():
    base = sys.argv[1] if len(sys.argv) > 1 else os.environ.get("BASE_SHA")
    if not base:
        print("no base ref: skip")
        return 0

    folders = changed_skill_folders(base)
    if not folders:
        print("no changed skills")
        return 0

    errors = 0
    for folder in folders:
        path = f"skills/{folder}/SKILL.md"

        # Deleted or renamed away at HEAD -> nothing to gate.
        if git(["cat-file", "-e", f"HEAD:{path}"]).returncode != 0:
            print(f"skip  {path} (no SKILL.md at HEAD)")
            continue

        head_version = load_version(git(["show", f"HEAD:{path}"]).stdout)
        head_valid = head_version is not None and bool(SEMVER_RE.match(head_version))
        if not head_valid:
            errors += 1
            print(f"::error file={path}::metadata.version missing or invalid (expected X.Y.Z)")
            print(f"fail  {path} — metadata.version missing or invalid (expected X.Y.Z)")
            continue

        # New skill (no SKILL.md at base) -> presence + version already checked.
        if git(["cat-file", "-e", f"{base}:{path}"]).returncode != 0:
            print(f"pass  {path} — new skill (version {head_version})")
            continue

        base_version = load_version(git(["show", f"{base}:{path}"]).stdout)
        if base_version is None:
            # Legacy adoption: base SKILL.md predates metadata.version.
            print(f"pass  {path} — legacy adoption (base without metadata.version, head {head_version})")
            continue

        if not SEMVER_RE.match(base_version):
            print(f"pass  {path} — base version unparseable ({base_version!r}), head {head_version}")
            continue

        if compare_versions(head_version, base_version) > 0:
            print(f"pass  {path} — {base_version} -> {head_version}")
        else:
            errors += 1
            print(f"::error file={path}::bump metadata.version (base {base_version}, head {head_version})")
            print(f"fail  {path} — version not strictly increased ({base_version} -> {head_version})")

    if errors:
        print(f"{errors} version gate error(s)")
        return 1

    print(f"✓ version gate passed ({len(folders)} changed skill(s))")
    return 0


if __name__ == "__main__":
    sys.exit(main())