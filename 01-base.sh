# List of variables

#Connected via cable
KEYBOARD="us-acentos"
REGION="America"
CITY="Sao_Paulo"
HOST_NAME="home01"
SWAP_SIZE="2048M"

# Get first Disk from fdisk -l
HD="$(fdisk -l | grep -m 1 -oP "(?<=Disk /dev/)([^l][a-z]*))"

# Atualizar relógio do sistema
timedatectl set-ntp true

# Verify the boot mode, if efivars directory exists, boot mode = EFI
DIR="/sys/firmware/efi/efivars/"
if [ -d "$DIR" ]; then
	HD_EFI="${HD}1
	HD_LINUX=${HD}2

	sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << EOF | fdisk /dev/$HD
	g # new GPT partition table
	n # new partition
	1 # partition number 1
		# default - start at beginning of disk 
	+512M # 512 MB boot parttion
	t # chose type
	1 # type EFI
	n # new partition
	2 # partion number 2
		# default, start immediately after preceding partition
		# default, extend partition to end of disk
	w # write the partition table
	EOF	

	read p

	mkfs.fat -F32 /dev/$HD_EFI
	mkfs.ext4 /dev/$HD_LINUX
	mount /dev/$HD_LINUX /mnt
	mount /dev/$HD_EFI /mnt/boot
else
	HD_LINUX=${HD}1

	sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << EOF | fdisk /dev/$HD
	g # new GPT partition table
	n # new partition
	1 # partition number 1
		# default - start at beginning of disk 
		# default, start immediately after preceding partition
	w # write the partition table
	EOF	

	read p

	mkfs.ext4 /dev/$HD_LINUX
	mount /dev/$HD_LINUX /mnt
	exit 1
fi



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
