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

# Install Packages -----------------------------------------------------------
# ref: https://wiki.archlinux.org/index.php/Pacman/Tips_and_tricks#Install_packages_from_a_list
.PHONY: installpackages
installpackages: files/pkglist.txt
	pacstrap /mnt base linux linux-firmware base-dev
	pacstrap /mnt -S --needed $(comm -12 <(pacman -Slq | sort) <(sort @<))
#	pacman -S --needed $(comm -12 <(pacman -Slq | sort) <(sort @<))

# Install Yay Helper
/mnt/tmp/yay:
	git clone https://aur.archlinux.org/yay.git $@
	cd $@ && makepkg -si



