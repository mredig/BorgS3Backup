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
# PRUNE_KEEP_HOURLY_COUNT?
# PRUNE_KEEP_DAILY_COUNT?
# PRUNE_KEEP_WEEKLY_COUNT?
# PRUNE_KEEP_MONTHLY_COUNT?
# PRUNE_KEEP_YEARLY_COUNT?
# PRUNE_KEEP_ALL_WITHIN_SECONDS?
# PRUNE_GLOB?
## end

BORG_REPO_PARENT_DIR="/borgdir"
# borg setup
BORG_REPO_DIR="${BORG_REPO_PARENT_DIR}/backup_repo"
BORG_BACKUPS_DIR="/backups"
RCLONE_CONF_FILE_PATH="/rclone.conf"

# https://borgbackup.readthedocs.io/en/stable/usage/general.html#env-vars
export BORG_RELOCATED_REPO_ACCESS_IS_OK=yes
export BORG_UNKNOWN_UNENCRYPTED_REPO_ACCESS_IS_OK=yes

if [ ! -d "${BORG_REPO_DIR}" ]; then
    borg init -e none "${BORG_REPO_DIR}"
    echo "Created repo at ${BORG_REPO_DIR}"
else
    echo "Using existing repo at ${BORG_REPO_DIR}"
fi

THIS_BACKUP_TITLE="${BACKUP_TITLE}-{fqdn}_{now}"

# borg run
BORG_COMMAND=("borg")
BORG_COMMAND+=("create")
BORG_COMMAND+=("--stats")
BORG_COMMAND+=("${BORG_REPO_DIR}::${THIS_BACKUP_TITLE}")
BORG_COMMAND+=("${BORG_BACKUPS_DIR}")

"${BORG_COMMAND[@]}"

# borg pruning
SHOULD_PRUNE=false

PRUNE_COMMAND=("borg")
PRUNE_COMMAND+=("prune")
PRUNE_COMMAND+=("--list")

if [[ $PRUNE_KEEP_HOURLY_COUNT ]]; then
    SHOULD_PRUNE=true
    PRUNE_COMMAND+=("-H")
    PRUNE_COMMAND+=("${PRUNE_KEEP_HOURLY_COUNT}")
fi

if [[ $PRUNE_KEEP_DAILY_COUNT ]]; then
    SHOULD_PRUNE=true
    PRUNE_COMMAND+=("-d")
    PRUNE_COMMAND+=("${PRUNE_KEEP_DAILY_COUNT}")
fi

if [[ $PRUNE_KEEP_WEEKLY_COUNT ]]; then
    SHOULD_PRUNE=true
    PRUNE_COMMAND+=("-w")
    PRUNE_COMMAND+=("${PRUNE_KEEP_WEEKLY_COUNT}")
fi

if [[ $PRUNE_KEEP_MONTHLY_COUNT ]]; then
    SHOULD_PRUNE=true
    PRUNE_COMMAND+=("-m")
    PRUNE_COMMAND+=("${PRUNE_KEEP_MONTHLY_COUNT}")
fi

if [[ $PRUNE_KEEP_YEARLY_COUNT ]]; then
    SHOULD_PRUNE=true
    PRUNE_COMMAND+=("-y")
    PRUNE_COMMAND+=("${PRUNE_KEEP_YEARLY_COUNT}")
fi

if [[ $PRUNE_KEEP_ALL_WITHIN ]]; then
    SHOULD_PRUNE=true
    PRUNE_COMMAND+=("--keep-within")
    PRUNE_COMMAND+=("${PRUNE_KEEP_ALL_WITHIN}")
fi

if [[ $PRUNE_GLOB ]]; then
    PRUNE_COMMAND+=("-a")
    PRUNE_COMMAND+=("${PRUNE_GLOB}")
fi

if [[ $SHOULD_PRUNE == true ]]; then
	echo "Pruning."
	PRUNE_COMMAND+=("${BORG_REPO_DIR}")
	"${PRUNE_COMMAND[@]}"

	COMPACT_COMMAND=("borg")
	COMPACT_COMMAND+=("compact")
	COMPACT_COMMAND+=("${BORG_REPO_DIR}")
	"${COMPACT_COMMAND[@]}"
else
	echo "Skipping pruning."
fi

# rclone setup

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

# rclone run

# https://rclone.org/s3/#s3-no-check-bucket for other env var info
export RCLONE_S3_NO_CHECK_BUCKET=true

RCLONE_COMMAND=("rclone")
RCLONE_COMMAND+=("-P")
RCLONE_COMMAND+=("--config=${RCLONE_CONF_FILE_PATH}")
RCLONE_COMMAND+=("sync")
RCLONE_COMMAND+=("${BORG_REPO_PARENT_DIR}/")
RCLONE_COMMAND+=("${RCLONE_REMOTE_NAME}:${RCLONE_REMOTE_BACKUP_PATH}/${BACKUP_TITLE}/")

echo "Running '${RCLONE_COMMAND[@]}'"

"${RCLONE_COMMAND[@]}"
