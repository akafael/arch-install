##
# Arch Instalation Description as Makefile
#
# @author Rafael
##

###############################################################################
# Variables
###############################################################################
# Enable Source Command
SHELL := /bin/zsh

# Get Makefile directory
ROOT_DIR:=$(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))

# System Configurations
MACHINE_NAME := hal

###############################################################################
# Rules
###############################################################################

install: language network updatetime partitions installpackages fstab localization grub

# Language Configurations -----------------------------------------------------
.PHONY: language
language:
	loadkeys br-abnt

# Network Configurations ------------------------------------------------------

# Set up network through DCHP
.PHONY: network
network:
	if link set $(ip link | sed -n -e "s/2: \([a-z0-9]*\):.*/\1/p") up
	dhclient

# Enable auto update for time
.PHONY: updatetime
updatetime:
	timedatectl set-ntp true

# Partitions
.PHONY: partitions
partitions: /mnt
/mnt:
	parted /dev/sda mklabel gpt \
		mkpart primary ext4 1MiB 4MiB set 1 bios_grub on\
		mkpart primary linux-swap 4MiB 4GiB set 2 swap on\
		mkpart primary ext4 4GiB 100% set 3 boot on
	mkswap /dev/sda2
	swapon /dev/sda2
	mkfs.ext4 /dev/sda3
	mount /dev/sda3 /mnt

# Install Packages -----------------------------------------------------------
# ref: https://wiki.archlinux.org/index.php/Pacman/Tips_and_tricks#Install_packages_from_a_list
.PHONY: installpackages
installpackages: /mnt network
	pacstrap /mnt base linux-hardened linux-firmware base-devel vim arduino i3-wm i3status terminator git grub xorg lightdm intel-ucode amd-ucode
#	pacstrap /mnt -S --needed $(comm -12 <(pacman -Slq | sort) <(sort @<))
#	pacman -S --needed $(comm -12 <(pacman -Slq | sort) <(sort @<))

# Install Yay Helper
yay:
	git clone https://aur.archlinux.org/yay.git /mnt/tmp/yay
	cd /mnt/tmp/yay && makepkg -si

# Configuration ---------------------------------------------------------------

# Fstab
fstab: /mnt
	genfstab -U /mnt >> /mnt/etc/fstab

# Time
timeset: /mnt
	arch-chroot /mnt ln -sf /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime
	arch-chroot /mnt hwclock --systohc

# Localization
.PHONY: localization
localization: /mnt
	arch-chroot /mnt sed /etc/locale.gen -i -e "s/^#\(pt_BR.*\)/\1/" -e "s/^#\(en_US.UTF-8.*\)/\1/"
	arch-chroot /mnt locale-gen
	arch-chroot /mnt echo "LANG=en_US.UTF-8" > /mnt/etc/locale.conf
	arch-chroot /mnt echo "KEYMAP=br-abnt" > /mnt/etc/vconsole.conf
 
# Grub
.PHONY: grub
grub: /mnt installpackages 
	arch-chroot /mnt grub-install --target=i386-pc /dev/sda
	arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg


