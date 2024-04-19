#!/usr/bin/env bash

BORG_DIR="/borgdir/backup_repo"

if [ ! -d "${BORG_DIR}" ]; then
    borg init -e none "${BORG_DIR}"
    echo "Created repo at ${BORG_DIR}"
else
    echo "Using existing repo at ${BORG_DIR}"
fi

# BACKUP_TIMESTAMP=$(date -Iseconds)
BACKUP_TIMESTAMP=$(date +%s)

THIS_BACKUP_TITLE="${BACKUP_TITLE}-${BACKUP_TIMESTAMP}"

COMMAND=("borg")
COMMAND+=("create")
if [[ $KEEP_STATS ]]; then
    COMMAND+=("--stats")
fi
COMMAND+=("${BORG_DIR}::${THIS_BACKUP_TITLE}")
COMMAND+=("/backups")

if [[ $KEEP_STATS ]]; then
    "${COMMAND[@]}" >> /root/stats
    echo "" >> /root/stats
else
    "${COMMAND[@]}"
fi

if [[ -z "$RCLONE_S3_ACCESS_KEY_ID" ]]; then
    echo "RCLONE_S3_ACCESS_KEY_ID undefined. Checking for file."
    if [[ "$RCLONE_S3_ACCESS_KEY_ID_FILE" ]]; then
        echo "RCLONE_S3_ACCESS_KEY_ID_FILE defined. Loading."
        RCLONE_S3_ACCESS_KEY_ID=$(cat "${RCLONE_S3_ACCESS_KEY_ID_FILE}")
    else
        echo "No key provided for RCLONE_S3_ACCESS_KEY_ID - aborting rclone upload".
        exit 1
    fi
fi

if [[ -z "$RCLONE_S3_SECRET_ACCESS_KEY" ]]; then
    echo "RCLONE_S3_SECRET_ACCESS_KEY undefined. Checking for file."
    if [[ "$RCLONE_S3_SECRET_ACCESS_KEY_FILE" ]]; then
        echo "RCLONE_S3_SECRET_ACCESS_KEY_FILE defined. Loading."
        RCLONE_S3_SECRET_ACCESS_KEY=$(cat "${RCLONE_S3_SECRET_ACCESS_KEY_FILE}")
    else
        echo "No key provided for RCLONE_S3_ACCESS_KEY_ID - aborting rclone upload".
        exit 1
    fi
fi

if [[ ! -r /rclone.conf ]]; then
    echo "No rclone config file at /rclone.conf! aborting"
    exit 1
fi

RCOMMAND=("rclone")
RCOMMAND+=("-P")
RCOMMAND+=("--config=/rclone.conf")
RCOMMAND+=("sync")
RCOMMAND+=("/borgdir/")
RCOMMAND+=("${RCLONE_REMOTE_NAME}:${RCLONE_REMOTE_BACKUP_PATH}/${BACKUP_TITLE}/")

echo "Running '${COMMAND[@]}'"

"${RCOMMAND[@]}"
