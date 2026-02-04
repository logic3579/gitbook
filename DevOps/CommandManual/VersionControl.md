# Version Control

## Git

### branch

```bash
# get branch logs
git log --graph --pretty=oneline --abbrev-commit

# get all branch
git branch -a
# get all remote branch
git branch -r

# create branch
git branch dev

# create and switch to branch
git fetch && git checkout -b dev
# link local and remote branch
git branch --set-upstream-to=origin/dev dev
git push dev

# create local branch and track remote branch
git fetch && git switch -c dev origin/dev
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

# delete local branch
git branch -d --force dev
# delete remote branch
git push origin --delete dev

```

### config

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

### cherry-pick

```bash
# copy a specific commit to the current branch
# useful for replaying a bug fix from main to dev, or vice versa
git cherry-pick 4c805e2
```

### rebase

```bash
# rebase branch
git rebase
```

### stash

```bash
# stash current work to the stack
git stash save "stash message for log"
# list all stash entries
git stash list
# restore stash and remove it from stack (= git stash apply + git stash drop)
git stash pop
```

### tag

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

### version control

```bash
# view current version
git rev-parse HEAD

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

## Subversion

```bash
svn list svn://1.1.1.1:3690/my-repo/
svn checkout svn://1.1.1.1:3690/my-repo/

svn add ./*
svn commit -m 'commit message'
svn update

svn update -r xxx
```
