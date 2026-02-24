#!/bin/bash

if [ $UID -ne 0 ]; then
	echo Run this script as root
	exit 1
fi

echo "[+] Checking for internet access"
if ping -c 1 -W 5 8.8.8.8 >/dev/null 2>&1; then
    echo "Access confirmed"
    is_online=true
else
    echo "No internet access"
    is_online=false
fi

#sanity
apt install apache2 -y && apt upgrade apache2 -y
chown -R root:www-data /var/www/html
chmod -R 755 /var/www/html

#ufw
ufw enable
ufw default deny incoming
ufw default allow outgoing
ufw allow from 0.0.0.0/0 to any port 443 proto tcp 
ufw allow from 0.0.0.0/0 to any port 80 proto tcp 
sed -i '/IPV6=yes/s/.*/IPV6=no/' filename.txt




systemctl restart nginx
echo "test if modsecurity works, curl http://127.0.0.1?q=<script>alert(1);</script> results in 403"
echo "try restarting your machine now"
