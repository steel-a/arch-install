FILESERVER_PARTITION="sda1"
PATH_TO_MOUNT="/mnt/data"
PARTITION_TYPE="ext4"

DOCKER_USER="mi"
SAMBA_FS_USER="mi"
SAMBA_FS_MOUNT_LABEL="Fileserver"
SAMBA_FS_PATH="/mnt/data/f"

PROJ_PATH="https://raw.githubusercontent.com/steel-a/arch-install/master/"

# Mount HD for Fileserver
UUID="$(blkid | grep ${FILESERVER_PARTITION} | grep -m 1 -oP '((?<=: UUID=")([a-z0-9-]*))')"

if grep -q $UUID /etc/fstab
then
  echo "UUID is already in fstab"
else
  echo -e "UUID=${UUID} \t${PATH_TO_MOUNT} \t${PARTITION_TYPE} \trw,relatime \t0 2" >> /etc/fstab
  mkdir ${PATH_TO_MOUNT}
  mount /dev/${FILESERVER_PARTITION} ${PATH_TO_MOUNT}
fi


# Install Docker
yes | pacman -S docker
sudo usermod -aG docker $DOCKER_USER
systemctl start docker
systemctl enable docker


# Samba install
yes | pacman -S samba
FILE="/etc/samba/smb.conf"
mkdir -p /usr/local/samba/var/

# smb.conf exists? Create
if test -f "$FILE";
then
    echo "smb.conf already exists"
else

		FILE2="./smb.conf"
		if test -f "$FILE2";
		then
			echo "${FILE2} already exists"
		else
      wget ${PROJ_PATH}smb.conf
		fi
    mv smb.conf /etc/samba
fi

# ${SAMBA_FS_MOUNT_LABEL} in smb.conf? Insert
if grep -q ${SAMBA_FS_MOUNT_LABEL}] ${FILE}
then
  echo "${SAMBA_FS_MOUNT_LABEL} entry has alread in smb.conf"
else
  echo "[${SAMBA_FS_MOUNT_LABEL}]" >> ${FILE}
  echo "path = ${SAMBA_FS_PATH}" >> ${FILE}
  echo "valid users = ${SAMBA_FS_USER}" >> ${FILE}
  echo "read only = no" >> ${FILE}
fi

# Samba dir exists? create
DIR="${SAMBA_FS_PATH}"
if [ -d "$SAMBA_FS_PATH" ]
then
  echo "Samba FS directory [${SAMBA_FS_PATH}] alread exists"
else
  mkdir -p $SAMBA_FS_PATH
  chown ${SAMBA_FS_USER} $SAMBA_FS_PATH
fi

# Set the root and other user passwords
clear
echo "Set password for samba user ${SAMBA_FS_USER}"
smbpasswd -a ${SAMBA_FS_USER}

systemctl start smb
systemctl enable smb
