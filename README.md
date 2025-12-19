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
- ✅ 备份文件锁机制，防止并发执行
- ✅ 完善的错误处理和验证机制
- ✅ 智能恢复：自动检测备份数据是否存在
- ✅ 支持 Akash 网络部署

## 🏗️ 技术架构

### 基础镜像
- **Ghost**: `latest`
- **数据库**: SQLite3 (`content/data/ghost.db`)

### 默认环境变量
- `FILEBASE_ENDPOINT`: 默认为 `https://s3.filebase.com`
- `database__client`: 设置为 `sqlite3`
- `database__connection__filename`: 设置为 `content/data/ghost.db`

### 核心组件
- `aws-cli`: S3 存储操作
- `gnupg`: 数据库加密/解密
- `cron`: 定时备份任务

### 主要脚本
- **run.sh**: 容器启动脚本，初始化 Ghost、执行恢复、设置定时任务（每 15 分钟）
- **backup.sh**: 备份脚本，包含文件锁机制和错误处理，加密并上传数据库和图片到 S3
- **restore.sh**: 恢复脚本，自动检测备份数据是否存在，从 S3 下载并解密数据

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

#### 邮件配置环境变量

Ghost 支持通过环境变量配置邮件服务。**注意**：Ghost 使用双下划线（`__`）作为环境变量分隔符来表示嵌套配置。

| 变量名 | 说明 | 示例 |
|--------|------|------|
| `mail__transport` | 邮件传输方式 | `SMTP`（推荐）或 `Direct` |
| `mail__options__host` | SMTP 服务器地址 | `smtp.gmail.com` |
| `mail__options__port` | SMTP 端口 | `587`（TLS）或 `465`（SSL） |
| `mail__options__auth__user` | SMTP 认证用户名 | `your-email@gmail.com` |
| `mail__options__auth__pass` | SMTP 认证密码 | `your-app-password` |
| `mail__from` | 发件人邮箱地址 | `noreply@yourdomain.com` |

**常见邮件服务商配置示例：**

| 服务商 | `mail__options__host` | `mail__options__port` | `mail__options__auth__user` | `mail__options__auth__pass` | 说明 |
|--------|----------------------|---------------------|---------------------------|---------------------------|------|
| **Resend**（推荐） | `smtp.resend.com` | `587` | `resend` | Resend API Key | 现代化邮件服务，配置简单，免费额度充足 |
| Gmail | `smtp.gmail.com` | `587` | 你的 Gmail 地址 | 应用专用密码 | 需要使用应用专用密码 |
| SendGrid | `smtp.sendgrid.net` | `587` | `apikey` | SendGrid API Key | 使用 API Key 作为密码 |
| Mailgun | `smtp.mailgun.org` | `587` | SMTP 用户名 | SMTP 密码 | 使用 SMTP 凭证 |
| QQ邮箱 | `smtp.qq.com` | `587` | QQ 邮箱地址 | 授权码 | 需要开启 SMTP 服务 |
| 163邮箱 | `smtp.163.com` | `465` | 163 邮箱地址 | 授权码 | 使用授权码作为密码 |

**Resend 配置步骤：**

1. 访问 [Resend 官网](https://resend.com/) 注册账号
2. 在 Resend 控制台创建 API Key
3. 使用以下配置：
   - `mail__transport=SMTP`
   - `mail__options__host=smtp.resend.com`
   - `mail__options__port=587`
   - `mail__options__secure=false`
   - `mail__options__requireTLS=true`
   - `mail__options__auth__user=resend`
   - `mail__options__auth__pass=你的 Resend API Key`
   - `mail__from=noreply@resend.dev`（使用 Resend 提供的测试域名，无需验证）

> **重要提示**：如果不配置邮件服务，Ghost 仍可正常运行，但无法发送欢迎邮件、密码重置邮件等。建议在生产环境中配置邮件服务。

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
  ghcr.io/zhajingwen/ghost-ipfs-bkup:latest

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
  ghcr.io/zhajingwen/ghost-ipfs-bkup:latest

# 完整配置示例（包含 Resend 邮件服务）
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
  -e mail__transport=SMTP \
  -e mail__options__host=smtp.resend.com \
  -e mail__options__port=587 \
  -e mail__options__secure=false \
  -e mail__options__requireTLS=true \
  -e mail__options__auth__user=resend \
  -e mail__options__auth__pass=re_xxxxxxxxxxxxx \
  -e mail__from=noreply@resend.dev \
  ghcr.io/zhajingwen/ghost-ipfs-bkup:latest
```

### Docker Compose 示例

```yaml
version: '3.8'

services:
  ghost:
    image: ghcr.io/zhajingwen/ghost-ipfs-bkup:latest
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
      # 可选：邮件服务配置（解决邮件发送失败问题）
      # Resend 配置示例（推荐）
      - mail__transport=SMTP
      - mail__options__host=smtp.resend.com
      - mail__options__port=587
      - mail__options__secure=false
      - mail__options__requireTLS=true
      - mail__options__auth__user=resend
      - mail__options__auth__pass=re_xxxxxxxxxxxxx
      - mail__from=noreply@resend.dev
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

项目配置了 GitHub Actions 工作流，支持自动构建并推送到 GitHub Container Registry (GHCR)：

**触发条件：**
- 推送到 `main` 分支时：自动构建并推送镜像
- 创建 Release 时：自动构建并推送版本标签镜像（支持 semver 格式）
- 手动触发：在 Actions 页面可以手动触发构建

**镜像标签策略：**
- `latest`：默认分支（main）的最新构建
- `main`：main 分支标签
- `<branch>-<sha>`：分支名和 commit SHA（如 `main-abc1234`）
- `<version>`：Release 版本标签（如 `v0.0.1`）
- `<major>.<minor>`：主版本和次版本（如 `v0.0`）
- `<major>`：主版本（如 `v0`）

**镜像地址格式：**
- `ghcr.io/<用户名>/ghost-ipfs-bkup:<tag>`（如 `ghcr.io/zhajingwen/ghost-ipfs-bkup:latest`）

**必需配置：**

1. **配置 GitHub Secret**：
   - 访问仓库 Settings → Secrets and variables → Actions
   - 点击 "New repository secret"
   - 名称：`GHCR_PAT`
   - 值：GitHub Personal Access Token（需要 `write:packages` 权限）

2. **创建 Personal Access Token**：
   - 访问 GitHub Settings → Developer settings → Personal access tokens → Tokens (classic)
   - 点击 "Generate new token (classic)"
   - 勾选 `write:packages` 权限
   - 生成并复制 token，然后添加到仓库 Secrets 中

**功能特性：**
- ✅ 使用 Docker Buildx 进行构建
- ✅ 启用构建缓存加速后续构建
- ✅ 自动检测 secret 配置，失败时提供清晰错误提示
- ✅ 支持多触发条件（Release、Push、手动触发）

## 🔄 备份和恢复机制

### 备份流程

备份脚本包含文件锁机制，防止多个备份任务并发执行。

1. **图片备份**：将 `content/images` 目录下的所有文件上传到 Filebase/S3
   - 如果设置了 `FILEBASE_BACKUP_PATH`，备份到：`s3://bucket/${FILEBASE_BACKUP_PATH}/images`
   - 如果未设置，备份到：`s3://bucket/images`
   - 备份失败时会输出错误信息并退出

2. **数据库备份**：
   - 清理旧的加密文件（如果存在）
   - 使用 GPG 对称加密 `ghost.db` 文件
   - 验证加密文件是否成功创建
   - 上传加密后的 `.gpg` 文件到 Filebase/S3
     - 如果设置了 `FILEBASE_BACKUP_PATH`，备份到：`s3://bucket/${FILEBASE_BACKUP_PATH}/data`
     - 如果未设置，备份到：`s3://bucket/data`
   - 上传失败时会清理临时文件并退出
   - 删除本地临时加密文件
   - 释放文件锁

### 恢复流程

容器启动时自动执行：

1. **初始化 Ghost 内容目录**
2. **检查备份数据是否存在**：
   - 检查 S3 存储中是否存在加密的数据库文件（`.gpg` 文件）
   - 如果不存在备份数据，跳过恢复并输出警告信息
3. **从 Filebase/S3 恢复数据**（仅在找到备份数据时执行）：
   - 根据 `FILEBASE_BACKUP_PATH` 配置从对应路径下载数据
   - 下载加密的数据库文件
   - 验证加密文件是否成功下载
   - 使用 GPG 解密数据库
   - 验证解密后的数据库文件是否成功创建
   - 删除临时加密文件
   - 恢复图片文件（图片恢复失败不会阻止数据库恢复）
4. **设置定时备份任务**（每 15 分钟）
5. **启动 Ghost 服务**

> **注意**：恢复时使用的 `FILEBASE_BACKUP_PATH` 必须与备份时设置的路径一致，否则无法找到备份文件。如果 S3 中不存在备份数据，容器仍会正常启动，但不会执行恢复操作。

### 备份时间表

- **频率**：每 15 分钟自动备份一次
- **日志**：备份日志输出到容器标准输出（stdout），可通过 `docker logs` 命令查看
- **并发保护**：使用文件锁机制防止多个备份任务同时执行

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

1. **错误处理**：脚本已包含基本的错误处理和验证机制，但建议在生产环境中添加重试逻辑和更完善的错误恢复机制
2. **数据覆盖风险**：容器每次启动都会执行恢复操作，如果 S3 中存在备份数据，会覆盖本地数据
3. **数据库锁定**：备份脚本使用文件锁防止并发执行，但如果数据库正在写入时备份，可能获取到不一致的数据快照
4. **日志管理**：备份日志输出到容器标准输出，建议使用 Docker 日志驱动或日志收集工具进行管理

### 最佳实践

1. **定期验证备份**：定期检查 S3 存储中的备份文件完整性
2. **监控备份任务**：使用 `docker logs <container-name>` 监控备份日志，确保备份成功
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
4. 查看日志：`docker logs <container-name>` 或 `docker logs -f <container-name>` 实时查看
5. 如果看到 "Backup already in progress, skipping..." 消息，说明有备份任务正在运行，这是正常现象
6. 检查备份脚本的错误信息，常见错误包括：
   - GPG 加密失败：检查 `BACKUP_ENCRYPTION_PASSWORD` 是否正确
   - S3 上传失败：检查网络连接和 S3 凭证
   - 文件权限问题：确保 Ghost 内容目录有写入权限

### 恢复失败

1. 确认 Filebase/S3 中存在备份文件（`.gpg` 格式的加密数据库文件）
2. 验证 `BACKUP_ENCRYPTION_PASSWORD` 是否正确
3. 检查 `FILEBASE_BACKUP_PATH` 是否与备份时设置的路径一致
4. 检查容器文件系统权限
5. 查看容器启动日志：`docker logs <container-name>`
6. 如果看到 "No backup data found" 警告，说明 S3 中不存在备份数据，容器会正常启动但不会执行恢复
7. 如果恢复失败，检查日志中的具体错误信息：
   - GPG 解密失败：密码错误或加密文件损坏
   - 下载失败：网络问题或 S3 凭证错误
   - 文件验证失败：下载的文件不完整

### 数据库损坏

1. 从 S3 下载最新的备份文件
2. 手动解密数据库文件
3. 替换容器中的数据库文件
4. 重启容器

### 邮件发送失败

如果日志中出现 `Failed to send email` 或 `Missing mail.from config` 错误，说明邮件服务未正确配置。

**检查步骤：**

1. **验证环境变量是否正确设置**
   ```bash
   docker exec ghost-blog env | grep mail
   ```
   应该能看到所有 `mail__` 开头的环境变量。

2. **检查邮件配置格式**
   - 确保使用双下划线（`__`）作为分隔符，而不是单下划线
   - 正确格式：`mail__transport`、`mail__options__host`
   - 错误格式：`mail_transport`、`mail.options.host`

3. **验证 SMTP 凭证**
   - **Resend**：使用 `resend` 作为用户名，API Key 作为密码。`mail__from` 固定使用 `noreply@resend.dev`，无需验证域名
   - Gmail：需要使用[应用专用密码](https://support.google.com/accounts/answer/185833)，不能使用普通密码
   - SendGrid：使用 `apikey` 作为用户名，API Key 作为密码
   - 其他服务商：确认用户名和密码/授权码正确

4. **测试邮件配置**
   - 登录 Ghost 管理后台
   - 进入 Settings → Email
   - 点击 "Send a test email" 测试邮件发送

5. **查看详细错误日志**
   ```bash
   docker logs ghost-blog | grep -i mail
   ```

**常见问题：**

- **Resend 配置提示**：
  - 用户名必须设置为 `resend`（固定值）
  - 密码使用你的 Resend API Key（格式：`re_xxxxxxxxxxxxx`）
  - `mail__from` 固定使用 `noreply@resend.dev`（Resend 提供的测试域名，无需验证）
- **Gmail 连接失败**：确保已启用"允许不够安全的应用访问"，或使用应用专用密码
- **端口被阻止**：某些网络环境可能阻止 587 端口，尝试使用 465 端口（SSL）
- **认证失败**：检查用户名和密码是否正确，某些服务商需要使用完整的邮箱地址作为用户名

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

## 📄 许可证

本项目基于 Ghost 官方镜像构建，请遵循相应的许可证要求。

## 🔗 相关链接

- [Ghost 官方文档](https://ghost.org/docs/)
- [Filebase 文档](https://docs.filebase.com/)
- [AWS CLI 文档](https://docs.aws.amazon.com/cli/)
- [Akash 网络文档](https://docs.akash.network/)

**注意**：本项目仍在开发中，建议在生产环境使用前进行充分测试。
