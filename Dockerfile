FROM ghost:latest

RUN apk add --no-cache aws-cli gnupg

COPY ./run.sh /usr/local/bin/run.sh
RUN chmod +x /usr/local/bin/run.sh

COPY ./backup.sh /usr/local/bin/backup.sh
RUN chmod +x /usr/local/bin/backup.sh

COPY ./restore.sh /usr/local/bin/restore.sh
RUN chmod +x /usr/local/bin/restore.sh

ENV FILEBASE_ENDPOINT="${FILEBASE_ENDPOINT:-https://s3.filebase.com}"
ENV database__client=sqlite3
ENV database__connection__filename=content/data/ghost.db

## run script
CMD ["run.sh"]