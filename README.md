I used this script to install the base of Arch Linux with Kernel LTS + openssh + docker on some personal servers automatically.

The script installs the system on the first disk found by the fdisk -l command

The servers on which I installed have the following characteristics:
- EFI Boot
- MMC disk (mmcblk0)
- In this case the script created a GPT system with partitions mmcblk0p1 (/ boot / EFI) and mmcblk0p2 (/)

I also tested it on a virtual machine without EFI. In this case the script created a DOS system with only the sda1 partition.

The swap is done on a disk file.

I need to alert that the script worked for my servers but it is still in an initial stage where the commands are just typed, without checking the returns.

Instructions:
- boot with the arch linux image
- wget https://raw.githubusercontent.com/steel-a/arch-install/master/01-base.sh
- chmod 700 01-base.sh
- ./base-01.sh
