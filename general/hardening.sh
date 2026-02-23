#!/bin/bash


if [ $UID -ne 0 ]; then
	echo "Script must be run as root"
	exit 1
fi

#basic stuff - Comment out if no network access yet
sudo apt update -y
sudo apt upgrade -y
sudo apt full-upgrade -y
sudo apt install ufw -y #add ufw
sudo apt install git -y #add git

#make sure we have no ssh key
rm /root/.ssh/authorized_keys
rm /home/*/.ssh/authorized_keys
