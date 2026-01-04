FROM ghost:latest

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        awscli \
        gnupg \
        cron && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# 在 Ghost 工作目录中本地安装 better-sqlite3
RUN cd /var/lib/ghost && npm install better-sqlite3

COPY ./run.sh /usr/local/bin/run.sh
RUN chmod +x /usr/local/bin/run.sh

COPY ./backup.sh /usr/local/bin/backup.sh
RUN chmod +x /usr/local/bin/backup.sh

COPY ./restore.sh /usr/local/bin/restore.sh
RUN chmod +x /usr/local/bin/restore.sh

COPY ./scripts/dedup-posts.js /usr/local/bin/dedup-posts.js
RUN chmod +x /usr/local/bin/dedup-posts.js

ENV database__client=sqlite3
ENV database__connection__filename=content/data/ghost.db

# Filebase/S3 backup configuration - MUST be set at runtime via docker run -e
ENV FILEBASE_ENDPOINT=""
ENV FILEBASE_BUCKET=""
ENV FILEBASE_ACCESS_KEY_ID=""
ENV FILEBASE_SECRET_ACCESS_KEY=""
ENV BACKUP_ENCRYPTION_PASSWORD=""
ENV FILEBASE_BACKUP_PATH=""

## run script
CMD ["run.sh"]