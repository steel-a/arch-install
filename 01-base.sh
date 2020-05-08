# List of variables

#Connected via cable
KEYBOARD="us-acentos"
REGION="America"
CITY="Sao_Paulo"
HOST_NAME="home01"
SWAP_SIZE="2048M"
WORK_USER="mi"

PROJ_PATH="https://raw.githubusercontent.com/steel-a/arch-install/master/"

# Get first Disk from fdisk -l
HD="$(fdisk -l | grep -m 1 -oP "(?<=Disk /dev/)([^l][a-z]*)")"

# If install.txt exists, we are into installation environment
FILE="./install.txt"
if test -f "$FILE"; then

	# Verify the boot mode, if efivars directory exists, boot mode = EFI
	DIR="/sys/firmware/efi/efivars/"
	if [ -d "$DIR" ]; then
		GRUB_INSTALL_COMMAND="pacman -Sy grub-efi-x86_64 efibootmgr"
		GRUB_INSTALL_COMMAND2="grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=arch_grub --recheck"
		HD_EFI="${HD}1"
		HD_LINUX="${HD}2"
		wget ${PROJ_PATH}create-partitions-boot-linux.sh
		chmod 700 create-partitions-boot-linux.sh
		./create-partitions-boot-linux.sh
		yes | mkfs.fat -F32 /dev/$HD_EFI
		yes | mkfs.ext4 /dev/$HD_LINUX
		mount /dev/$HD_LINUX /mnt
		mkdir /mnt/boot
		mkdir /mnt/boot/efi
		mount /dev/$HD_EFI /mnt/boot
	else
		GRUB_INSTALL_COMMAND="pacman -Sy grub"
		GRUB_INSTALL_COMMAND2="grub-install --target=i386-pc /dev/${HD}"
		HD_LINUX=${HD}1
		wget ${PROJ_PATH}create-partition-linux.sh
		chmod 700 create-partition-linux.sh
		./create-partition-linux.sh
		yes | mkfs.ext4 /dev/$HD_LINUX
		mount /dev/$HD_LINUX /mnt
	fi

	# Atualizar relógio do sistema
	timedatectl set-ntp true

	# Edit mirros /etc/pacman.d/mirrorlist

	# Install LTS with NO FIRMWARE
	pacstrap /mnt base linux-lts linux-firmware

	# Generate fstab
	genfstab -U /mnt > /mnt/etc/fstab

	# Change root into the new system
	cp ./01-base.sh /mnt/root/01-base.sh
	arch-chroot /mnt /root/01-base.sh

else # If install.txt does not exists, we are at the new installed environment

	# Create swapfile
	fallocate -l ${SWAP_SIZE} /swapfile
	ls -lh /swapfile
	chmod 600 /swapfile
	mkswap /swapfile
	swapon /swapfile
	echo "/swapfile	none	swap	defaults	0	0" >> /etc/fstab

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

	# Create new user
	useradd -m -g users -G wheel $WORK_USER
	pacman -Sy sudo
	echo "mi ALL=(ALL) ALL" >> /etc/sudoers

	#Install grub
	sh $GRUB_INSTALL_COMMAND
	sh $GRUB_INSTALL_COMMAND2

	# Set the root password
	passwd
	passwd $WORK_USER
fi
