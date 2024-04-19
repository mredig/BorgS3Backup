#!/usr/bin/env bash

## imported env vars
# '?' indicates optional
# RCLONE_S3_ACCESS_KEY_ID
# RCLONE_S3_SECRET_ACCESS_KEY
#   OR
# RCLONE_S3_ACCESS_KEY_ID_FILE
# RCLONE_S3_SECRET_ACCESS_KEY_FILE
#
# BACKUP_TITLE
# RCLONE_REMOTE_NAME
# RCLONE_REMOTE_BACKUP_PATH
## end

BORG_REPO_PARENT_DIR="/borgdir"
BORG_REPO_DIR="${BORG_REPO_PARENT_DIR}/backup_repo"
BORG_BACKUPS_DIR="/backups"
RCLONE_CONF_FILE_PATH="/rclone.conf"

export BORG_RELOCATED_REPO_ACCESS_IS_OK=yes
export BORG_UNKNOWN_UNENCRYPTED_REPO_ACCESS_IS_OK=yes

if [ ! -d "${BORG_REPO_DIR}" ]; then
    borg init -e none "${BORG_REPO_DIR}"
    echo "Created repo at ${BORG_REPO_DIR}"
else
    echo "Using existing repo at ${BORG_REPO_DIR}"
fi

THIS_BACKUP_TITLE="${BACKUP_TITLE}-{fqdn}_{now}"

COMMAND=("borg")
COMMAND+=("create")
COMMAND+=("--stats")
COMMAND+=("${BORG_REPO_DIR}::${THIS_BACKUP_TITLE}")
COMMAND+=("${BORG_BACKUPS_DIR}")

# if [[ $KEEP_STATS ]]; then
#     "${COMMAND[@]}" >> /root/stats
#     echo "" >> /root/stats
# else
# fi
"${COMMAND[@]}"

if [[ -z "$RCLONE_S3_ACCESS_KEY_ID" ]]; then
    echo "RCLONE_S3_ACCESS_KEY_ID undefined. Checking for file."
    if [[ "$RCLONE_S3_ACCESS_KEY_ID_FILE" ]]; then
        echo "RCLONE_S3_ACCESS_KEY_ID_FILE defined. Loading."
        export RCLONE_S3_ACCESS_KEY_ID=$(cat "${RCLONE_S3_ACCESS_KEY_ID_FILE}")
    else
        echo "No key provided for RCLONE_S3_ACCESS_KEY_ID - aborting rclone upload".
        exit 1
    fi
fi

if [[ -z "$RCLONE_S3_SECRET_ACCESS_KEY" ]]; then
    echo "RCLONE_S3_SECRET_ACCESS_KEY undefined. Checking for file."
    if [[ "$RCLONE_S3_SECRET_ACCESS_KEY_FILE" ]]; then
        echo "RCLONE_S3_SECRET_ACCESS_KEY_FILE defined. Loading."
        export RCLONE_S3_SECRET_ACCESS_KEY=$(cat "${RCLONE_S3_SECRET_ACCESS_KEY_FILE}")
    else
        echo "No key provided for RCLONE_S3_ACCESS_KEY_ID - aborting rclone upload".
        exit 1
    fi
fi

if [[ ! -e "${RCLONE_CONF_FILE_PATH}" ]]; then
    echo "No rclone config file at /rclone.conf! aborting"
    exit 1
fi

export RCLONE_S3_NO_CHECK_BUCKET=true

RCOMMAND=("rclone")
RCOMMAND+=("-P")
RCOMMAND+=("--config=${RCLONE_CONF_FILE_PATH}")
RCOMMAND+=("sync")
RCOMMAND+=("${BORG_REPO_PARENT_DIR}/")
RCOMMAND+=("${RCLONE_REMOTE_NAME}:${RCLONE_REMOTE_BACKUP_PATH}/${BACKUP_TITLE}/")

echo "Running '${RCOMMAND[@]}'"

"${RCOMMAND[@]}"
