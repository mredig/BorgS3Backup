#!/usr/bin/env sh

## imported env vars
# BACKUP_15MIN
# BACKUP_HOURLY
# BACKUP_DAILY
# BACKUP_WEEKLY
# BACKUP_MONTHLY
# RUN_ON_START
## end

trap 'echo "Received SIGTERM. Terminating."; exit' SIGTERM

if [[ $BACKUP_15MIN ]]; then
    ln -s /usr/bin/backup.sh /etc/periodic/15min/
fi
if [[ $BACKUP_HOURLY ]]; then
    ln -s /usr/bin/backup.sh /etc/periodic/hourly/
fi
if [[ $BACKUP_DAILY ]]; then
    ln -s /usr/bin/backup.sh /etc/periodic/daily/
fi
if [[ $BACKUP_WEEKLY ]]; then
    ln -s /usr/bin/backup.sh /etc/periodic/weekly/
fi
if [[ $BACKUP_MONTHLY ]]; then
    ln -s /usr/bin/backup.sh /etc/periodic/monthly/
fi

if [[ $RUN_ON_START ]]; then
    /usr/bin/backup.sh
fi

crond -f
