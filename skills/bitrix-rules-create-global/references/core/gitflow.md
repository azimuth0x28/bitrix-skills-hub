# Git Process

<context>
  <system_context>
    Rules below are the hub default git process. Branch models, naming, and
    release mechanics differ between teams and are project facts: the observed
    repository practice wins over this default. Adapt this file to the real
    process and record the adaptation instead of enforcing details nobody uses.
  </system_context>

  <domain_context>
    Branch model · Conventional Commits · review flow · release tagging.
  </domain_context>
</context>

<critical_rules enforcement="strict">
  <rule id="observe-first" scope="all-git-work">
    Read the team's actual git process from the repository before creating
    branches, releases, or tags: `git branch -r`, merge history, CI/CD config,
    `CHANGELOG.md`. This file states the default; the observed process wins.
  </rule>

  <rule id="conventional-commits" scope="commits">
    MUST use Conventional Commits in Russian (`feat(import): Добавлена поддержка XML`): `type(scope): subject`, types limited to `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`; subject in
    the imperative mood, body explains "why" for complex changes.
  </rule>

  <rule id="no-direct-main-commits" scope="code-review">
    MUST NOT commit directly to `main` or any production branch; route changes
    through review — a PR when the team has a PR process.
  </rule>

  <rule id="traceable-branches" scope="all-branches">
    Branch names must be traceable: a task-tracking number when the project
    has a tracker (`feature/task-123`), otherwise an explicit `no-task` marker
    with a short description (`feature/no-task/refactoring-init`).
  </rule>
</critical_rules>

## Review

- Keep PRs and changes focused and small — one concern per PR.
- CI/CD must pass before merge when the project has CI.

## Releases

- Tag releases with semantic versioning (`vX.Y.Z`); the tag goes on the merge
  commit into the production branch.
- Record what changed on every release — `CHANGELOG.md` or tracker releases,
  per the team's existing practice.

## Default branch model (adjust to the team's process)

Git-Flow-derived default; replace it wholesale when the repository shows a
different model — keep one model, do not mix:

- Long-lived: `main` (production) ← `develop` (integration).
- Short-lived, created from `develop`: `feature/task-123`, `bugfix/task-456`;
  `release/vX.Y.Z` before production deploys.
- `hotfix/task-789` from `main`, then delivered to all long-lived branches.
