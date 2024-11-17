# Version Control

## Git
### branch
```bash
# 创建分支
git branch dev

# 删除本地分支
git branch -d --force dev 
git branch -D dev
# 删除远程分支
git push origin --delete dev

# 关联本地和远程dev分支
git branch --set-upstream-to=origin/dev dev 
```

### config
```bash
# 设置别名
git config --global alias.test "command"
git config --global alias.lg "log --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit"

# 保存认证信息
git config credential.helper 'cache --timeout=3600' [--global]
git config credential.helper store [--global]
git config user.name yakir
git config user.email yakir@gmail.com
```

### common
```bash
# mv and rm
git mv x.json
git rm x.json

# tag
# 根据版本号打标签
git tag v1.0 dsv34dsdv
# 本地删除标签
git tag -d v0.9 
# 远程删除标签
git push origin :refs/tags/v0.9 

# 合并dev分支到当前分支，fast-forward模式 新版本git
git merge dev 
# 删除分支后保留合并记录
git merge --no-ff -m "merge with no-ff" dev 
# 查看分支记录
git log --graph --pretty=oneline --abbrev-commit 
# 分支变基
git rebase
```

### checkout
```bash
# 创建并合并分支
git checkout -b dev 

# 创建本地分支管理远程 dev 分支
git checkout -b dev origin/dev 
```

### remote repo
```bash
# relationship remote repo
git remote add origin https://github.com/username/reponame.git 
git remote -v 

# pull and push remote repo
git pull main
git push origin main 

# 查看所有远程库信息
git branch --all |grep remotes
```

### stash
```bash
# 暂存工作到堆栈去
git stash save "stash message for log"
# 查看所有暂存堆栈
git stash list 
# 恢复暂存堆栈工作并删除 == git stash apply + git stash drop
git stash pop 
# 复制某一个特定提交到当前分支 既可在master分支上修复bug后，在dev分支上可以“重放”这个修复过程，也可以在dev分支上修复bug，然后在master分支上“重放”
git cherry-pick 4c805e2
```

### version control
```bash
# 查看当前版本
git rev-parse HEAD


# 回退上一个版本
git reset --hard HEAD^ 
# 回退两个版本
git reset --hard HEAD^^
# 回退10个版本
git reset --hard HEAD~10
# 指定版本
git reset --hard fd301d 指定版本


# 查看 git 每次执行命令
git reflog
# 撤销修改区回到最新版本
git checkout -- file 
# 撤销添加暂存区回到修改区 撤销add，回到修改区
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
