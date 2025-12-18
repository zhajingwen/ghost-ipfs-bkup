#!/bin/bash

# prep ghost stuff from entry point script
baseDir="$GHOST_INSTALL/content.orig"
for src in "$baseDir"/*/ "$baseDir"/themes/*; do
    src="${src%/}"
    target="$GHOST_CONTENT/${src#$baseDir/}"
    mkdir -p "$(dirname "$target")"
    if [ ! -e "$target" ]; then
        tar -cC "$(dirname "$src")" "$(basename "$src")" | tar -xC "$(dirname "$target")"
    fi
done

# run restore
/usr/local/bin/restore.sh

# Set the path to the script you want to run as a cron job
script_path=/usr/local/bin/backup.sh

# backup every 15 minutes
(crontab -l 2>/dev/null; cat <<EOF
FILEBASE_BUCKET=${FILEBASE_BUCKET}
FILEBASE_ENDPOINT=${FILEBASE_ENDPOINT}
FILEBASE_ACCESS_KEY_ID=${FILEBASE_ACCESS_KEY_ID}
FILEBASE_SECRET_ACCESS_KEY=${FILEBASE_SECRET_ACCESS_KEY}
BACKUP_ENCRYPTION_PASSWORD=${BACKUP_ENCRYPTION_PASSWORD}
FILEBASE_BACKUP_PATH=${FILEBASE_BACKUP_PATH}
GHOST_CONTENT=${GHOST_CONTENT}
*/15 * * * * $script_path 2>&1 | tee -a /var/log/daily-backup.log > /proc/1/fd/1
EOF
) | crontab -

# start ghost
cron && node current/index.js