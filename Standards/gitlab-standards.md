---
icon: gitlab
description: GitLab project management and release standards
---

# GitLab Standards

## Project Management

### Group & Project Structure

```
Organization (Group)
├── platform (Subgroup)
│   ├── platform-api
│   └── platform-web
├── infrastructure (Subgroup)
│   ├── terraform-modules
│   └── helm-charts
└── shared (Subgroup)
    ├── ci-templates
    └── docker-images
```

- Use **Groups** for team/domain boundaries
- Use **Subgroups** for logical categorization
- Repository naming: lowercase with hyphens

### Branch Strategy

| Branch | Purpose | Naming Convention |
|--------|---------|-------------------|
| `main` | Production-ready code | Protected branch |
| `develop` | Integration branch | Protected branch |
| `feature/*` | New features | `feature/<issue-id>-short-description` |
| `bugfix/*` | Bug fixes | `bugfix/<issue-id>-short-description` |
| `hotfix/*` | Emergency production fixes | `hotfix/<issue-id>-short-description` |
| `release/*` | Release preparation | `release/v<major>.<minor>.<patch>` |

### Protected Branches

```
# Settings > Repository > Protected Branches
main:
  allowed_to_merge: Maintainers
  allowed_to_push: No one
  allowed_to_force_push: false
  require_code_owner_approval: true

develop:
  allowed_to_merge: Developers + Maintainers
  allowed_to_push: No one
```

### Issue Management

#### Issue Templates

Path: `.gitlab/issue_templates/`

```markdown
<!-- .gitlab/issue_templates/Bug.md -->
## Summary

## Environment
- GitLab version:
- OS:
- Browser:

## Steps to Reproduce
1.
2.
3.

## Expected Behavior

## Actual Behavior

## Logs / Screenshots

/label ~bug ~"needs-triage"
```

```markdown
<!-- .gitlab/issue_templates/Feature.md -->
## Summary

## Motivation

## Acceptance Criteria
- [ ] Criteria 1
- [ ] Criteria 2

## Technical Notes

/label ~feature ~"needs-triage"
```

#### Labels

| Category | Labels | Description |
|----------|--------|-------------|
| Type | `~bug`, `~feature`, `~enhancement`, `~docs` | Issue classification |
| Priority | `~P0-critical`, `~P1-high`, `~P2-medium`, `~P3-low` | Urgency level |
| Workflow | `~"needs-triage"`, `~"in-progress"`, `~"blocked"` | Current status |
| Scoped | `~"team::backend"`, `~"team::frontend"` | Team assignment |

#### Boards

- Use **Issue Boards** with label-based lists
- Standard lists: `Open` → `~"needs-triage"` → `~"in-progress"` → `~"in-review"` → `Closed`
- Create team-specific boards using scoped labels

#### Milestones & Iterations

- **Milestones**: align with release versions (e.g., `v1.2.0`)
- **Iterations** (GitLab Premium): align with sprints (e.g., `Sprint 24-W10`)
- Use milestone burndown charts to track release progress

## Code Review Standards

### Merge Request Conventions

#### MR Title Format

```
<type>(<scope>): <description>

# Examples:
feat(auth): add LDAP authentication support
fix(pipeline): resolve cache invalidation on deploy stage
docs(api): update endpoint documentation
```

#### MR Description Template

Path: `.gitlab/merge_request_templates/Default.md`

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
- [ ] Pipeline passes
- [ ] Documentation updated (if applicable)
- [ ] No breaking changes (or documented in CHANGELOG)

/assign @reviewer
/label ~"in-review"
```

#### Review Guidelines

- Review within **1 business day**
- At least **1 approval** required (configurable per project)
- Use **Squash commits** for feature branches
- Enable **Fast-forward merge** for clean history
- Remove source branch after merge
- Use **Code Owners** (CODEOWNERS file) for automatic reviewer assignment

### Approval Rules

```
# Settings > Merge Requests > Approvals
Default:
  approvals_required: 1
  approvers: @org/maintainers

Security-related:
  approvals_required: 2
  approvers: @org/security-team
  target_branch: main
```

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

4. **Merge to main via MR**
   ```bash
   # Create MR: release/v1.2.0 → main
   # After merge, tag the release
   git tag -a v1.2.0 -m "Release v1.2.0"
   git push origin v1.2.0
   ```

5. **Back-merge to develop**
   ```bash
   # Create MR: main → develop
   ```

6. **Create GitLab Release**
   - Navigate to **Deploy > Releases > New Release**
   - Select tag `v1.2.0`
   - Auto-generate release notes or write manually
   - Attach release assets if applicable

### CHANGELOG Format

Follow [Keep a Changelog](https://keepachangelog.com/):

```markdown
## [1.2.0] - 2026-03-08

### Added
- LDAP authentication support (!123)

### Fixed
- Pipeline cache invalidation on deploy (!456)

### Changed
- Upgraded dependency X to v2.0 (!789)

### Removed
- Deprecated /v1/legacy endpoint (!101)
```

### GitLab CI/CD Release Pipeline

```yaml
# .gitlab-ci.yml
stages:
  - build
  - test
  - release

variables:
  VERSION: ${CI_COMMIT_TAG}

build:
  stage: build
  script:
    - make build
  rules:
    - if: $CI_COMMIT_TAG =~ /^v\d+\.\d+\.\d+$/

test:
  stage: test
  script:
    - make test
  rules:
    - if: $CI_COMMIT_TAG =~ /^v\d+\.\d+\.\d+$/

release:
  stage: release
  image: registry.gitlab.com/gitlab-org/release-cli:latest
  script:
    - echo "Creating release for ${VERSION}"
  release:
    tag_name: ${CI_COMMIT_TAG}
    name: "Release ${CI_COMMIT_TAG}"
    description: "Release created from ${CI_COMMIT_TAG}"
  rules:
    - if: $CI_COMMIT_TAG =~ /^v\d+\.\d+\.\d+$/
```

### Environment Promotion

```yaml
# Multi-environment deployment strategy
deploy_staging:
  stage: deploy
  environment:
    name: staging
    url: https://staging.example.com
  script:
    - deploy --env staging
  rules:
    - if: $CI_COMMIT_BRANCH == "develop"

deploy_production:
  stage: deploy
  environment:
    name: production
    url: https://example.com
  script:
    - deploy --env production
  rules:
    - if: $CI_COMMIT_TAG =~ /^v\d+\.\d+\.\d+$/
  when: manual
```

## Repository Configuration

### Required Files

| File | Purpose |
|------|---------|
| `README.md` | Project overview, setup instructions |
| `LICENSE` | Open source license |
| `CHANGELOG.md` | Version history |
| `.gitignore` | Ignored files and directories |
| `CODEOWNERS` | Automatic review assignment |
| `CONTRIBUTING.md` | Contribution guidelines |
| `.gitlab-ci.yml` | CI/CD pipeline definition |
| `.gitlab/issue_templates/` | Issue templates |
| `.gitlab/merge_request_templates/` | MR templates |

### CI/CD Templates (Shared)

Store reusable CI templates in a dedicated group project:

```yaml
# In application project's .gitlab-ci.yml
include:
  - project: 'shared/ci-templates'
    ref: main
    file:
      - '/templates/docker-build.yml'
      - '/templates/helm-deploy.yml'
```

> Reference:
>
> 1. [GitLab Docs](https://docs.gitlab.com)
> 2. [Semantic Versioning](https://semver.org/)
> 3. [Keep a Changelog](https://keepachangelog.com/)
> 4. [Conventional Commits](https://www.conventionalcommits.org/)
