# Git 常用命令速查

---

## 查看状态与历史

```bash
git status                  # 查看哪些文件改过、哪些暂存了
git log --oneline           # 查看提交历史（简洁模式）
git log --oneline --graph   # 带分支图的提交历史
git diff                    # 查看具体改了什么内容（未暂存）
git diff --staged           # 查看已暂存的内容改了什么
```

## 保存更改（提交三部曲）

```bash
git add 文件名               # 暂存某个文件
git add .                   # 暂存所有改过的文件
git commit -m "提交信息"      # 提交到本地仓库
git push                    # 推送到 GitHub
```

最常用的就是这三步：`add` → `commit` → `push`

## 撤销操作

```bash
git restore 文件名           # 撤销文件的修改（回到上次提交的样子）
git restore --staged 文件名  # 取消暂存（但保留修改）
git reset --soft HEAD~1     # 撤销最近一次 commit（修改回到暂存区）
```

## 远程仓库（GitHub）

```bash
git remote -v               # 查看关联的远程仓库地址
git push                    # 推送本地提交到 GitHub
git pull                    # 从 GitHub 拉取最新内容
```

## 分支操作

```bash
git branch                  # 查看本地分支
git branch 新分支名          # 创建新分支
git switch 分支名            # 切换到某个分支
git switch -c 新分支名       # 创建并切换到新分支
git merge 分支名             # 把指定分支合并到当前分支
```

## 不想追踪的文件

在项目根目录创建 `.gitignore` 文件，写入不想上传的文件名或文件夹：

```
*.log
node_modules/
.env
```

---

## 日常使用流程

```bash
# 1. 看看改了啥
git status

# 2. 暂存所有修改
git add .

# 3. 提交
git commit -m "描述你做了什么"

# 4. 推到 GitHub
git push
```

就这么四步，日常足够用了。
