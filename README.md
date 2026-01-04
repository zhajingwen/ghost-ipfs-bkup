# ghost-ipfs-bkup

[English Version](#english-version) | [中文版本](#中文版本)

---

# English Version

Docker image based on Ghost latest, providing automatic backup and restore functionality with S3-compatible storage (such as Filebase) for data persistence.

## 📋 Overview

`ghost-ipfs-bkup` is an enhanced Ghost blogging Docker image that adds the following features on top of the official Ghost image:

- 🔄 **Automatic Backup**: Automatically backs up database and images to S3-compatible storage every 15 minutes
- 🔐 **Data Encryption**: Uses GPG symmetric encryption to protect database files
- 📦 **Automatic Restore**: Automatically restores data from S3 on container startup
- ☁️ **IPFS Compatible**: Supports S3-compatible storage from Filebase and other IPFS gateways

## ✨ Features

- ✅ Based on Ghost latest official image
- ✅ SQLite3 database support
- ✅ Automatic scheduled backups (every 15 minutes)
- ✅ GPG encrypted database backups
- ✅ S3-compatible storage support (Filebase, AWS S3, etc.)
- ✅ Automatic data restoration on container startup
- ✅ Backup file lock mechanism to prevent concurrent execution
- ✅ Comprehensive error handling and validation
- ✅ Smart restore: Automatically detects if backup data exists
- ✅ Akash network deployment support

## 🏗️ Technical Architecture

### Base Image
- **Ghost**: `latest`
- **Database**: SQLite3 (`content/data/ghost.db`)

### Default Environment Variables
- `FILEBASE_ENDPOINT`: Defaults to `https://s3.filebase.com`
- `database__client`: Set to `sqlite3`
- `database__connection__filename`: Set to `content/data/ghost.db`

### Core Components
- `aws-cli`: S3 storage operations
- `gnupg`: Database encryption/decryption
- `cron`: Scheduled backup tasks

### Main Scripts
- **run.sh**: Container startup script, initializes Ghost, executes restore, sets up scheduled tasks (every 15 minutes)
- **backup.sh**: Backup script with file lock mechanism and error handling, encrypts and uploads database and images to S3
- **restore.sh**: Restore script, automatically detects if backup data exists, downloads and decrypts data from S3

## 🚀 Quick Start

### Prerequisites

- Docker or container-compatible runtime environment
- S3-compatible storage service (such as Filebase, AWS S3)
- S3 access credentials (Access Key ID and Secret Access Key)

### Environment Variable Configuration

#### Required Environment Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `FILEBASE_BUCKET` | Filebase bucket name | `my-bucket-name` |
| `FILEBASE_ACCESS_KEY_ID` | Filebase access key ID | `your-filebase-access-key-id` |
| `FILEBASE_SECRET_ACCESS_KEY` | Filebase secret key | `your-filebase-secret-access-key` |
| `BACKUP_ENCRYPTION_PASSWORD` | Database encryption password | `your-secure-password` |
| `url` | Ghost blog complete URL | `https://example.com` |

#### Optional Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `FILEBASE_ENDPOINT` | Filebase S3 endpoint address | `https://s3.filebase.com` |
| `FILEBASE_BACKUP_PATH` | Backup directory path prefix | Empty (backup to bucket root) |
| `NODE_ENV` | Node.js runtime environment | `production` |

#### Email Configuration Environment Variables

Ghost supports email service configuration through environment variables. **Note**: Ghost uses double underscores (`__`) as environment variable separators to represent nested configuration.

| Variable | Description | Example |
|----------|-------------|---------|
| `mail__transport` | Email transport method | `SMTP` (recommended) or `Direct` |
| `mail__options__host` | SMTP server address | `smtp.gmail.com` |
| `mail__options__port` | SMTP port | `587` (TLS) or `465` (SSL) |
| `mail__options__auth__user` | SMTP authentication username | `your-email@gmail.com` |
| `mail__options__auth__pass` | SMTP authentication password | `your-app-password` |
| `mail__from` | Sender email address | `noreply@yourdomain.com` |

**Common Email Provider Configuration Examples:**

| Provider | `mail__options__host` | `mail__options__port` | `mail__options__auth__user` | `mail__options__auth__pass` | Notes |
|----------|----------------------|---------------------|---------------------------|---------------------------|-------|
| **Resend** (Recommended) | `smtp.resend.com` | `587` | `resend` | Resend API Key | Modern email service, simple configuration, generous free tier |
| Gmail | `smtp.gmail.com` | `587` | Your Gmail address | App-specific password | Requires app-specific password |
| SendGrid | `smtp.sendgrid.net` | `587` | `apikey` | SendGrid API Key | Use API Key as password |
| Mailgun | `smtp.mailgun.org` | `587` | SMTP username | SMTP password | Use SMTP credentials |
| QQ Mail | `smtp.qq.com` | `587` | QQ email address | Authorization code | Need to enable SMTP service |
| 163 Mail | `smtp.163.com` | `465` | 163 email address | Authorization code | Use authorization code as password |

**Resend Configuration Steps:**

1. Visit [Resend](https://resend.com/) to register an account
2. Create an API Key in the Resend console
3. Use the following configuration:
   - `mail__transport=SMTP`
   - `mail__options__host=smtp.resend.com`
   - `mail__options__port=587`
   - `mail__options__secure=false`
   - `mail__options__requireTLS=true`
   - `mail__options__auth__user=resend`
   - `mail__options__auth__pass=your-resend-api-key`
   - `mail__from=noreply@resend.dev` (Resend test domain, no verification needed)

> **Important Note**: Ghost can still run normally without email service configuration, but cannot send welcome emails, password reset emails, etc. Email service configuration is recommended for production environments.

##### FILEBASE_BACKUP_PATH Usage Notes

`FILEBASE_BACKUP_PATH` allows you to specify the directory path for backups in the bucket, which is useful for:

- **Multi-instance isolation**: Multiple Ghost instances can share the same bucket but use different backup directories
- **Project organization**: Organize backup files by project or environment
- **Version management**: Create separate directories for different backup versions

**Examples:**

| FILEBASE_BACKUP_PATH Value | Backup Location |
|---------------------------|----------------|
| (Not set) | `s3://bucket/images` and `s3://bucket/data` |
| `my-backup` | `s3://bucket/my-backup/images` and `s3://bucket/my-backup/data` |
| `project1/backup` | `s3://bucket/project1/backup/images` and `s3://bucket/project1/backup/data` |
| `production/ghost` | `s3://bucket/production/ghost/images` and `s3://bucket/production/ghost/data` |

> **Backward Compatibility**: For backward compatibility, the scripts still support old variable names (`S3_PATH`, `S3_HOST`, `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `KEY_PASSWORD`), but using the new Filebase-specific variable names is recommended.

### Docker Run Example

```bash
# Basic usage (backup to bucket root)
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

# Using custom backup path (backup to specified directory)
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

# Complete configuration example (including Resend email service)
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

### Docker Compose Example

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
      # Optional: Specify backup directory path
      - FILEBASE_BACKUP_PATH=my-backup
      # Optional: Email service configuration (resolves email sending failures)
      # Resend configuration example (recommended)
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

## 📦 Building the Image

### Local Build

```bash
git clone https://github.com/dmikey/ghost-ipfs-bkup.git
cd ghost-ipfs-bkup
docker build -t ghost-ipfs-bkup:latest .
```

#### Build Warnings

When building the image, you may see the following warnings:

```
WARN: SecretsUsedInArgOrEnv: Do not use ARG or ENV instructions for sensitive data (ENV "FILEBASE_ACCESS_KEY_ID")
WARN: SecretsUsedInArgOrEnv: Do not use ARG or ENV instructions for sensitive data (ENV "FILEBASE_SECRET_ACCESS_KEY")
WARN: SecretsUsedInArgOrEnv: Do not use ARG or ENV instructions for sensitive data (ENV "BACKUP_ENCRYPTION_PASSWORD")
```

**These warnings are safe to ignore.** Here's why:

- ✅ **Pattern-based detection**: Docker BuildKit triggers these warnings based on variable names containing keywords like `KEY`, `SECRET`, or `PASSWORD`
- ✅ **No actual secrets**: The Dockerfile only declares empty environment variables, not actual secret values
- ✅ **Runtime injection**: Real credentials are passed at runtime via `docker run -e` and are never written to the image layers
- ✅ **Best practice**: This approach follows Docker security best practices by separating configuration from the image

The warnings are a precautionary measure by Docker to prevent hardcoded secrets in Dockerfiles. Since we're only declaring variable names (with empty values) and injecting actual secrets at runtime, there's no security risk.

### GitHub Actions Automatic Build

The project is configured with GitHub Actions workflow supporting automatic builds and pushes to GitHub Container Registry (GHCR):

**Trigger Conditions:**
- Push to `main` branch: Automatically builds and pushes image
- Create Release: Automatically builds and pushes version tag image (supports semver format)
- Manual trigger: Can manually trigger build from Actions page

**Image Tag Strategy:**
- `latest`: Latest build of default branch (main)
- `main`: Main branch tag
- `<branch>-<sha>`: Branch name and commit SHA (e.g., `main-abc1234`)
- `<version>`: Release version tag (e.g., `v0.0.1`)
- `<major>.<minor>`: Major and minor version (e.g., `v0.0`)
- `<major>`: Major version (e.g., `v0`)

**Image Address Format:**
- `ghcr.io/<username>/ghost-ipfs-bkup:<tag>` (e.g., `ghcr.io/zhajingwen/ghost-ipfs-bkup:latest`)

**Required Configuration:**

1. **Configure GitHub Secret**:
   - Visit repository Settings → Secrets and variables → Actions
   - Click "New repository secret"
   - Name: `GHCR_PAT`
   - Value: GitHub Personal Access Token (requires `write:packages` permission)

2. **Create Personal Access Token**:
   - Visit GitHub Settings → Developer settings → Personal access tokens → Tokens (classic)
   - Click "Generate new token (classic)"
   - Check `write:packages` permission
   - Generate and copy token, then add to repository Secrets

**Features:**
- ✅ Uses Docker Buildx for building
- ✅ Build cache enabled to speed up subsequent builds
- ✅ Automatic secret configuration detection with clear error messages on failure
- ✅ Supports multiple trigger conditions (Release, Push, manual trigger)

## 🔄 Backup and Restore Mechanism

### Backup Process

The backup script includes a file lock mechanism to prevent concurrent backup task execution.

1. **Image Backup**: Uploads all files in the `content/images` directory to Filebase/S3
   - If `FILEBASE_BACKUP_PATH` is set, backs up to: `s3://bucket/${FILEBASE_BACKUP_PATH}/images`
   - If not set, backs up to: `s3://bucket/images`
   - Outputs error message and exits on backup failure

2. **Database Backup**:
   - Cleans up old encrypted files (if any)
   - Uses GPG symmetric encryption on `ghost.db` file
   - Verifies encrypted file was created successfully
   - Uploads encrypted `.gpg` file to Filebase/S3
     - If `FILEBASE_BACKUP_PATH` is set, backs up to: `s3://bucket/${FILEBASE_BACKUP_PATH}/data`
     - If not set, backs up to: `s3://bucket/data`
   - Cleans up temporary files and exits on upload failure
   - Deletes local temporary encrypted file
   - Releases file lock

### Restore Process

Automatically executed on container startup:

1. **Initialize Ghost content directory**
2. **Check if backup data exists**:
   - Checks if encrypted database file (`.gpg` file) exists in S3 storage
   - If backup data doesn't exist, skips restore and outputs warning message
3. **Restore data from Filebase/S3** (only executed if backup data found):
   - Downloads data from corresponding path based on `FILEBASE_BACKUP_PATH` configuration
   - Downloads encrypted database file
   - Verifies encrypted file was downloaded successfully
   - Uses GPG to decrypt database
   - Verifies decrypted database file was created successfully
   - Deletes temporary encrypted file
   - Restores image files (image restore failure won't block database restore)
4. **Set scheduled backup task** (every 15 minutes)
5. **Start Ghost service**

> **Note**: The `FILEBASE_BACKUP_PATH` used during restore must match the path set during backup, otherwise backup files cannot be found. If backup data doesn't exist in S3, the container will still start normally but won't execute restore operations.

### Backup Schedule

- **Frequency**: Automatically backs up every 15 minutes
- **Logs**: Backup logs output to container standard output (stdout), viewable via `docker logs` command
- **Concurrency Protection**: Uses file lock mechanism to prevent multiple backup tasks from running simultaneously

## 🌐 Deploying to Akash Network

The project includes a `deploy.yaml` configuration file supporting deployment to the Akash decentralized cloud network:

```bash
akash deploy deploy.yaml
```

Before deployment, modify the following in `deploy.yaml`:
- Domain configuration (`changeme.com`)
- Environment variable values
- Resource quotas

## ⚠️ Notes and Known Issues

### Security Recommendations

1. **Password Security**:
   - `BACKUP_ENCRYPTION_PASSWORD` and `FILEBASE_SECRET_ACCESS_KEY` are sensitive information
   - Recommend using key management services (such as Kubernetes Secrets, Docker Secrets)
   - Do not hardcode these values in code repositories

2. **Password Exposure Risk**:
   - In the current implementation, GPG password appears in process list
   - Recommend using more secure password passing methods in production environments

### Known Limitations

1. **Error Handling**: Scripts include basic error handling and validation mechanisms, but recommend adding retry logic and more comprehensive error recovery mechanisms in production environments
2. **Data Overwrite Risk**: Container executes restore operation on every startup; if backup data exists in S3, it will overwrite local data
3. **Database Locking**: Backup script uses file lock to prevent concurrent execution, but backing up while database is being written to may capture an inconsistent data snapshot
4. **Log Management**: Backup logs output to container standard output; recommend using Docker log driver or log collection tools for management

### Best Practices

1. **Regularly Verify Backups**: Periodically check integrity of backup files in S3 storage
2. **Monitor Backup Tasks**: Use `docker logs <container-name>` to monitor backup logs and ensure backups succeed
3. **Version Control**: Consider adding timestamps to backup files to support multi-version backups
4. **Resource Monitoring**: Monitor container resource usage to ensure sufficient space

## 📁 Project Structure

```
ghost-ipfs-bkup/
├── Dockerfile              # Docker image build file
├── backup.sh              # Backup script
├── restore.sh             # Restore script
├── run.sh                 # Startup script
├── deploy.yaml            # Akash deployment configuration
├── .github/
│   └── workflows/
│       └── docker-image.yml  # GitHub Actions CI/CD
└── README.md              # Project documentation
```

## 🔧 Troubleshooting

### Backup Failure

1. Check if environment variables are correctly set
2. Verify S3 credentials are valid
3. Check network connectivity and S3 endpoint accessibility
4. View logs: `docker logs <container-name>` or `docker logs -f <container-name>` for real-time viewing
5. If you see "Backup already in progress, skipping..." message, it indicates a backup task is running, which is normal
6. Check backup script error messages; common errors include:
   - GPG encryption failure: Check if `BACKUP_ENCRYPTION_PASSWORD` is correct
   - S3 upload failure: Check network connection and S3 credentials
   - File permission issues: Ensure Ghost content directory has write permissions

### Restore Failure

1. Confirm backup files exist in Filebase/S3 (encrypted database file in `.gpg` format)
2. Verify `BACKUP_ENCRYPTION_PASSWORD` is correct
3. Check if `FILEBASE_BACKUP_PATH` matches the path set during backup
4. Check container filesystem permissions
5. View container startup logs: `docker logs <container-name>`
6. If you see "No backup data found" warning, it indicates backup data doesn't exist in S3; container will start normally but won't execute restore
7. If restore fails, check specific error messages in logs:
   - GPG decryption failure: Incorrect password or corrupted encrypted file
   - Download failure: Network issues or incorrect S3 credentials
   - File verification failure: Downloaded file is incomplete

### Database Corruption

1. Download latest backup file from S3
2. Manually decrypt database file
3. Replace database file in container
4. Restart container

### Email Sending Failure

If you see `Failed to send email` or `Missing mail.from config` errors in logs, it indicates email service is not correctly configured.

**Check Steps:**

1. **Verify environment variables are correctly set**
   ```bash
   docker exec ghost-blog env | grep mail
   ```
   You should see all environment variables starting with `mail__`.

2. **Check email configuration format**
   - Ensure using double underscores (`__`) as separators, not single underscores
   - Correct format: `mail__transport`, `mail__options__host`
   - Incorrect format: `mail_transport`, `mail.options.host`

3. **Verify SMTP credentials**
   - **Resend**: Use `resend` as username, API Key as password. `mail__from` fixed as `noreply@resend.dev`, no domain verification needed
   - Gmail: Need to use [app-specific password](https://support.google.com/accounts/answer/185833), cannot use regular password
   - SendGrid: Use `apikey` as username, API Key as password
   - Other providers: Confirm username and password/authorization code are correct

4. **Test email configuration**
   - Log in to Ghost admin panel
   - Go to Settings → Email
   - Click "Send a test email" to test email sending

5. **View detailed error logs**
   ```bash
   docker logs ghost-blog | grep -i mail
   ```

**Common Issues:**

- **Resend configuration tips**:
  - Username must be set to `resend` (fixed value)
  - Password uses your Resend API Key (format: `re_xxxxxxxxxxxxx`)
  - `mail__from` fixed as `noreply@resend.dev` (Resend test domain, no verification needed)
- **Gmail connection failure**: Ensure "Allow less secure app access" is enabled, or use app-specific password
- **Port blocked**: Some network environments may block port 587, try using port 465 (SSL)
- **Authentication failure**: Check if username and password are correct; some providers require full email address as username

## 🤝 Contributing

Issues and Pull Requests are welcome!

## 📄 License

This project is built on the official Ghost image; please follow the respective license requirements.

## 🔗 Related Links

- [Ghost Official Documentation](https://ghost.org/docs/)
- [Filebase Documentation](https://docs.filebase.com/)
- [AWS CLI Documentation](https://docs.aws.amazon.com/cli/)
- [Akash Network Documentation](https://docs.akash.network/)

**Note**: This project is still in development; thorough testing is recommended before production use.

---

# 中文版本

基于 Ghost latest 的 Docker 镜像，提供自动备份和恢复功能，使用 S3 兼容存储(如 Filebase)进行数据持久化。

## 📋 项目简介

`ghost-ipfs-bkup` 是一个增强版的 Ghost 博客 Docker 镜像，在官方 Ghost 镜像基础上添加了：

- 🔄 **自动备份**：每 15 分钟自动备份数据库和图片到 S3 兼容存储
- 🔐 **数据加密**：使用 GPG 对称加密保护数据库文件
- 📦 **自动恢复**：容器启动时自动从 S3 恢复数据
- ☁️ **IPFS 兼容**：支持 Filebase 等 IPFS 网关的 S3 兼容存储

## ✨ 功能特性

- ✅ 基于 Ghost latest 官方镜像
- ✅ SQLite3 数据库支持
- ✅ 自动定时备份(每 15 分钟)
- ✅ GPG 加密数据库备份
- ✅ S3 兼容存储支持(Filebase、AWS S3 等)
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
- **run.sh**: 容器启动脚本，初始化 Ghost、执行恢复、设置定时任务(每 15 分钟)
- **backup.sh**: 备份脚本，包含文件锁机制和错误处理，加密并上传数据库和图片到 S3
- **restore.sh**: 恢复脚本，自动检测备份数据是否存在，从 S3 下载并解密数据

## 🚀 快速开始

### 前置要求

- Docker 或支持容器的运行环境
- S3 兼容存储服务(如 Filebase、AWS S3)
- S3 访问凭证(Access Key ID 和 Secret Access Key)

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
| `FILEBASE_BACKUP_PATH` | 备份目录路径前缀 | 空(备份到存储桶根目录) |
| `NODE_ENV` | Node.js 运行环境 | `production` |

#### 邮件配置环境变量

Ghost 支持通过环境变量配置邮件服务。**注意**：Ghost 使用双下划线(`__`)作为环境变量分隔符来表示嵌套配置。

| 变量名 | 说明 | 示例 |
|--------|------|------|
| `mail__transport` | 邮件传输方式 | `SMTP`(推荐)或 `Direct` |
| `mail__options__host` | SMTP 服务器地址 | `smtp.gmail.com` |
| `mail__options__port` | SMTP 端口 | `587`(TLS)或 `465`(SSL) |
| `mail__options__auth__user` | SMTP 认证用户名 | `your-email@gmail.com` |
| `mail__options__auth__pass` | SMTP 认证密码 | `your-app-password` |
| `mail__from` | 发件人邮箱地址 | `noreply@yourdomain.com` |

**常见邮件服务商配置示例：**

| 服务商 | `mail__options__host` | `mail__options__port` | `mail__options__auth__user` | `mail__options__auth__pass` | 说明 |
|--------|----------------------|---------------------|---------------------------|---------------------------|------|
| **Resend**(推荐) | `smtp.resend.com` | `587` | `resend` | Resend API Key | 现代化邮件服务，配置简单，免费额度充足 |
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
   - `mail__from=noreply@resend.dev`(使用 Resend 提供的测试域名，无需验证)

> **重要提示**：如果不配置邮件服务，Ghost 仍可正常运行，但无法发送欢迎邮件、密码重置邮件等。建议在生产环境中配置邮件服务。

##### FILEBASE_BACKUP_PATH 使用说明

`FILEBASE_BACKUP_PATH` 允许您指定备份在存储桶中的目录路径，这对于以下场景非常有用：

- **多实例隔离**：多个 Ghost 实例可以共享同一个存储桶，但使用不同的备份目录
- **项目组织**：按项目或环境组织备份文件
- **版本管理**：为不同版本的备份创建独立目录

**示例：**

| FILEBASE_BACKUP_PATH 值 | 备份位置 |
|------------------------|---------|
| (未设置) | `s3://bucket/images` 和 `s3://bucket/data` |
| `my-backup` | `s3://bucket/my-backup/images` 和 `s3://bucket/my-backup/data` |
| `project1/backup` | `s3://bucket/project1/backup/images` 和 `s3://bucket/project1/backup/data` |
| `production/ghost` | `s3://bucket/production/ghost/images` 和 `s3://bucket/production/ghost/data` |

> **向后兼容性**：为了保持向后兼容，脚本仍支持旧的变量名(`S3_PATH`、`S3_HOST`、`AWS_ACCESS_KEY_ID`、`AWS_SECRET_ACCESS_KEY`、`KEY_PASSWORD`)，但建议使用新的 Filebase 专用变量名。

### Docker 运行示例

```bash
# 基本使用(备份到存储桶根目录)
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

# 使用自定义备份路径(备份到指定目录)
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

# 完整配置示例(包含 Resend 邮件服务)
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
      # 可选：邮件服务配置(解决邮件发送失败问题)
      # Resend 配置示例(推荐)
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

#### 构建警告说明

构建镜像时，你可能会看到以下警告：

```
WARN: SecretsUsedInArgOrEnv: Do not use ARG or ENV instructions for sensitive data (ENV "FILEBASE_ACCESS_KEY_ID")
WARN: SecretsUsedInArgOrEnv: Do not use ARG or ENV instructions for sensitive data (ENV "FILEBASE_SECRET_ACCESS_KEY")
WARN: SecretsUsedInArgOrEnv: Do not use ARG or ENV instructions for sensitive data (ENV "BACKUP_ENCRYPTION_PASSWORD")
```

**这些警告可以安全忽略。** 原因如下：

- ✅ **基于模式的检测**：Docker BuildKit 根据变量名中包含的关键词（如 `KEY`、`SECRET`、`PASSWORD`）触发警告
- ✅ **不包含真实密钥**：Dockerfile 中只声明了空的环境变量，而非实际的密钥值
- ✅ **运行时注入**：真实凭证通过 `docker run -e` 在运行时传入，永远不会写入镜像层
- ✅ **最佳实践**：这种方式遵循 Docker 安全最佳实践，将配置与镜像分离

这些警告是 Docker 为防止在 Dockerfile 中硬编码密钥的预防措施。由于我们只是声明变量名（空值），并在运行时注入实际密钥，因此不存在安全风险。

### GitHub Actions 自动构建

项目配置了 GitHub Actions 工作流，支持自动构建并推送到 GitHub Container Registry (GHCR)：

**触发条件：**
- 推送到 `main` 分支时：自动构建并推送镜像
- 创建 Release 时：自动构建并推送版本标签镜像(支持 semver 格式)
- 手动触发：在 Actions 页面可以手动触发构建

**镜像标签策略：**
- `latest`：默认分支(main)的最新构建
- `main`：main 分支标签
- `<branch>-<sha>`：分支名和 commit SHA(如 `main-abc1234`)
- `<version>`：Release 版本标签(如 `v0.0.1`)
- `<major>.<minor>`：主版本和次版本(如 `v0.0`)
- `<major>`：主版本(如 `v0`)

**镜像地址格式：**
- `ghcr.io/<用户名>/ghost-ipfs-bkup:<tag>`(如 `ghcr.io/zhajingwen/ghost-ipfs-bkup:latest`)

**必需配置：**

1. **配置 GitHub Secret**：
   - 访问仓库 Settings → Secrets and variables → Actions
   - 点击 "New repository secret"
   - 名称：`GHCR_PAT`
   - 值：GitHub Personal Access Token(需要 `write:packages` 权限)

2. **创建 Personal Access Token**：
   - 访问 GitHub Settings → Developer settings → Personal access tokens → Tokens (classic)
   - 点击 "Generate new token (classic)"
   - 勾选 `write:packages` 权限
   - 生成并复制 token，然后添加到仓库 Secrets 中

**功能特性：**
- ✅ 使用 Docker Buildx 进行构建
- ✅ 启用构建缓存加速后续构建
- ✅ 自动检测 secret 配置，失败时提供清晰错误提示
- ✅ 支持多触发条件(Release、Push、手动触发)

## 🔄 备份和恢复机制

### 备份流程

备份脚本包含文件锁机制，防止多个备份任务并发执行。

1. **图片备份**：将 `content/images` 目录下的所有文件上传到 Filebase/S3
   - 如果设置了 `FILEBASE_BACKUP_PATH`，备份到：`s3://bucket/${FILEBASE_BACKUP_PATH}/images`
   - 如果未设置，备份到：`s3://bucket/images`
   - 备份失败时会输出错误信息并退出

2. **数据库备份**：
   - 清理旧的加密文件(如果存在)
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
   - 检查 S3 存储中是否存在加密的数据库文件(`.gpg` 文件)
   - 如果不存在备份数据，跳过恢复并输出警告信息
3. **从 Filebase/S3 恢复数据**(仅在找到备份数据时执行)：
   - 根据 `FILEBASE_BACKUP_PATH` 配置从对应路径下载数据
   - 下载加密的数据库文件
   - 验证加密文件是否成功下载
   - 使用 GPG 解密数据库
   - 验证解密后的数据库文件是否成功创建
   - 删除临时加密文件
   - 恢复图片文件(图片恢复失败不会阻止数据库恢复)
4. **设置定时备份任务**(每 15 分钟)
5. **启动 Ghost 服务**

> **注意**：恢复时使用的 `FILEBASE_BACKUP_PATH` 必须与备份时设置的路径一致，否则无法找到备份文件。如果 S3 中不存在备份数据，容器仍会正常启动，但不会执行恢复操作。

### 备份时间表

- **频率**：每 15 分钟自动备份一次
- **日志**：备份日志输出到容器标准输出(stdout)，可通过 `docker logs` 命令查看
- **并发保护**：使用文件锁机制防止多个备份任务同时执行

## 🌐 部署到 Akash 网络

项目包含 `deploy.yaml` 配置文件，支持部署到 Akash 去中心化云网络：

```bash
akash deploy deploy.yaml
```

部署前需要修改 `deploy.yaml` 中的：
- 域名配置(`changeme.com`)
- 环境变量值
- 资源配额

## ⚠️ 注意事项和已知问题

### 安全建议

1. **密码安全**：
   - `BACKUP_ENCRYPTION_PASSWORD` 和 `FILEBASE_SECRET_ACCESS_KEY` 是敏感信息
   - 建议使用密钥管理服务(如 Kubernetes Secrets、Docker Secrets)
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

1. 确认 Filebase/S3 中存在备份文件(`.gpg` 格式的加密数据库文件)
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
   - 确保使用双下划线(`__`)作为分隔符，而不是单下划线
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
  - 用户名必须设置为 `resend`(固定值)
  - 密码使用你的 Resend API Key(格式：`re_xxxxxxxxxxxxx`)
  - `mail__from` 固定使用 `noreply@resend.dev`(Resend 提供的测试域名，无需验证)
- **Gmail 连接失败**：确保已启用"允许不够安全的应用访问"，或使用应用专用密码
- **端口被阻止**：某些网络环境可能阻止 587 端口，尝试使用 465 端口(SSL)
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
