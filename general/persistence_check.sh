#!/bin/bash 

if [ $UID -ne 0 ]; then
	echo "Run this as root"
	exit 1
fi

#check for malicious users
echo -e "\033[32m[+] Printing login users\033[0m"
cat /etc/passwd | grep -i -v -E "/nologin"

#check for malicious groups
echo -e "\n\033[32m[+] Printing nondefault groups\033[0m"
cat /etc/group | grep -i -v -E "root|daemon|bin|sys|adm|tty|disk|lp|mail|news|uucp|man|proxy|kmem|dialout|fax|voice|cdrom|floppy|tape|sudo|audio|dip|www-data|backup|operator|list|irc|src|shadow|utmp|video|sasl|plugdev|staff|games|users|nogroup|ssl-cert|systemd-journal|systemd-network|crontab|systemd-timesync|Debian-exim|messagebus|lxc|lxd|ubuntu"

#check group memberships
echo -e "\n\033[32m[+] Printing group memberships\033[0m"
USERS=$(cat /etc/passwd | cut -d ":" -f 1)
for USER in $USERS; do
    groups $USER | grep --color=always -E "sudo|root|docker|lxc|lxd|wheel|disk|libvirt|libvirt-qemu|adm|shadow|tty|kmem|mem|kvm|netdev|pcap|systemd-journal|staff|$"
done

#check crons
echo -e "\n\033[32m[+] Listing system and user cron aentries\033[0m"
echo -n "System Crons:"
sed -E '/^(#|SHELL|PATH|\n)/d' /etc/crontab

echo -e "\nUser Crons:"
USER_CRONS=$(ls /var/spool/cron/crontabs)
for FILE in $USER_CRONS; do
        echo "${FILE}:"
        sed -E '/^(#|SHELL|PATH)/d' /var/spool/cron/crontabs/$FILE
done

#print manual checks just in case
echo -e "\nRun manual checks in other cron dirs:"
echo "ls -l /etc/cron.hourly"
echo "ls -l /etc/cron.daily"
echo "ls -l /etc/cron.weekly"
echo "ls -l /etc/cron.monthly"

#checking rc files for aliases
echo -e "\n\033[32m[+] Printing aliases in RC files\033[0m"
grep -E "alias" /home/*/.*rc
grep -E "alias" /root/.*rc

#enumerating for established connections
echo -e "\n\033[32m[+] Printing established connections\033[0m"
if which netstat 1>/dev/null; then
        netstat -tunap | grep -i "ESTABLISHED"
else
        ss -tunap | grep -i "ESTABLISHED"
fi

#enumerate logged on users
echo -e "\n\033[32m[+] Printing logged on users\033[0m"
w

#print out timed services
echo -e "\n\033[32m[+] Printing timed services\033[0m"
systemctl list-timers --no-pager

#print this out and manually check the pager
echo -e "\n\033[32m[+] Check services manually\033[0m"
echo -e "\n\033[32msystemctl list-timers\033[0m"

#processes
echo -e "\n\033[32m[+] Generating process commands file for manual review\033[0m"
ps aux > procs; cat procs | sed "1d" | tr -s " " | cut -d " " -f 11- | sort > cmds

#enumerating authorized_keys
echo -e "\n\033[32m[+] Checking Authorized keys\033[0m"
cat /home/*/.ssh/authorized_keys
cat /root/.ssh/authorized_keys
