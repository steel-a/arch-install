# Prerequisites: Computer must be connected to Internet via cable.

# Configure the following variables:
KEYBOARD="us-acentos"
REGION="America"
CITY="Sao_Paulo"
HOST_NAME="home01"
SWAP_SIZE="2048M"
WORK_USER="mi"
WORK_USER_UID="1000"
SSH_PORT="63169"


PROJ_PATH="https://raw.githubusercontent.com/steel-a/arch-install/master/"

# Get first Disk from fdisk -l
HD="$(fdisk -l | grep -m 1 -oP "(?<=Disk /dev/)([^l][a-z0-9]*)")"

# If install.txt exists, we are into installation environment
FILE="./install.txt"
if test -f "$FILE"; then

	# Verify the boot mode, if efivars directory exists, boot mode = EFI
	DIR="/sys/firmware/efi/efivars/"
	if [ -d "$DIR" ]; then
		if [[ $HD == *"mmcblk"* ]]; then
			HD_EFI="${HD}p1"
			HD_LINUX="${HD}p2"
		else
			HD_EFI="${HD}1"
			HD_LINUX="${HD}2"
		fi
		wget ${PROJ_PATH}create-partitions-boot-linux.sh
		chmod 700 create-partitions-boot-linux.sh
		./create-partitions-boot-linux.sh
		yes | mkfs.fat -F32 /dev/$HD_EFI
		yes | mkfs.ext4 /dev/$HD_LINUX
		mount /dev/$HD_LINUX /mnt
		mkdir /mnt/boot
		mkdir /mnt/boot/efi
		mount /dev/$HD_EFI /mnt/boot/efi
	else
		if [[ $HD == *"mmcblk"* ]]; then
			HD_LINUX=${HD}p1
		else
			HD_LINUX=${HD}1
		fi
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
	pacstrap /mnt base linux-lts
	#linux-firmware not installed

	# Generate fstab
	genfstab -U /mnt > /mnt/etc/fstab

	# Change root into the new system
	cp ./01-base.sh /mnt/root/01-base.sh
	arch-chroot /mnt /root/01-base.sh
	rm /mnt/root/01-base.sh

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
	echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
	locale-gen
	echo "LANG=en_US.UTF-8" > /etc/locale.conf

	# Make Keyboard changes persistent
	echo "KEYMAP=${KEYBOARD}" > /etc/vconsole.conf

	# Create the hostname file
	echo "${HOST_NAME}" > /etc/hostname

	echo "127.0.0.1	localhost.localdomain	localhost" > /etc/hosts
	echo "::1		localhost.localdomain	localhost" >> /etc/hosts
	echo "127.0.1.1	home01.localdomain	${HOST_NAME}" >> /etc/hosts

	# Create new user
	useradd -m -g users -G wheel -u $WORK_USER_UID $WORK_USER
	yes | pacman -S sudo
	echo "${WORK_USER} ALL=(ALL) ALL" >> /etc/sudoers

	#Install grub
	DIR="/boot/efi/"
	if [ -d "$DIR" ]; then
		yes | pacman -S grub-efi-x86_64 efibootmgr
		grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=arch_grub --recheck
	else
		yes | pacman -S grub
		grub-install --target=i386-pc --recheck /dev/${HD}
	fi
	cp /usr/share/locale/en\@quot/LC_MESSAGES/grub.mo /boot/grub/locale/en.mo
	grub-mkconfig -o /boot/grub/grub.cfg
	
	# Install DHCPCD
	yes | pacman -S dhcpcd
	systemctl enable dhcpcd
	
	# Install OpenSSH
	yes | pacman -S openssh
	sed -i 's/#PermitRootLogin /PermitRootLogin /g' /etc/ssh/sshd_config
	sed -i 's/PermitRootLogin yes/PermitRootLogin no/g' /etc/ssh/sshd_config
	sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin no/g' /etc/ssh/sshd_config
	echo "Port ${SSH_PORT}" >> /etc/ssh/sshd_config
	echo "Protocol 2" >> /etc/ssh/sshd_config
	echo "AllowUsers ${WORK_USER}" >> /etc/ssh/sshd_config
	echo "MaxStartups 3" >> /etc/ssh/sshd_config
	systemctl enable sshd
	
	# Install Docker
	yes | pacman -S docker
	systemctl enable docker
	
	# Set the root and other user passwords
	clear
	echo "Set password for root user"
	passwd
	clear
	echo "Set password for ${WORK_USER} user"
	passwd $WORK_USER
fi
