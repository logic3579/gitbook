---
description: GitHub project management and release standards
---

# GitHub Standards

## Project Management

### Repository Naming Convention

- Use lowercase with hyphens: `project-name`
- Prefix with team/org name for internal projects: `team-project-name`
- Avoid abbreviations; use clear, descriptive names

### Branch Strategy

| Branch | Purpose | Naming Convention |
|--------|---------|-------------------|
| `main` | Production-ready code | Protected branch |
| `develop` | Integration branch | Protected branch |
| `feature/*` | New features | `feature/<issue-id>-short-description` |
| `bugfix/*` | Bug fixes | `bugfix/<issue-id>-short-description` |
| `hotfix/*` | Emergency production fixes | `hotfix/<issue-id>-short-description` |
| `release/*` | Release preparation | `release/v<major>.<minor>.<patch>` |

### Branch Protection Rules

```yaml
# Recommended protection for main branch
main:
  require_pull_request_reviews:
    required_approving_review_count: 1
    dismiss_stale_reviews: true
  require_status_checks:
    strict: true
    contexts:
      - ci/build
      - ci/test
  enforce_admins: true
  require_linear_history: true
  allow_force_pushes: false
  allow_deletions: false
```

### Issue Management

#### Issue Templates

- **Bug Report**: environment, steps to reproduce, expected vs actual behavior, logs/screenshots
- **Feature Request**: description, motivation, acceptance criteria
- **Task**: description, subtasks checklist, related issues

#### Labels

| Category | Labels | Color |
|----------|--------|-------|
| Type | `bug`, `feature`, `enhancement`, `docs`, `chore` | — |
| Priority | `P0-critical`, `P1-high`, `P2-medium`, `P3-low` | — |
| Status | `needs-triage`, `in-progress`, `blocked`, `ready-for-review` | — |
| Size | `size/S`, `size/M`, `size/L`, `size/XL` | — |

#### Milestones

- Create milestones aligned with release versions or sprints
- Assign target dates for each milestone
- Track completion percentage for release readiness

### Project Boards

- Use GitHub Projects (V2) for Kanban-style tracking
- Standard columns: `Backlog` → `Todo` → `In Progress` → `In Review` → `Done`
- Automate status transitions via GitHub Actions or built-in automation

## Code Review Standards

### Pull Request Conventions

#### PR Title Format

```
<type>(<scope>): <description>

# Examples:
feat(auth): add OAuth2 login support
fix(api): resolve timeout issue on /users endpoint
docs(readme): update deployment instructions
```

#### PR Description Template

```markdown
## Summary
Brief description of changes.

## Changes
- Change 1
- Change 2

## Related Issues
Closes #123

## Test Plan
- [ ] Unit tests added/updated
- [ ] Integration tests pass
- [ ] Manual testing completed

## Checklist
- [ ] Code follows project style guidelines
- [ ] Self-review completed
- [ ] Documentation updated (if applicable)
- [ ] No breaking changes (or documented in CHANGELOG)
```

#### Review Guidelines

- Review within **1 business day**
- Use GitHub review statuses: `Approve`, `Request Changes`, `Comment`
- At least **1 approval** required before merge
- Use **Squash and Merge** for feature branches (clean commit history)
- Use **Merge Commit** for release branches (preserve full history)
- Delete source branch after merge

## Release Standards

### Semantic Versioning

Follow [SemVer 2.0.0](https://semver.org/):

```
MAJOR.MINOR.PATCH[-PRERELEASE][+BUILD]

# Examples:
1.0.0        # First stable release
1.1.0        # New feature (backward compatible)
1.1.1        # Bug fix
2.0.0        # Breaking change
1.2.0-rc.1   # Release candidate
```

### Release Process

1. **Create release branch** from `develop`
   ```bash
   git checkout -b release/v1.2.0 develop
   ```

2. **Version bump** — update version in package files, CHANGELOG

3. **Testing** — QA on release branch, fix bugs in-place

4. **Merge to main**
   ```bash
   git checkout main
   git merge --no-ff release/v1.2.0
   git tag -a v1.2.0 -m "Release v1.2.0"
   ```

5. **Back-merge to develop**
   ```bash
   git checkout develop
   git merge --no-ff release/v1.2.0
   ```

6. **Create GitHub Release**
   - Use tag `v1.2.0`
   - Auto-generate release notes from PRs
   - Attach build artifacts if applicable

### CHANGELOG Format

Follow [Keep a Changelog](https://keepachangelog.com/):

```markdown
## [1.2.0] - 2026-03-08

### Added
- OAuth2 login support (#123)

### Fixed
- API timeout on /users endpoint (#456)

### Changed
- Upgraded dependency X to v2.0 (#789)

### Removed
- Deprecated /v1/legacy endpoint (#101)
```

### GitHub Actions CI/CD

```yaml
# .github/workflows/release.yml
name: Release

on:
  push:
    tags:
      - 'v*'

jobs:
  release:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Build
        run: make build

      - name: Test
        run: make test

      - name: Create GitHub Release
        uses: softprops/action-gh-release@v2
        with:
          generate_release_notes: true
```

## Repository Configuration

### Required Files

| File | Purpose |
|------|---------|
| `README.md` | Project overview, setup instructions, usage |
| `LICENSE` | Open source license |
| `CHANGELOG.md` | Version history |
| `.gitignore` | Ignored files and directories |
| `CODEOWNERS` | Automatic review assignment |
| `CONTRIBUTING.md` | Contribution guidelines |
| `.github/ISSUE_TEMPLATE/` | Issue templates |
| `.github/PULL_REQUEST_TEMPLATE.md` | PR template |

### CODEOWNERS Example

```
# Global owners
* @org/engineering-leads

# Frontend
/src/frontend/ @org/frontend-team

# Backend
/src/backend/ @org/backend-team

# Infrastructure
/terraform/ @org/devops-team
/.github/ @org/devops-team
```

> Reference:
>
> 1. [GitHub Docs](https://docs.github.com)
> 2. [Semantic Versioning](https://semver.org/)
> 3. [Keep a Changelog](https://keepachangelog.com/)
> 4. [Conventional Commits](https://www.conventionalcommits.org/)
