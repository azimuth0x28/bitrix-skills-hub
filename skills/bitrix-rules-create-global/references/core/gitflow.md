# Git Process

<context>
  <system_context>
    The repository follows a Git Flow derived workflow with three long-lived root
    branches (`main`, `pre-prod`, `develop`) and four short-lived branch types
    (`feature/`, `bugfix/`, `release/`, `hotfix/`). Branch names encode a task
    tracking number so every change is traceable to a tracker entry.
  </system_context>

  <domain_context>
    Git Flow · Conventional commits · release branches (`release/vX.Y.Z`) ·
    semantic versioning tags (`vX.Y.Z`, `vX.Y.Z-rcN`) · hotfix propagation.
  </domain_context>
</context>

<critical_rules enforcement="strict">
  <rule id="branch-source-develop" scope="all-branches">
    All new branches are created only from `develop`; the only exception is
    `hotfix/*`, which is created from `main`.
  </rule>

  <rule id="branch-naming" scope="all-branches">
    Branch names must contain a task tracking number (`feature/task-123`,
    `bugfix/task-323`) or an explicit `no-task` marker when there is no task in
    the tracker (`feature/no-task/refactoring-init`). Bare names without either
    are invalid.
  </rule>

  <rule id="merge-before-develop" scope="feature-bugfix">
    Before merging into `develop`, first merge `develop` into the feature|bugfix
    branch and resolve conflicts.
  </rule>

  <rule id="final-tag-on-main" scope="releases">
    Final release tags (`vX.Y.Z`) are placed only on the release merge commit
    into `main`.
  </rule>

  <rule id="conventional-commits" scope="commits">
    MUST use Conventional commits: `type(scope): subject`, with only the types
    `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`.
  </rule>

  <rule id="no-direct-main-commits" scope="code-review">
    MUST NOT make direct commits to `main`; route changes through review —
    on `develop` before a release, or through a PR when the team has a PR process.
  </rule>

  <rule id="hotfix-propagation" scope="hotfix">
    Hotfixes go straight to `main` and are then delivered to all long-lived branches.
  </rule>
</critical_rules>

## 1. Main Branches (Root Nodes)

Long-lived root branches:

- `main` — Production (the final branch for delivering code to the production site)
- `pre-prod` — Pre-production (release preparation and testing). Usually a server in the Customer's environment
- `develop` — Integration testing. All new branches are created only from it

Short-lived development branches:

1. **feature/** — for developing new functionality; created from `develop`
2. **bugfix/** — for fixing bugs in current development; created from `develop` or `release`
3. **release/** — for preparing a release version (format `release/vX.Y.Z`); created from `develop`
4. **hotfix/** — for urgent fixes in production (branch `main`); created from `main`

## 2. Branch Naming Conventions

All branches must follow the template:

- `(feature|bugfix|hotfix)/<tracking-number>`
- `(feature|bugfix|hotfix)/<tracking-number>/<stage>`
- `(feature|bugfix)/no-task/<description>` — exception when there is no task in the tracker: refactoring initiative, CI/CD preparation, and similar cases

- `feature/task-123` — a feature with a task tracking number
- `feature/task-234/subfeature_step_1` — a complex feature made of several sub-tasks within the feature
- `bugfix/task-456` — a bug fix
- `hotfix/task-789` — an urgent fix for the production site `main`
- `release/vX.Y.Z` — a versioned release branch (e.g. `release/v1.2.0`)
- `release/rc-epic/<name>` — a draft release branch accumulating functionality that will later be merged into a versioned branch

**Correct branch names:**

- ✅ `feature/task-123/login-page`
- ✅ `feature/task-234`
- ✅ `bugfix/task-456/auth-fix`
- ✅ `hotfix/task-789/critical-error`
- ✅ `feature/no-task/refactoring-init`
- ✅ `bugfix/no-task/cicd-prepare`
- ✅ `release/v1.2.0`

**Incorrect branch names:**

- ❌ `feature/login` (no task number and no `no-task` marker)
- ❌ `fix/auth` (does not match the format)

## 3. Tags (Versioning)

- **Release candidates (RC):** `vX.Y.Z-rcN` (e.g. `v1.2.0-rc1`). Tag every bugfix merge into `release`
- **Final releases:** `vX.Y.Z` — the tag is placed only on the release merge commit into `main`

## Commits

- Limit the subject to 50 characters
- Add a commit body explaining "why" for complex changes

## Code review

- If the team has a PR process: route all changes to `develop` and `main` through PRs, involve at least one reviewer, and require CI/CD to pass
- Keep PRs/changes focused and small

## Releases

- Tag releases with semantic versioning (`v1.2.3`)
- Create a release branch from `develop` before deploying to production
- Update `CHANGELOG.md` on every release

## Overall Workflow

1. All new branches are created only from `develop`.
2. Branch names must contain a task tracking number (`feature/task-123`, `bugfix/task-323`) or an explicit `no-task` marker when there is no task in the tracker (`feature/no-task/refactoring-init`).
3. Before merging into `develop` — first merge `develop` into the feature|bugfix branch and resolve conflicts.
4. Releases are named `release/vX.Y.Z`, tags — `vX.Y.Z` (final, only on the merge commit into `main`).
5. Hotfixes go straight to `main` and are then delivered to all long-lived branches.