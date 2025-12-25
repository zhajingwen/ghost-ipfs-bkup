#!/bin/bash
# Support both new and legacy environment variable names for backward compatibility
FILEBASE_BUCKET="${FILEBASE_BUCKET:-${S3_PATH}}"
FILEBASE_ENDPOINT="${FILEBASE_ENDPOINT:-${S3_HOST}}"
FILEBASE_ACCESS_KEY_ID="${FILEBASE_ACCESS_KEY_ID:-${AWS_ACCESS_KEY_ID}}"
FILEBASE_SECRET_ACCESS_KEY="${FILEBASE_SECRET_ACCESS_KEY:-${AWS_SECRET_ACCESS_KEY}}"
BACKUP_ENCRYPTION_PASSWORD="${BACKUP_ENCRYPTION_PASSWORD:-${KEY_PASSWORD}}"
# Backup path prefix (optional, defaults to empty for root of bucket)
# Example: "my-backup" will backup to s3://bucket/my-backup/images and s3://bucket/my-backup/data
FILEBASE_BACKUP_PATH="${FILEBASE_BACKUP_PATH:-}"

# Export AWS credentials for AWS CLI
export AWS_ACCESS_KEY_ID="${FILEBASE_ACCESS_KEY_ID}"
export AWS_SECRET_ACCESS_KEY="${FILEBASE_SECRET_ACCESS_KEY}"

# Build S3 base URI with optional backup path prefix
if [ -n "$FILEBASE_BACKUP_PATH" ]; then
  # Remove leading/trailing slashes and ensure proper format
  BACKUP_PATH_PREFIX=$(echo "$FILEBASE_BACKUP_PATH" | sed 's|^/||;s|/$||')
  s3_uri_base="s3://${FILEBASE_BUCKET}/${BACKUP_PATH_PREFIX}"
else
  s3_uri_base="s3://${FILEBASE_BUCKET}"
fi

aws_args="--endpoint-url ${FILEBASE_ENDPOINT}"
backup_path=$GHOST_CONTENT
now=$(date +"%T")

# File lock mechanism to prevent concurrent execution
LOCK_FILE="/tmp/ghost-backup.lock"

# Check if lock file exists, if so exit
if [ -f "$LOCK_FILE" ]; then
    echo "Backup already in progress, skipping..."
    exit 0
fi

# Create lock file and set trap to clean up on exit
trap "rm -f $LOCK_FILE; exit" INT TERM EXIT
touch "$LOCK_FILE"

echo "starting backup.... $now"
echo "Backup destination: ${s3_uri_base}"

# 备份前去重
node /usr/local/bin/dedup-posts.js 2>&1 || true

# Backup images
if ! aws $aws_args s3 cp "${backup_path}/images" "${s3_uri_base}/images" --recursive --exclude "*" --include "*.*"; then
    echo "Error: Failed to backup images"
    rm -f "$LOCK_FILE"
    exit 1
fi

# Clean up old encrypted file before encryption
rm -f "${backup_path}/data/ghost.db.gpg"

# Encrypt database file
if ! gpg --symmetric --batch --passphrase "$BACKUP_ENCRYPTION_PASSWORD" "${backup_path}/data/ghost.db"; then
    echo "Error: GPG encryption failed"
    rm -f "$LOCK_FILE"
    exit 1
fi

# Verify encrypted file was created
if [ ! -f "${backup_path}/data/ghost.db.gpg" ]; then
    echo "Error: Encrypted file was not created"
    rm -f "$LOCK_FILE"
    exit 1
fi

# Upload encrypted database file
if ! aws $aws_args s3 cp "${backup_path}/data/" "${s3_uri_base}/data" --recursive --exclude "*" --include "*.gpg"; then
    echo "Error: S3 upload failed"
    rm -f "${backup_path}/data/ghost.db.gpg"
    rm -f "$LOCK_FILE"
    exit 1
fi

# Remove temporary encrypted file
rm -f "${backup_path}/data/ghost.db.gpg"

# Remove lock file
rm -f "$LOCK_FILE"

now=$(date +"%T")
echo "complete backup.... $now"