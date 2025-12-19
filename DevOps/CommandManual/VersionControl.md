# Version Control

## Git

### branch

```bash
# 查看分支记录
git log --graph --pretty=oneline --abbrev-commit

# 查看所有远程分支
git branch -r
# 查看所有分支
git branch -a

# 创建分支
git branch dev

# 创建并切换分支
git checkout -b dev
# 关联本地和远程分支
git branch --set-upstream-to=origin/dev dev
git push dev
#git push origin --set-upstream origin/dev dev

# 创建本地分支并关联远程分支
git fetch
git checkout -b dev origin/dev

# 拉取远程分支并切换到本地分支
git fetch
git switch -c dev origin/dev

# 拉取所有远程分支（更新本地索引）
git fetch --all
# 更新远程分支到本地分支
git pull

# 合并分支到当前分支，fast-forward 模式
git merge dev
# 删除分支后保留合并记录
git merge --no-ff -m "merge with no-ff" dev

# 删除本地分支
git branch -d --force dev
git branch -D dev
# 删除远程分支
git push origin --delete dev

```

### config

```bash
# 设置别名
git config --global alias.lg "log --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit" [--global]

# 保存认证信息
git config credential.helper 'cache --timeout=3600' [--global]
git config credential.helper store [--global]
git config user.name logic [--global]
git config user.email logic3579@duck.com [--global]

# 添加与查看关联远程仓库
git remote add origin https://github.com/username/reponame.git
git remote -v
```

### rebase

```bash
# 分支变基
git rebase
```

### stash

```bash
# 暂存工作到堆栈去
git stash save "stash message for log"
# 查看所有暂存堆栈
git stash list
# 恢复暂存堆栈工作并删除 == git stash apply + git stash drop
git stash pop
# 复制某一个特定提交到当前分支，既可在 main 分支上修复 bug 后，在 dev 分支上可以重放这个修复过程
# 也可以在 dev 分支上修复 bug，然后在 main 分支上重放
git cherry-pick 4c805e2
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
# 查看当前版本
git rev-parse HEAD

# 撤销 commit，但保留修改，修改内容回到暂存区（staged）
git reset --soft HEAD~1
# 撤销 commit，并把修改也取消暂存（保留工作区修改），修改仍存在但不在暂存区
git reset --mixed HEAD~1
# 彻底撤销 commit，并丢掉所有改动
git reset --hard HEAD~1

# 回退上一个版本
git reset --hard HEAD^
# 回退两个版本
git reset --hard HEAD^^
# 回退10个版本
git reset --hard HEAD~10
# 指定版本
git reset --hard fd301d

# 查看 git 每次执行命令
git reflog
# 撤销修改区回到最新版本
git checkout -- file
# 撤销添加暂存区回到修改区，撤销add 回到修改区
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
