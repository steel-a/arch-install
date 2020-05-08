# Get first Disk from fdisk -l
HD="$(fdisk -l | grep -m 1 -oP "(?<=Disk /dev/)([^l][a-z]*)")"

# Automatic send keys to fdisk, create EFI partition, then Linux partition
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
p # print partition table
w # write the partition table
EOF	

HD_EFI="${HD}1"
HD_LINUX="${HD}2"

# Format Partitions
mkfs.fat -F32 /dev/$HD_EFI
mkfs.ext4 /dev/$HD_LINUX

# Mount Partitions
mount /dev/$HD_LINUX /mnt
mount /dev/$HD_EFI /mnt/boot
