# ghost-ipfs-bkup

基于 Ghost latest 的 Docker 镜像，提供自动备份和恢复功能，使用 S3 兼容存储（如 Filebase）进行数据持久化。

## 📋 项目简介

`ghost-ipfs-bkup` 是一个增强版的 Ghost 博客 Docker 镜像，在官方 Ghost 镜像基础上添加了：

- 🔄 **自动备份**：每 15 分钟自动备份数据库和图片到 S3 兼容存储
- 🔐 **数据加密**：使用 GPG 对称加密保护数据库文件
- 📦 **自动恢复**：容器启动时自动从 S3 恢复数据
- ☁️ **IPFS 兼容**：支持 Filebase 等 IPFS 网关的 S3 兼容存储

## ✨ 功能特性

- ✅ 基于 Ghost latest 官方镜像
- ✅ SQLite3 数据库支持
- ✅ 自动定时备份（每 15 分钟）
- ✅ GPG 加密数据库备份
- ✅ S3 兼容存储支持（Filebase、AWS S3 等）
- ✅ 容器启动时自动数据恢复
- ✅ 支持 Akash 网络部署

## 🏗️ 技术架构

### 基础镜像
- **Ghost**: `latest`
- **数据库**: SQLite3 (`content/data/ghost.db`)

### 核心组件
- `aws-cli`: S3 存储操作
- `gnupg`: 数据库加密/解密
- `cron`: 定时备份任务

### 主要脚本
- **run.sh**: 容器启动脚本，初始化 Ghost、执行恢复、设置定时任务
- **backup.sh**: 备份脚本，加密并上传数据库和图片
- **restore.sh**: 恢复脚本，从 S3 下载并解密数据

## 🚀 快速开始

### 前置要求

- Docker 或支持容器的运行环境
- S3 兼容存储服务（如 Filebase、AWS S3）
- S3 访问凭证（Access Key ID 和 Secret Access Key）

### 环境变量配置

#### 必需环境变量

| 变量名 | 说明 | 示例 |
|--------|------|------|
| `FILEBASE_BUCKET` | Filebase 存储桶名称 | `my-bucket-name` |
| `FILEBASE_ACCESS_KEY_ID` | Filebase 访问密钥 ID | `your-filebase-access-key-id` |
| `FILEBASE_SECRET_ACCESS_KEY` | Filebase 密钥 | `your-filebase-secret-access-key` |
| `BACKUP_ENCRYPTION_PASSWORD` | 数据库加密密码 | `your-secure-password` |
| `url` | Ghost 博客完整 URL | `https://example.com` |

#### 可选环境变量

| 变量名 | 说明 | 默认值 |
|--------|------|--------|
| `FILEBASE_ENDPOINT` | Filebase S3 端点地址 | `https://s3.filebase.com` |
| `FILEBASE_BACKUP_PATH` | 备份目录路径前缀 | 空（备份到存储桶根目录） |
| `NODE_ENV` | Node.js 运行环境 | `production` |

##### FILEBASE_BACKUP_PATH 使用说明

`FILEBASE_BACKUP_PATH` 允许您指定备份在存储桶中的目录路径，这对于以下场景非常有用：

- **多实例隔离**：多个 Ghost 实例可以共享同一个存储桶，但使用不同的备份目录
- **项目组织**：按项目或环境组织备份文件
- **版本管理**：为不同版本的备份创建独立目录

**示例：**

| FILEBASE_BACKUP_PATH 值 | 备份位置 |
|------------------------|---------|
| （未设置） | `s3://bucket/images` 和 `s3://bucket/data` |
| `my-backup` | `s3://bucket/my-backup/images` 和 `s3://bucket/my-backup/data` |
| `project1/backup` | `s3://bucket/project1/backup/images` 和 `s3://bucket/project1/backup/data` |
| `production/ghost` | `s3://bucket/production/ghost/images` 和 `s3://bucket/production/ghost/data` |

> **向后兼容性**：为了保持向后兼容，脚本仍支持旧的变量名（`S3_PATH`、`S3_HOST`、`AWS_ACCESS_KEY_ID`、`AWS_SECRET_ACCESS_KEY`、`KEY_PASSWORD`），但建议使用新的 Filebase 专用变量名。

### Docker 运行示例

```bash
# 基本使用（备份到存储桶根目录）
docker run -d \
  --name ghost-blog \
  -p 2368:2368 \
  -e url=http://localhost:2368 \
  -e NODE_ENV=production \
  -e FILEBASE_BUCKET=my-bucket-name \
  -e FILEBASE_ENDPOINT=https://s3.filebase.com \
  -e FILEBASE_ACCESS_KEY_ID=your-filebase-access-key-id \
  -e FILEBASE_SECRET_ACCESS_KEY=your-filebase-secret-access-key \
  -e BACKUP_ENCRYPTION_PASSWORD=your-encryption-password \
  ghcr.io/dmikey/ghost-ipfs-bkup:v0.0.1

# 使用自定义备份路径（备份到指定目录）
docker run -d \
  --name ghost-blog \
  -p 2368:2368 \
  -e url=http://localhost:2368 \
  -e NODE_ENV=production \
  -e FILEBASE_BUCKET=my-bucket-name \
  -e FILEBASE_ENDPOINT=https://s3.filebase.com \
  -e FILEBASE_ACCESS_KEY_ID=your-filebase-access-key-id \
  -e FILEBASE_SECRET_ACCESS_KEY=your-filebase-secret-access-key \
  -e BACKUP_ENCRYPTION_PASSWORD=your-encryption-password \
  -e FILEBASE_BACKUP_PATH=my-backup \
  ghcr.io/dmikey/ghost-ipfs-bkup:v0.0.1
```

### Docker Compose 示例

```yaml
version: '3.8'

services:
  ghost:
    image: ghcr.io/dmikey/ghost-ipfs-bkup:v0.0.1
    ports:
      - "2368:2368"
    environment:
      - url=http://localhost:2368
      - NODE_ENV=production
      - FILEBASE_BUCKET=my-bucket-name
      - FILEBASE_ENDPOINT=https://s3.filebase.com
      - FILEBASE_ACCESS_KEY_ID=your-filebase-access-key-id
      - FILEBASE_SECRET_ACCESS_KEY=your-filebase-secret-access-key
      - BACKUP_ENCRYPTION_PASSWORD=your-encryption-password
      # 可选：指定备份目录路径
      - FILEBASE_BACKUP_PATH=my-backup
    volumes:
      - ghost-data:/var/lib/ghost/content
```

## 📦 构建镜像

### 本地构建

```bash
git clone https://github.com/dmikey/ghost-ipfs-bkup.git
cd ghost-ipfs-bkup
docker build -t ghost-ipfs-bkup:latest .
```

### GitHub Actions 自动构建

项目配置了 GitHub Actions 工作流，当创建 Release 时会自动构建并推送到 GHCR：

- 镜像地址：`ghcr.io/dmikey/ghost-ipfs-bkup:<tag>`
- 需要配置 GitHub Personal Access Token (PAT) 作为 `GHCR_PAT` secret

## 🔄 备份和恢复机制

### 备份流程

1. **图片备份**：将 `content/images` 目录下的所有文件上传到 Filebase/S3
   - 如果设置了 `FILEBASE_BACKUP_PATH`，备份到：`s3://bucket/${FILEBASE_BACKUP_PATH}/images`
   - 如果未设置，备份到：`s3://bucket/images`

2. **数据库备份**：
   - 使用 GPG 对称加密 `ghost.db` 文件
   - 上传加密后的 `.gpg` 文件到 Filebase/S3
     - 如果设置了 `FILEBASE_BACKUP_PATH`，备份到：`s3://bucket/${FILEBASE_BACKUP_PATH}/data`
     - 如果未设置，备份到：`s3://bucket/data`
   - 删除本地临时加密文件

### 恢复流程

容器启动时自动执行：

1. **初始化 Ghost 内容目录**
2. **从 Filebase/S3 恢复数据**：
   - 根据 `FILEBASE_BACKUP_PATH` 配置从对应路径下载数据
   - 下载加密的数据库文件
   - 使用 GPG 解密数据库
   - 恢复图片文件
3. **设置定时备份任务**（每 15 分钟）
4. **启动 Ghost 服务**

> **注意**：恢复时使用的 `FILEBASE_BACKUP_PATH` 必须与备份时设置的路径一致，否则无法找到备份文件。

### 备份时间表

- **频率**：每 15 分钟自动备份一次
- **日志**：备份日志写入 `/var/log/daily-backup.log`

## 🌐 部署到 Akash 网络

项目包含 `deploy.yaml` 配置文件，支持部署到 Akash 去中心化云网络：

```bash
akash deploy deploy.yaml
```

部署前需要修改 `deploy.yaml` 中的：
- 域名配置（`changeme.com`）
- 环境变量值
- 资源配额

## ⚠️ 注意事项和已知问题

### 安全建议

1. **密码安全**：
   - `BACKUP_ENCRYPTION_PASSWORD` 和 `FILEBASE_SECRET_ACCESS_KEY` 是敏感信息
   - 建议使用密钥管理服务（如 Kubernetes Secrets、Docker Secrets）
   - 不要在代码仓库中硬编码这些值

2. **密码暴露风险**：
   - 当前实现中，GPG 密码会出现在进程列表中
   - 建议在生产环境中使用更安全的密码传递方式

### 已知限制

1. **错误处理**：脚本缺少完善的错误处理机制，建议在生产环境使用前添加错误检查和重试逻辑
2. **数据覆盖风险**：容器每次启动都会执行恢复操作，可能覆盖本地数据
3. **数据库锁定**：备份时如果数据库正在写入，可能导致备份失败
4. **日志管理**：备份日志文件没有轮转机制，长期运行可能占用大量磁盘空间

### 最佳实践

1. **定期验证备份**：定期检查 S3 存储中的备份文件完整性
2. **监控备份任务**：监控 `/var/log/daily-backup.log` 确保备份成功
3. **版本控制**：考虑为备份文件添加时间戳，支持多版本备份
4. **资源监控**：监控容器资源使用情况，确保有足够空间

## 📁 项目结构

```
ghost-ipfs-bkup/
├── Dockerfile              # Docker 镜像构建文件
├── backup.sh              # 备份脚本
├── restore.sh             # 恢复脚本
├── run.sh                 # 启动脚本
├── deploy.yaml            # Akash 部署配置
├── .github/
│   └── workflows/
│       └── docker-image.yml  # GitHub Actions CI/CD
└── README.md              # 项目文档
```

## 🔧 故障排查

### 备份失败

1. 检查环境变量是否正确设置
2. 验证 S3 凭证是否有效
3. 检查网络连接和 S3 端点可访问性
4. 查看日志：`docker logs <container-name>`

### 恢复失败

1. 确认 Filebase/S3 中存在备份文件
2. 验证 `BACKUP_ENCRYPTION_PASSWORD` 是否正确
3. 检查容器文件系统权限
4. 查看容器启动日志

### 数据库损坏

1. 从 S3 下载最新的备份文件
2. 手动解密数据库文件
3. 替换容器中的数据库文件
4. 重启容器

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

## 📄 许可证

本项目基于 Ghost 官方镜像构建，请遵循相应的许可证要求。

## 🔗 相关链接

- [Ghost 官方文档](https://ghost.org/docs/)
- [Filebase 文档](https://docs.filebase.com/)
- [AWS CLI 文档](https://docs.aws.amazon.com/cli/)
- [Akash 网络文档](https://docs.akash.network/)

## 📝 更新日志

### v0.0.1
- 初始版本
- 基于 Ghost latest
- 实现自动备份和恢复功能
- 支持 S3 兼容存储

---

**注意**：本项目仍在开发中，建议在生产环境使用前进行充分测试。
