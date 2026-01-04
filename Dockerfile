# ============================================================
# 阶段 1: 构建阶段 - 编译 better-sqlite3
# ============================================================
FROM ghost:latest AS builder

# 安装编译依赖（仅此阶段需要）
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        python3 \
        make \
        g++ && \
    rm -rf /var/lib/apt/lists/*

# 编译 better-sqlite3
WORKDIR /var/lib/ghost
RUN npm install better-sqlite3

# ============================================================
# 阶段 2: 最终运行镜像
# ============================================================
FROM ghost:latest

# 单层安装运行时依赖 + 清理（节省 ~80MB）
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        s3cmd \
        gnupg \
        cron \
        ca-certificates && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* \
           /tmp/* \
           /var/tmp/* \
           /usr/share/doc/* \
           /usr/share/man/*

# 从构建阶段复制已编译的 better-sqlite3 及其依赖（避免包含构建工具，节省 ~200MB）
# 复制整个 node_modules（只包含 better-sqlite3 及其依赖：bindings, file-uri-to-path 等）
COPY --from=builder /var/lib/ghost/node_modules /var/lib/ghost/node_modules

# 复制脚本文件
COPY ./run.sh /usr/local/bin/run.sh
COPY ./backup.sh /usr/local/bin/backup.sh
COPY ./restore.sh /usr/local/bin/restore.sh
COPY ./scripts/dedup-posts.js /usr/local/bin/dedup-posts.js

# 设置执行权限
RUN chmod +x /usr/local/bin/run.sh \
             /usr/local/bin/backup.sh \
             /usr/local/bin/restore.sh \
             /usr/local/bin/dedup-posts.js

# Ghost 数据库配置
ENV database__client=sqlite3
ENV database__connection__filename=content/data/ghost.db

# S3 备份配置（运行时通过 -e 设置）
ENV FILEBASE_ENDPOINT=""
ENV FILEBASE_BUCKET=""
ENV FILEBASE_ACCESS_KEY_ID=""
ENV FILEBASE_SECRET_ACCESS_KEY=""
ENV BACKUP_ENCRYPTION_PASSWORD=""
ENV FILEBASE_BACKUP_PATH=""

## run script
CMD ["run.sh"]
