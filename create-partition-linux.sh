# Get first Disk from fdisk -l
HD="$(fdisk -l | grep -m 1 -oP "(?<=Disk /dev/)([^l][a-z]*)")"

# Automatic send keys to fdisk, create EFI partition, then Linux partition
sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << EOF | fdisk /dev/$HD
o # new DOS partition table
n # new partition
p # primary
1 # partition number 1
	# default, start immediately after preceding partition
	# default, extend partition to end of disk
a # togle bootable
p # print partition table
w # write the partition table
EOF
