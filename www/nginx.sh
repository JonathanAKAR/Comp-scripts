#!/bin/bash

if [ $UID -ne 0 ]; then
    echo "Run this script as root"
    exit 1
fi

read -p "Hit enter if you have already changed the appropriate config, if not exit: " TMP

WEBROOT="/var/www/html"
WEBSITE_DOMAIN="test.com"

echo "[+] Checking for internet access"
if ping -c 1 -W 5 8.8.8.8 >/dev/null 2>&1; then
    echo "Access confirmed"
    is_online=true
else
    echo "No internet access"
    is_online=false
fi

########################################
# Backup initial state
########################################
echo "[+] Creating initial backup"
tar -cvf initial_app.tar $WEBROOT /etc/nginx

########################################
# Install Nginx
########################################
echo "[+] Installing nginx"
apt update -y
apt install nginx -y
apt upgrade nginx -y

chown -R root:www-data $WEBROOT
chmod -R 755 $WEBROOT

########################################
# Firewall configuration
########################################
echo "[+] Configuring firewall"
ufw --force enable
ufw default deny incoming
ufw default allow outgoing
ufw allow 443/tcp
ufw allow 80/tcp
ufw allow 22/tcp
sed -i '/IPV6=yes/s/.*/IPV6=no/' /etc/default/ufw

########################################
# ModSecurity for Nginx
########################################
if $is_online; then
    echo "[+] Installing ModSecurity for nginx"

    apt update
    apt install -y libmodsecurity3 libnginx-mod-http-modsecurity git

    # Create modsec directory
    mkdir -p /etc/nginx/modsec

    # Copy your custom modsecurity config
    cp config_files/modsecurity.conf-recommended \
       /etc/nginx/modsec/modsecurity.conf

    # Ensure blocking mode
    sed -i 's/SecRuleEngine DetectionOnly/SecRuleEngine On/' \
       /etc/nginx/modsec/modsecurity.conf

    # Create audit log
    touch /var/log/nginx/modsec_audit.log
    chown www-data:www-data /var/log/nginx/modsec_audit.log
    chmod 640 /var/log/nginx/modsec_audit.log

    # Install OWASP CRS
    cd /etc/nginx/modsec
    git clone https://github.com/coreruleset/coreruleset.git crs

    cp /etc/nginx/modsec/crs/crs-setup.conf.example \
       /etc/nginx/modsec/crs/crs-setup.conf

    # Create or copy main.conf
    if [ -f config_files/main.conf ]; then
        cp config_files/main.conf /etc/nginx/modsec/main.conf
    else
        cat <<EOF > /etc/nginx/modsec/main.conf
Include /etc/nginx/modsec/modsecurity.conf
Include /etc/nginx/modsec/crs/crs-setup.conf
Include /etc/nginx/modsec/crs/rules/*.conf
EOF
    fi

    # Enable ModSecurity globally in nginx.conf (only if not already present)
    if ! grep -q "modsecurity on;" /etc/nginx/nginx.conf; then
        sed -i '/http {/a \
    modsecurity on;\n\
    modsecurity_rules_file /etc/nginx/modsec/main.conf;\n' \
        /etc/nginx/nginx.conf
    fi

    # Deploy nginx site config (your reverse proxy config)
    cp config_files/default /etc/nginx/sites-available/default

    # Ensure site is enabled
    ln -sf /etc/nginx/sites-available/default \
           /etc/nginx/sites-enabled/default

    # Test and restart nginx
    nginx -t && systemctl restart nginx

    echo "[+] ModSecurity + OWASP CRS successfully installed."
fi

########################################
# Nginx Site Config
########################################
echo "[+] Creating nginx site configuration"

cat > /etc/nginx/sites-available/default <<EOF
server {
    listen 80;
    server_name ${WEBSITE_DOMAIN};

    root ${WEBROOT};
    index index.html index.htm index.php;

    # Enable ModSecurity
    modsecurity on;
    modsecurity_rules_file /etc/nginx/modsec/modsecurity.conf;

    location / {
        try_files \$uri \$uri/ =404;
    }

    # Reverse proxy example (edit if needed)
    location /proxy/ {
        proxy_pass http://127.0.0.1:8080;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
}
EOF

########################################
# Disable IPv6 in nginx
########################################
sed -i 's/listen \[::\]:80 default_server;/#listen [::]:80 default_server;/' /etc/nginx/sites-available/default

########################################
# Test & Restart
########################################
nginx -t && systemctl restart nginx
systemctl restart ufw

########################################
# Final Backup
########################################
echo "[+] Creating final backup"
tar -cvf final_app.tar $WEBROOT /etc/nginx

echo "Test ModSecurity:"
echo 'curl "http://127.0.0.1/?q=<script>alert(1);</script>"'
echo "Should return 403 if working."
