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

install: language network updatetime

# Language Configurations -----------------------------------------------------
.PHONY: language
language:
	loadkeys br-abnt

# Network Configurations ------------------------------------------------------

# Set up network through DCHP
.PHONY: network
network:
	if link set ens0s0 up
	dhclient

# Enable auto update for time
.PHONY: updatetime
updatetime:
	timedatectl set ntp true

# Partititions ---------------------------------------------------------------

# Partitions
partitions:
	mkswap /dev/sda1
	swapon /dev/sda1
	mkfs.ext4 /dev/sda2

/mnt: partitions
	mount /dev/sda2 /mnt

# Install Packages -----------------------------------------------------------
# ref: https://wiki.archlinux.org/index.php/Pacman/Tips_and_tricks#Install_packages_from_a_list
.PHONY: installpackages
installpackages: files/pkglist.txt
	pacstrap /mnt base linux linux-firmware base-devel vim
	pacstrap /mnt -S --needed $(comm -12 <(pacman -Slq | sort) <(sort @<))
#	pacman -S --needed $(comm -12 <(pacman -Slq | sort) <(sort @<))

# Install Yay Helper
/mnt/tmp/yay:
	git clone https://aur.archlinux.org/yay.git /mnt/tmp/yay
	cd /mnt/tmp/yay && makepkg -si

# Configuration --------------------------------------------------------------

# Fstab
/mnt/etc/fstab:
	genfstab -U /mnt >> /mnt/etc/fstab

# Time Zone
/mnt/etc/localtime:
	arch-chroot /mnt ln -sf /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime

# Hardware Clock
/mnt/etc/adjtime:
	arch-chroot /mnt hwclock --systohc

# Localization
localization:
	arch-chroot /mnt sed /etc/locale.gen -i -e "s/^#\(pt_BR.*\)/\1/" -e "s/^#\(en_US.UTF-8.*\)/\1/"

/mnt/etc/locale.conf:
	arch-chroot /mnt echo "LANG=en_US.UTF-8" > /mnt/etc/locale.conf

# Grub
grub:
	arch-chroot /mnt grub-install --target=i386-pc /dev/sda
	arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg

# Lxdm + i3wm
lxdm:
	pacstrap /mnt lxdm i3-wm i3status
	arch-chroot /mnt sed /etc/lxdm/lxdm.conf -i -e "s+^#\(session*\)+session=/usr/bin/i3+"
	arch-chroot systemctl enable lxdm
