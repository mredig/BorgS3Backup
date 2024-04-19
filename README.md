# BorgS3Backup Example

This is a starter repo to setup a docker/podman automated backup, primarily intended for docker persistent setting files, but can really be used to backup anything to S3 (or any storage supported by rclone).

### Important details to note before continuing:

First, keep in mind that the entirety of the backup will need to reside on the same host that contains this backup container. It will roughly duplicate the size of the original data (minus a little due to compression and borg deduping) so make sure you have enough space on your server for that.

Second, something else. - secrets in global name space, but can run multiple copies of this

### Getting started

1. Fork or otherwise copy this repo to manage your own project
1. before the first setup, run `secret-setup.py` to store all your secrets in docker.
1. configure your docker-compose file with what you need to back up. Add as many directories as you want to back up to the volumes, just making sure to mount all your backups inside `/backups/` in the container.
	1. configure your rclone.conf file and set in the docker-compose volume mount (see example in docker-compose). This, ideally, will just be the S3 endpoint information with no secrets (as those should be included through docker secrets in secret-setup.py)
	1. All environment values that have `true` are considered true with *any* value. To make them false, just comment out the line you want to nullify.
