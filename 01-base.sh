# List of variables

#Connected via cable
KEYBOARD="us-acentos"
REGION="America"
CITY="Sao_Paulo"
HOST_NAME="home01"
SWAP_SIZE="2048M"

PROJ_PATH="https://raw.githubusercontent.com/steel-a/arch-install/master/"

# Get first Disk from fdisk -l
HD="$(fdisk -l | grep -m 1 -oP "(?<=Disk /dev/)([^l][a-z]*)")"

# Verify the boot mode, if efivars directory exists, boot mode = EFI
DIR="/sys/firmware/efi/efivars/"
if [ -d "$DIR" ]; then
	HD_EFI="${HD}1"
	HD_LINUX="${HD}2"
	wget ${PROJ_PATH}create-partitions-boot-linux.sh
	chmod 700 create-partitions-boot-linux.sh
	create-partitions-boot-linux.sh
	mkfs.fat -F32 /dev/$HD_EFI
	mkfs.ext4 /dev/$HD_LINUX
	mount /dev/$HD_LINUX /mnt
	mount /dev/$HD_EFI /mnt/boot
else
	HD_LINUX=${HD}1
	wget ${PROJ_PATH}create-partition-linux.sh
	chmod 700 create-partition-linux.sh
	create-partition-linux.sh
	mkfs.ext4 /dev/$HD_LINUX
	mount /dev/$HD_LINUX /mnt
	exit 1
fi

read p

# Atualizar relógio do sistema
timedatectl set-ntp true

# Edit mirros /etc/pacman.d/mirrorlist

# Install LTS with NO FIRMWARE
pacstrap /mnt base linux-lts

# Generate fstab
genfstab -U /mnt > /mnt/etc/fstab

# Create swapfile
fallocate -l ${SWAP_SIZE} /swapfile
ls -lh /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
echo "/swapfile	none	swap	defaults	0	0" >> /mnt/etc/fstab

# Change root into the new system
arch-chroot /mnt

# Set the time zone
ln -sf /usr/share/zoneinfo/${REGION}/${CITY} /etc/localtime

# Adjust hardware date and time
hwclock --systohc

# Set localization
echo "pt_BR.UTF-8 UTF-8" > /etc/locale.gen
locale-gen
echo "LANG=pt_BR.UTF-8" > /etc/locale.conf

# Make Keyboard changes persistent
echo "KEYMAP=${KEYBOARD}" > /etc/vconsole.conf

# Create the hostname file
echo "${HOST_NAME}" > /etc/hostname

echo "127.0.0.1	localhost.localdomain	localhost" > /etc/hosts
echo "::1		localhost.localdomain	localhost" >> /etc/hosts
echo "127.0.1.1	home01.localdomain	${HOST_NAME}" >> /etc/hosts

#TODO: Install grub

# Set the root password
passwd
