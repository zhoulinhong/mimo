# Git 多仓库分支管理指南

## 背景

一个本地项目需要推送到两个独立的 GitHub 仓库：

- **dream 仓库**：`https://github.com/zhoulinhong/dream.git`（个人主页）
- **mimo 仓库**：`https://github.com/zhoulinhong/mimo.git`（另一个项目）

两个仓库内容不同，需要独立管理，互不影响。

## 核心概念

| 概念 | 通俗理解 |
|------|----------|
| **远程仓库（Remote）** | 托管在 GitHub 上的仓库，本质就是一个 URL |
| **分支（Branch）** | 同一份代码的不同"版本线"，切换分支就是切换不同的文件状态 |
| **origin** | 远程仓库的别名，这里指向 dream |
| **mimo** | 另一个远程仓库的别名，指向 mimo |
| **推送（Push）** | 把本地的改动上传到 GitHub |

## 仓库与分支对应关系

```
你的电脑                              GitHub
                                
分支 main ───────────────────→ zhoulinhong/dream（别名 origin）
                                
分支 mimo-main ──────────────→ zhoulinhong/mimo（别名 mimo）
```

- 你在 `main` 分支上做什么，只影响 dream 仓库
- 你在 `mimo-main` 分支上做什么，只影响 mimo 仓库
- 两个分支完全独立，互不干扰

## 远程仓库配置

查看当前远程仓库：

```powershell
git remote -v
```

输出：

```
mimo    https://github.com/zhoulinhong/mimo.git (fetch)
mimo    https://github.com/zhoulinhong/mimo.git (push)
origin  https://github.com/zhoulinhong/dream.git (fetch)
origin  https://github.com/zhoulinhong/dream.git (push)
```

- `origin` 指向 dream 仓库
- `mimo` 指向 mimo 仓库

## 日常操作流程

### 操作 dream 仓库

```powershell
# 1. 切换到 main 分支
git checkout main

# 2. 确认当前分支
git branch

# 3. 修改文件...
# 4. 查看改动
git status

# 5. 暂存文件（准备提交）
git add 文件名
# 或暂存所有改动
git add .

# 6. 提交
git commit -m "描述你做了什么"

# 7. 推送到 GitHub
git push origin main
```

### 操作 mimo 仓库

```powershell
# 1. 切换到 mimo-main 分支
git checkout mimo-main

# 2. 修改文件...
# 3. 暂存并提交
git add .
git commit -m "描述你做了什么"

# 4. 推送到 GitHub（注意：本地 mimo-main → 远程 main）
git push mimo mimo-main:main
```

## 命令速查

| 操作 | 命令 |
|------|------|
| 查看所有分支 | `git branch -a` |
| 切换分支 | `git checkout <分支名>` |
| 查看当前改动 | `git status` |
| 查看提交历史 | `git log --oneline -5` |
| 暂存文件 | `git add <文件名>` 或 `git add .` |
| 提交 | `git commit -m "提交信息"` |
| 推送到 dream | `git push origin main` |
| 推送到 mimo | `git push mimo mimo-main:main` |
| 拉取远程更新 | `git pull <远程别名> <分支名>` |

## 常见问题

### Q: 怎么知道自己在哪个分支？

```powershell
git branch
```

前面带 `*` 的就是当前分支。

### Q: 推送时报 "rejected (fetch first)"？

远程仓库有你本地没有的更新，先拉取再推送：

```powershell
git pull <远程别名> main
```

有冲突就解决冲突，没有冲突就自动合并，然后再 `git push`。

### Q: 推送到 mimo 为什么是 `mimo-main:main`？

因为本地分支叫 `mimo-main`，但远程仓库的分支叫 `main`。格式是 `本地分支:远程分支`。

## 本次搭建过程

1. 添加第二个远程仓库 `mimo`
2. 拉取 mimo 远程内容到本地
3. 创建 `mimo-main` 分支保存 mimo 的内容
4. 将 `main` 分支保持给 dream 使用
5. 两个分支独立管理，互不影响
