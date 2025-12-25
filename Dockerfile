FROM ghost:latest

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        awscli \
        gnupg \
        cron && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN npm install -g better-sqlite3

COPY ./run.sh /usr/local/bin/run.sh
RUN chmod +x /usr/local/bin/run.sh

COPY ./backup.sh /usr/local/bin/backup.sh
RUN chmod +x /usr/local/bin/backup.sh

COPY ./restore.sh /usr/local/bin/restore.sh
RUN chmod +x /usr/local/bin/restore.sh

COPY ./scripts/dedup-posts.js /usr/local/bin/dedup-posts.js
RUN chmod +x /usr/local/bin/dedup-posts.js

ENV FILEBASE_ENDPOINT="${FILEBASE_ENDPOINT:-https://s3.filebase.com}"
ENV database__client=sqlite3
ENV database__connection__filename=content/data/ghost.db

## run script
CMD ["run.sh"]