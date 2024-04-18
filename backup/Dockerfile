FROM rclone/rclone:latest

RUN apk update
RUN apk add borgbackup openrc busybox-openrc bash tzdata

RUN rc-update add crond
RUN rm -rf /var/cache/apk/*

WORKDIR /

RUN mkdir -p /borgdir
RUN mkdir -p /backups

COPY backup.sh /usr/bin/
COPY entrypoint.sh /

ENTRYPOINT /entrypoint.sh
