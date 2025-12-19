# GitHub Actions Workflow 测试和验证指南

## 📝 改动说明

已成功修改 `.github/workflows/docker-image.yml`，主要改动包括：

### 1. 移除问题组件
- ❌ 删除了 `ignite/cli/actions/release/vars` action（这是导致问题的根源）
- ✅ 使用标准的 Docker 官方 actions 替代

### 2. 新增功能
- ✅ 添加了 `docker/metadata-action@v5` 自动生成镜像标签
- ✅ 添加了 `docker/setup-buildx-action@v3` 支持高级构建功能
- ✅ 添加了 `docker/login-action@v3` 更安全的登录方式
- ✅ 添加了 `docker/build-push-action@v5` 一体化构建和推送
- ✅ 添加了 GitHub Actions 缓存，加速后续构建

### 3. 镜像标签策略

新的 workflow 会根据不同触发条件自动生成标签：

| 触发方式 | 生成的标签示例 | 说明 |
|---------|--------------|------|
| Push 到 main 分支 | `latest`, `main-sha123456` | 自动打上 latest 标签 |
| 创建 Release (v1.2.3) | `v1.2.3`, `1.2`, `1`, `latest` | 支持 semver 版本号 |
| Push 到其他分支 | `dev`, `dev-sha123456` | 使用分支名作为标签 |
| Pull Request | `pr-123` | PR 编号作为标签 |

## 🚀 如何测试

### 方法 1：提交代码触发（推荐）

1. **提交这次修改**：
   ```bash
   cd /Users/test/.cursor/worktrees/ghost-ipfs-bkup/sqd
   git add .github/workflows/docker-image.yml
   git commit -m "fix: 修复 GitHub Packages 推送问题，使用标准 Docker actions"
   git push origin main
   ```

2. **查看 workflow 运行**：
   - 访问：https://github.com/zhajingwen/ghost-ipfs-bkup/actions
   - 找到最新的 "Docker Image CI" workflow 运行记录
   - 点击进入查看详细日志

### 方法 2：手动触发

1. 访问 GitHub Actions 页面：https://github.com/zhajingwen/ghost-ipfs-bkup/actions
2. 点击左侧 "Docker Image CI"
3. 点击右侧 "Run workflow" 按钮
4. 选择分支（main）
5. 点击绿色的 "Run workflow" 按钮

### 方法 3：创建 Release（最正式）

1. 访问：https://github.com/zhajingwen/ghost-ipfs-bkup/releases
2. 点击 "Draft a new release"
3. 填写：
   - Tag version: `v0.0.2`（或其他版本号）
   - Release title: `v0.0.2 - 修复 GitHub Packages 推送`
   - Description: 描述这次修复
4. 点击 "Publish release"

## ✅ 验证成功的标志

### 1. Workflow 运行成功

查看 Actions 页面，确认以下步骤都显示 ✅：
- `Checkout code`
- `Set up Docker Buildx`
- `Generate Docker metadata`
- `Log in to GitHub Container Registry`
- `Build and push Docker image` ⭐ **最关键的一步**
- `Save image information`
- `Upload image information`

### 2. 查看详细日志

点击 "Build and push Docker image" 步骤，应该能看到类似输出：

```
#1 [internal] load build definition from Dockerfile
#2 [internal] load .dockerignore
#3 [internal] load metadata for docker.io/library/ghost:latest
...
#10 pushing ghcr.io/zhajingwen/ghost-ipfs-bkup:latest
#10 pushing layer sha256:abc123...
...
#10 DONE
```

### 3. GitHub Packages 页面显示镜像

1. 访问你的仓库首页：https://github.com/zhajingwen/ghost-ipfs-bkup
2. 点击右侧的 "Packages" 链接
3. 应该能看到 `ghost-ipfs-bkup` 包
4. 点击进入，应该能看到：
   - 镜像的各个版本/标签
   - 镜像大小
   - 推送时间
   - Pull 命令

### 4. 本地拉取测试

在你的本地机器上测试拉取镜像：

```bash
# 先登录到 GHCR（需要 Personal Access Token）
echo "YOUR_GITHUB_TOKEN" | docker login ghcr.io -u zhajingwen --password-stdin

# 拉取镜像
docker pull ghcr.io/zhajingwen/ghost-ipfs-bkup:latest

# 查看镜像信息
docker images | grep ghost-ipfs-bkup

# 运行测试
docker run --rm ghcr.io/zhajingwen/ghost-ipfs-bkup:latest --version
```

## 🔍 排查问题

### 如果 workflow 失败

#### 1. 检查 "Generate Docker metadata" 步骤

如果这步失败，检查：
- 确认仓库名称正确：`zhajingwen/ghost-ipfs-bkup`
- 检查 GitHub 变量是否正确：`${{ github.repository }}`

#### 2. 检查 "Log in to GitHub Container Registry" 步骤

如果登录失败，检查：

```bash
# 确认 GHCR_PAT secret 存在且有效
# 访问：https://github.com/zhajingwen/ghost-ipfs-bkup/settings/secrets/actions

# 确认 token 权限包含：
# ✅ write:packages
# ✅ read:packages
# ✅ delete:packages（可选）
```

可能的错误信息：
- `Error: Invalid username or password` → GHCR_PAT secret 不正确
- `denied: permission_denied` → token 缺少 write:packages 权限
- `unauthorized: authentication required` → token 已过期或被撤销

**解决方法**：
1. 访问：https://github.com/settings/tokens
2. 找到你之前创建的 token，检查权限
3. 如果有问题，创建新的 token：
   - 点击 "Generate new token (classic)"
   - 勾选 `write:packages`
   - 复制 token
4. 更新仓库 secret：
   - 访问：https://github.com/zhajingwen/ghost-ipfs-bkup/settings/secrets/actions
   - 编辑 `GHCR_PAT`，粘贴新 token

#### 3. 检查 "Build and push Docker image" 步骤

如果构建失败，检查：
- `Dockerfile` 语法是否正确
- 基础镜像 `ghost:latest` 是否可以拉取
- 网络连接是否正常

可能的错误信息：
- `ERROR: failed to solve: process "/bin/sh -c ..." did not complete successfully` → Dockerfile 中的命令执行失败
- `ERROR: failed to push` → 推送到 GHCR 失败（检查登录和权限）

### 如果 Packages 页面仍然为空

1. **等待几分钟**：有时候 GitHub UI 更新需要时间
2. **刷新页面**：强制刷新（Cmd+Shift+R 或 Ctrl+Shift+R）
3. **检查权限**：确认 workflow 有 `packages: write` 权限（已在新配置中添加）
4. **查看 workflow 日志**：确认 push 步骤确实执行成功
5. **检查仓库设置**：
   - 访问：https://github.com/zhajingwen/ghost-ipfs-bkup/settings
   - 查看 "Actions" → "General" → "Workflow permissions"
   - 确保选择了 "Read and write permissions"

## 📊 验证清单

完成以下检查项：

- [ ] Workflow 文件已更新并推送到仓库
- [ ] GitHub Actions 运行成功（所有步骤显示 ✅）
- [ ] "Build and push Docker image" 步骤日志显示 push 成功
- [ ] GitHub Packages 页面显示 `ghost-ipfs-bkup` 包
- [ ] 可以看到镜像标签（如 `latest`）
- [ ] 本地可以成功拉取镜像
- [ ] README.md 中的拉取命令有效

## 🎉 成功后的下一步

### 1. 更新 README.md

确认 README 中的镜像地址正确：

```bash
ghcr.io/zhajingwen/ghost-ipfs-bkup:latest
```

### 2. 测试镜像功能

运行镜像，确保备份和恢复功能正常：

```bash
docker run -d \
  --name ghost-test \
  -p 2368:2368 \
  -e url=http://localhost:2368 \
  -e FILEBASE_BUCKET=your-bucket \
  -e FILEBASE_ACCESS_KEY_ID=your-key \
  -e FILEBASE_SECRET_ACCESS_KEY=your-secret \
  -e BACKUP_ENCRYPTION_PASSWORD=your-password \
  ghcr.io/zhajingwen/ghost-ipfs-bkup:latest

# 查看日志
docker logs -f ghost-test

# 访问 Ghost
open http://localhost:2368
```

### 3. 设置仓库 Packages 可见性

默认情况下，Packages 继承仓库的可见性。如果需要公开访问：

1. 访问 Package 页面
2. 点击 "Package settings"
3. 滚动到 "Danger Zone"
4. 点击 "Change visibility" → "Public"

### 4. 添加 Badge 到 README（可选）

在 README.md 中添加 workflow 状态徽章：

```markdown
[![Docker Image CI](https://github.com/zhajingwen/ghost-ipfs-bkup/actions/workflows/docker-image.yml/badge.svg)](https://github.com/zhajingwen/ghost-ipfs-bkup/actions/workflows/docker-image.yml)
```

## 📚 其他资源

- [GitHub Packages 文档](https://docs.github.com/en/packages)
- [Docker Metadata Action](https://github.com/docker/metadata-action)
- [Docker Build Push Action](https://github.com/docker/build-push-action)
- [GitHub Actions 工作流语法](https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions)

## ❓ 常见问题

### Q: 为什么要使用 Docker 官方 actions 而不是直接运行命令？

A: Docker 官方 actions 提供了更好的：
- 错误处理
- 日志输出
- 缓存支持
- 多平台构建
- 标签管理

### Q: 新的 workflow 会生成多个标签吗？

A: 是的。例如推送到 main 分支会生成：
- `latest`（最新版本）
- `main-sha123456`（带 commit SHA 的分支标签）

创建 release v1.2.3 会生成：
- `v1.2.3`（完整版本）
- `1.2`（minor 版本）
- `1`（major 版本）
- `latest`（最新稳定版）

### Q: 缓存是如何工作的？

A: workflow 使用 GitHub Actions 缓存（`cache-from: type=gha`）来保存构建层，这样：
- 首次构建：需要下载所有层，时间较长
- 后续构建：只需要构建修改的层，速度快很多

### Q: 如果我不想要某些标签怎么办？

A: 编辑 `.github/workflows/docker-image.yml` 中的 `docker/metadata-action` 配置，删除不需要的标签类型。

---

**祝你好运！如果遇到任何问题，请查看 workflow 日志或联系 GitHub Support。** 🚀

