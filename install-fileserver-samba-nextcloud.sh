FILESERVER_PARTITION="sdb1"
PATH_TO_MOUNT="/mnt/data"
PARTITION_TYPE="ext4"

SAMBA_USER="mi"
SAMBA_MOUNT_LABEL="data"

PROJ_PATH="https://raw.githubusercontent.com/steel-a/arch-install/master/"

UUID="$(blkid | grep ${FILESERVER_PARTITION} | grep -m 1 -oP '((?<=: UUID=")([a-z0-9-]*))')"

if grep -q $UUID /etc/fstab
then
  echo "UUID is already in fstab"
else
  echo -e "UUID=${UUID} \t${PATH_TO_MOUNT} \t${PARTITION_TYPE} \trw,relatime \t0 2" >> /etc/fstab
  mkdir ${PATH_TO_MOUNT}
  mount /dev/${FILESERVER_PARTITION} ${PATH_TO_MOUNT}
fi

