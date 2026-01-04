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

# ============================================================
# s3cmd 配置生成
# ============================================================
# 移除协议前缀 (s3cmd 不需要 https://)
S3_HOST_CLEAN="${FILEBASE_ENDPOINT#https://}"
S3_HOST_CLEAN="${S3_HOST_CLEAN#http://}"

cat > ~/.s3cfg <<EOF
[default]
access_key = ${FILEBASE_ACCESS_KEY_ID}
secret_key = ${FILEBASE_SECRET_ACCESS_KEY}
host_base = ${S3_HOST_CLEAN}
host_bucket = %(bucket)s.${S3_HOST_CLEAN}
use_https = True
check_ssl_certificate = True
check_ssl_hostname = True
EOF

# Build S3 base URI with optional backup path prefix
if [ -n "$FILEBASE_BACKUP_PATH" ]; then
  # Remove leading/trailing slashes and ensure proper format
  BACKUP_PATH_PREFIX=$(echo "$FILEBASE_BACKUP_PATH" | sed 's|^/||;s|/$||')
  s3_uri_base="s3://${FILEBASE_BUCKET}/${BACKUP_PATH_PREFIX}"
else
  s3_uri_base="s3://${FILEBASE_BUCKET}"
fi

backup_path=$GHOST_CONTENT
now=$(date +"%T")

echo "starting restore.... $now"
echo "Restore source: ${s3_uri_base}"

# Check if backup data exists in filebase using s3cmd
echo "Checking for backup data in filebase..."
if s3cmd ls "${s3_uri_base}/data/" 2>/dev/null | grep -q "\.gpg$"; then
    echo "Found backup data, starting restore..."

    # restore db - download encrypted file using s3cmd
    if ! s3cmd get \
        "${s3_uri_base}/data/ghost.db.gpg" \
        "${backup_path}/data/ghost.db.gpg"; then
        echo "Error: Failed to download encrypted database file from S3"
        exit 1
    fi

    # Verify encrypted file exists before decrypting
    if [ ! -f "${backup_path}/data/ghost.db.gpg" ]; then
        echo "Error: Encrypted database file was not downloaded"
        exit 1
    fi

    # Decrypt database file
    if ! gpg --decrypt --batch --passphrase "$BACKUP_ENCRYPTION_PASSWORD" "${backup_path}/data/ghost.db.gpg" > "${backup_path}/data/ghost.db"; then
        echo "Error: GPG decryption failed"
        rm -f "${backup_path}/data/ghost.db.gpg"
        exit 1
    fi

    # Verify decrypted file was created
    if [ ! -f "${backup_path}/data/ghost.db" ]; then
        echo "Error: Decrypted database file was not created"
        rm -f "${backup_path}/data/ghost.db.gpg"
        exit 1
    fi

    # Remove temporary encrypted file
    rm -f "${backup_path}/data/ghost.db.gpg"

    # restore images using s3cmd
    if ! s3cmd sync \
        --exclude '*' \
        --include '*.*' \
        "${s3_uri_base}/images/" \
        "${backup_path}/images/"; then
        echo "Warning: Failed to restore images, but database restore succeeded"
    fi

    now=$(date +"%T")
    echo "complete restore.... $now"
else
    echo "Warning: No backup data found in ${s3_uri_base}/data/, skipping restore"
    now=$(date +"%T")
    echo "complete restore.... $now (skipped - no backup data)"
fi
