#!/bin/bash

if [ $UID -ne 0 ]; then
    echo "Run this script as root"
    exit 1
fi

read -p "Hit enter if you have already changed the appropriate config, if not exit: " TMP

# VARIABLES
WEBROOT="/var/www/html"
WEBSITE_DOMAIN="test.com"
ACME_URL="https://ca.ncaecybergames.org/acme/acme/directory"

echo "[+] Checking for internet access"
if ping -c 1 -W 5 8.8.8.8 >/dev/null 2>&1; then
    echo "Access confirmed"
    is_online=true
else
    echo "No internet access"
    is_online=false
fi

# Initial backup
echo "[+] Creating initial backup"
tar -cvf initial_nginx.tar $WEBROOT /etc/nginx

# Install / Upgrade nginx
echo "[+] Installing nginx"
apt update -y
apt install nginx -y
apt upgrade nginx -y

# Permissions hardening
echo "[+] Hardening webroot permissions"
chown -R root:www-data $WEBROOT
chmod -R 755 $WEBROOT

# UFW Configuration
echo "[+] Configuring firewall"
ufw --force enable
ufw default deny incoming
ufw default allow outgoing
ufw allow 443/tcp
ufw allow 80/tcp
ufw allow 22/tcp
sed -i '/IPV6=yes/s/.*/IPV6=no/' /etc/default/ufw

# Install & Configure ModSecurity for NGINX
if $is_online; then
    echo "[+] Installing ModSecurity for NGINX"

    apt install -y libnginx-mod-http-modsecurity git

    # Enable ModSecurity
    mkdir -p /etc/nginx/modsec
    cp /etc/modsecurity/modsecurity.conf-recommended /etc/nginx/modsec/modsecurity.conf
    sed -i 's/SecRuleEngine DetectionOnly/SecRuleEngine On/' /etc/nginx/modsec/modsecurity.conf

    # Install OWASP CRS
    git clone https://github.com/coreruleset/coreruleset
    rm -rf /etc/nginx/modsec/coreruleset
    mv coreruleset /etc/nginx/modsec/
    mv /etc/nginx/modsec/coreruleset/crs-setup.conf.example \
       /etc/nginx/modsec/coreruleset/crs-setup.conf

    # Create main modsec config loader
    cat <<EOF > /etc/nginx/modsec/main.conf
Include /etc/nginx/modsec/modsecurity.conf
Include /etc/nginx/modsec/coreruleset/crs-setup.conf
Include /etc/nginx/modsec/coreruleset/rules/*.conf
EOF

    # Enable in nginx.conf if not already enabled
    if ! grep -q "modsecurity on;" /etc/nginx/nginx.conf; then
        sed -i '/http {/a \    modsecurity on;\n    modsecurity_rules_file /etc/nginx/modsec/main.conf;' /etc/nginx/nginx.conf
    fi
fi

# Replace default site config
echo "[+] Deploying hardened nginx config"

cp config_files/nginx-default.conf /etc/nginx/sites-available/default
sed -i "s|SERVER_NAME_REPLACE|${WEBSITE_DOMAIN}|" /etc/nginx/sites-available/default

# Certbot
if $is_online; then
    echo "[+] Installing Certbot"

    if ! which certbot >/dev/null 2>&1; then
        apt install snapd -y
        snap install core
        snap refresh core
        snap install --classic certbot
    fi

    certbot --nginx --server $ACME_URL --no-random-sleep-on-renew -d $WEBSITE_DOMAIN
fi

# Test config before restart
echo "[+] Testing nginx config"
nginx -t

# Final backup
echo "[+] Creating final backup"
tar -cvf final_nginx.tar $WEBROOT /etc/nginx

# Restart
systemctl restart nginx

echo "Test modsecurity:"
echo "curl http://127.0.0.1?q=<script>alert(1);</script>"
echo "Should return 403 if working."

echo "Hardening complete. Consider rebooting."
