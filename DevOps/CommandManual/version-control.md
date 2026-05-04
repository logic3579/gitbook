---
description: Git, GitHub CLI, and Subversion CLI references
tags:
  - devops/command
---

# Version Control

## Git

### Configuration

```bash
# set alias
git config --global alias.lg "log --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit" [--global]

# save credentials
git config credential.helper 'cache --timeout=3600' [--global]
git config credential.helper store [--global]
git config user.name logic [--global]
git config user.email logic3579@duck.com [--global]

# add and view remote repository
git remote add origin https://github.com/username/reponame.git
git remote -v
```

### Branching

```bash
# list all branches / remote-only
git branch -a
git branch -r

# create branch
git branch dev

# create and switch to branch
git fetch && git checkout -b dev

# create local branch and track remote branch
git fetch && git switch -c dev origin/dev
git push dev

# delete local branch
git branch -d --force dev
# delete remote branch
git push origin --delete dev
```

### Syncing (fetch / pull / push)

```bash
# link local and remote branch
git branch --set-upstream-to=origin/dev dev
git push dev

# fetch all remote branches (update local index)
git fetch --all
# update remote branch to local branch
git pull

# merge latest remote dev into current main
git switch main
git fetch origin dev:dev
git merge dev

# on dev branch, force update main to match dev
git fetch origin
git branch -f main develop
git push origin main
```

### Stashing

```bash
# stash current work to the stack
git stash save "stash message for log"
# list all stash entries
git stash list
# restore stash and remove it from stack (= git stash apply + git stash drop)
git stash pop
```

### Tagging

```bash
# tag based on Annotated Tag
git tag -a v1.0.0 -m "Release v1.0.0"

# show and check tag
git show v1.0.0

# push tag to remote repository
git push origin v1.0.0

# show remote tag
git ls-remote --tags origin

# delete local/remote tag
git tag -d v1.0.0
git push origin --delete tag v1.0.0
```

### Cherry-pick & Rebase

```bash
# copy a specific commit to the current branch
# useful for replaying a bug fix from main to dev, or vice versa
git cherry-pick 4c805e2

# rebase branch
git rebase
```

### Undo & History

```bash
# view branch log graph
git log --graph --pretty=oneline --abbrev-commit

# view current version
git rev-parse HEAD

# show commit details with diff
git show HEAD                          # latest commit
git show 4c805e2                       # specific commit by hash
git show HEAD~1                        # parent of HEAD
# show only file change stats
git show --stat HEAD
# show only the names of changed files
git show --name-only HEAD
# show file content at a specific commit
git show 4c805e2:path/to/file

# undo commit but keep changes in staging area (staged)
git reset --soft HEAD~1
# undo commit and unstage changes (keep working directory modifications)
git reset --mixed HEAD~1
# completely undo commit and discard all changes
git reset --hard HEAD~1

# rollback to previous version
git reset --hard HEAD^
# rollback two versions
git reset --hard HEAD^^
# rollback 10 versions
git reset --hard HEAD~10
# rollback to specific version
git reset --hard fd301d

# view git command history
git reflog
# discard working directory changes and restore to latest version
git checkout -- file
# unstage file (undo git add, move back to working directory)
git reset HEAD file
```

## GitHub CLI (gh)

### auth

```bash
# login to GitHub (interactive browser-based)
gh auth login

# login with a token
gh auth login --with-token < token.txt

# check authentication status
gh auth status

# switch between GitHub accounts
gh auth switch

# logout
gh auth logout
```

### repo

```bash
# clone a repository
gh repo clone owner/repo

# create a new repository (interactive)
gh repo create my-repo --public --clone
gh repo create my-repo --private --source=. --remote=origin --push

# fork a repository
gh repo fork owner/repo --clone

# view repository in browser
gh repo view --web

# list your repositories
gh repo list --limit 20

# archive a repository
gh repo archive owner/repo
```

### pr (Pull Request)

```bash
# create a pull request (interactive)
gh pr create
# create with title and body
gh pr create --title "feat: add feature" --body "Description"
# create draft PR targeting a specific base branch
gh pr create --draft --base main

# list pull requests
gh pr list
gh pr list --state closed --author @me

# view PR details
gh pr view 123
gh pr view 123 --web

# checkout a PR branch locally
gh pr checkout 123

# review a PR
gh pr review 123 --approve
gh pr review 123 --request-changes --body "Please fix..."
gh pr review 123 --comment --body "Looks good"

# merge a PR
gh pr merge 123 --squash --delete-branch
gh pr merge 123 --rebase
gh pr merge 123 --merge

# view PR diff and checks
gh pr diff 123
gh pr checks 123

# close a PR without merging
gh pr close 123
```

### issue

```bash
# create an issue (interactive)
gh issue create
gh issue create --title "Bug: ..." --body "Steps to reproduce" --label bug

# list issues
gh issue list
gh issue list --assignee @me --state open

# view issue details
gh issue view 42
gh issue view 42 --web

# close / reopen an issue
gh issue close 42
gh issue reopen 42

# add comment to an issue
gh issue comment 42 --body "Fixed in #123"
```

### run (GitHub Actions)

```bash
# list recent workflow runs
gh run list

# view a specific run
gh run view 123456789
gh run view 123456789 --log

# watch a run in progress
gh run watch 123456789

# re-run a failed workflow
gh run rerun 123456789
gh run rerun 123456789 --failed

# trigger a workflow manually
gh workflow run deploy.yml --ref main
gh workflow run deploy.yml -f environment=staging
```

### release

```bash
# create a release with auto-generated notes
gh release create v1.0.0 --generate-notes
# create a release with assets
gh release create v1.0.0 ./dist/*.tar.gz --title "v1.0.0" --notes "Release notes"
# create a draft / prerelease
gh release create v1.0.0-rc1 --prerelease --draft

# list and view releases
gh release list
gh release view v1.0.0

# download release assets
gh release download v1.0.0 --dir ./downloads

# delete a release
gh release delete v1.0.0 --yes
```

### api

```bash
# call GitHub REST API directly
gh api repos/owner/repo
gh api repos/owner/repo/pulls/123/comments

# POST request with JSON body
gh api repos/owner/repo/issues -f title="Bug" -f body="Details"

# paginate results
gh api repos/owner/repo/issues --paginate

# use GraphQL
gh api graphql -f query='{ viewer { login } }'
```

### gist

```bash
# create a gist
gh gist create file.txt
gh gist create --public file.txt --desc "description"

# list and view gists
gh gist list
gh gist view <gist-id>

# edit / delete
gh gist edit <gist-id>
gh gist delete <gist-id>
```

### search

```bash
# search repositories, issues, PRs, code
gh search repos "kubernetes language:go" --limit 10
gh search issues "bug label:critical" --repo owner/repo
gh search prs "review:required" --state open
gh search code "func main" --repo owner/repo
```

### ssh-key & gpg-key

```bash
# manage SSH keys and GPG keys
gh ssh-key list
gh ssh-key add ~/.ssh/id_ed25519.pub --title "my-key"
gh gpg-key list
```

### config

```bash
# view and set configuration
gh config list
gh config set editor vim
gh config set git_protocol ssh
```

### codespace

```bash
# manage GitHub Codespaces
gh codespace list
gh codespace create --repo owner/repo
gh codespace ssh -c <codespace-name>
```

### extension

```bash
# install / list / upgrade extensions
gh extension install owner/gh-extension
gh extension list
gh extension upgrade --all
```

## Subversion

### Inspection

```bash
# list directory entries on the server
svn list svn://1.1.1.1:3690/my-repo/

# show info about a working copy or URL
svn info
svn info svn://1.1.1.1:3690/my-repo/trunk

# show local modification status
svn status

# show diff of local modifications / between revisions
svn diff
svn diff -r 100:HEAD path/to/file

# annotate file lines with last-changed revision and author
svn blame path/to/file

# show file contents at a specific revision
svn cat -r 100 path/to/file
```

### Working Copy Changes

```bash
# schedule files / dirs for addition
svn add ./*

# remove files / dirs (working copy + scheduled deletion)
svn delete path/to/file

# move or rename (preserves history)
svn move old-name new-name

# copy within a working copy (preserves history)
svn copy src dst

# discard local modifications
svn revert path/to/file
svn revert -R .                        # recursive
```

### Syncing (checkout / update / commit)

```bash
# initial checkout of a working copy
svn checkout svn://1.1.1.1:3690/my-repo/

# update working copy to latest revision
svn update

# update to a specific revision (time-travel the working copy)
svn update -r 100

# commit local modifications
svn commit -m 'commit message'
svn commit path/to/file -m 'message'   # commit only specific paths
```

### Branching & Tagging

SVN creates branches and tags by copying URLs — typically under `branches/` and `tags/` by convention. Tags are immutable only by team agreement, not enforcement.

```bash
# create a branch from trunk
svn copy svn://1.1.1.1:3690/my-repo/trunk \
         svn://1.1.1.1:3690/my-repo/branches/feature-x \
         -m "Create branch feature-x"

# create a tag from trunk
svn copy svn://1.1.1.1:3690/my-repo/trunk \
         svn://1.1.1.1:3690/my-repo/tags/v1.0.0 \
         -m "Tag v1.0.0"

# switch working copy to another branch
svn switch svn://1.1.1.1:3690/my-repo/branches/feature-x

# merge changes from a branch into the working copy
svn merge svn://1.1.1.1:3690/my-repo/branches/feature-x
svn merge -r 100:120 svn://1.1.1.1:3690/my-repo/branches/feature-x
```

### Undo & History

```bash
# show commit log (limit / verbose / revision range)
svn log
svn log -l 10
svn log -v
svn log -r 100:HEAD

# resolve conflicts after merge / update
svn resolve --accept working path/to/file

# clean up a stuck working copy (locks, interrupted operations)
svn cleanup
```

> Reference:
>
> 1. [Git Documentation](https://git-scm.com/doc)
> 2. [Pro Git Book](https://git-scm.com/book)
> 3. [GitHub CLI Manual](https://cli.github.com/manual/)
> 4. [Subversion Documentation](https://subversion.apache.org/docs/)
