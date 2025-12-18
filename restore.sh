#!/bin/bash
# Support both new and legacy environment variable names for backward compatibility
FILEBASE_BUCKET="${FILEBASE_BUCKET:-${S3_PATH}}"
FILEBASE_ENDPOINT="${FILEBASE_ENDPOINT:-${S3_HOST}}"
FILEBASE_ACCESS_KEY_ID="${FILEBASE_ACCESS_KEY_ID:-${AWS_ACCESS_KEY_ID}}"
FILEBASE_SECRET_ACCESS_KEY="${FILEBASE_SECRET_ACCESS_KEY:-${AWS_SECRET_ACCESS_KEY}}"
BACKUP_ENCRYPTION_PASSWORD="${BACKUP_ENCRYPTION_PASSWORD:-${KEY_PASSWORD}}"
# Backup path prefix (optional, defaults to empty for root of bucket)
# Example: "my-backup" will restore from s3://bucket/my-backup/images and s3://bucket/my-backup/data
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

echo "starting restore.... $now"
echo "Restore source: ${s3_uri_base}"

# restore db
aws $aws_args s3 cp "${s3_uri_base}/data" "${backup_path}/data" --recursive --exclude "*" --include "*.gpg"
gpg --decrypt --batch --passphrase "$BACKUP_ENCRYPTION_PASSWORD" "${backup_path}/data/ghost.db.gpg" > "${backup_path}/data/ghost.db"
rm "${backup_path}/data/ghost.db.gpg"

# restore images
aws $aws_args s3 cp "${s3_uri_base}/images" "${backup_path}/images" --recursive --exclude "*" --include "*.*"

now=$(date +"%T")
echo "complete restore.... $now"