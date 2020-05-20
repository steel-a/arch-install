FILESERVER_PARTITION="sdb1"
PATH_TO_MOUNT="/mnt/data"

SAMBA_USER="mi"
SAMBA_MOUNT_LABEL="data"

PROJ_PATH="https://raw.githubusercontent.com/steel-a/arch-install/master/"

UUID="$(blkid | grep -m 1 -oP '((?<=${FILESERVER_PARTITION}: UUID=")([a-z0-9-]*))')"

echo $UUID
