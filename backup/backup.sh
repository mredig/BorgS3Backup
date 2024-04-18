#!/usr/bin/env sh

BORG_DIR="/borgdir"

if [ ! -d "${BORG_DIR}" ]]; then
    borg init -e none "${BORG_DIR}"
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

RCOMMAND=("rclone")
RCOMMAND+=("sync")
RCOMMAND+=("/borgdir/")
RCOMMAND+=("${RCLONE_REMOTE_NAME}:/${BACKUP_TITLE}/")

"${RCOMMAND[@]}"
