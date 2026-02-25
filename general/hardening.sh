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
sudo apt install tmux #add tmux
sudo apt install ssh #add ssh

#add backup user
adduser backup_user

#basic ssh config
sed -i 's/^#*PermitRootLogin .*/PermitRootLogin no/' /etc/ssh/sshd_config
systemctl enable ssh || systemctl enable sshd

#just in case
systemctl start ssh || systemctl start sshd
systemctl restart ssh || systemctl restart sshd

#make sure we have no ssh key
rm /root/.ssh/authorized_keys
rm /home/*/.ssh/authorized_keys
