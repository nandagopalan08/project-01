#!/bin/bash

# ==========================================
# VM PROVISIONING SCRIPT (STABLE VERSION)
# ==========================================

echo "[*] Updating system packages..."
sudo apt-get update -y

echo "[*] Installing Python, MySQL, and dependencies..."
sudo apt-get install -y python3 python3-pip python3-venv mysql-server ufw

echo "[*] Configuring MySQL for Remote Access..."
# Fix MySQL bind-address to allow external connections
CONF_FILE="/etc/mysql/mysql.conf.d/mysqld.cnf"
if [ ! -f "$CONF_FILE" ]; then
    CONF_FILE="/etc/mysql/my.cnf"
fi

sudo sed -i 's/bind-address.*/bind-address = 0.0.0.0/' "$CONF_FILE"
sudo systemctl restart mysql

echo "[*] Initializing Database & User (project_user)..."
# We use the simplified IDENTIFIED BY to avoid plugin conflicts (mysql_native_password vs caching_sha2_password)
sudo mysql <<EOF
CREATE DATABASE IF NOT EXISTS vulnerable_db;
-- Create project_user if not exists
CREATE USER IF NOT EXISTS 'project_user'@'%' IDENTIFIED BY 'project123';
CREATE USER IF NOT EXISTS 'project_user'@'localhost' IDENTIFIED BY 'project123';
-- Reset password and ensure no plugin conflicts
ALTER USER 'project_user'@'%' IDENTIFIED BY 'project123';
ALTER USER 'project_user'@'localhost' IDENTIFIED BY 'project123';
GRANT ALL PRIVILEGES ON *.* TO 'project_user'@'%' WITH GRANT OPTION;
GRANT ALL PRIVILEGES ON *.* TO 'project_user'@'localhost' WITH GRANT OPTION;
FLUSH PRIVILEGES;
EOF

echo "[*] Applying Schema from setup.sql..."
if [ -f "database/setup.sql" ]; then
    sudo mysql vulnerable_db < database/setup.sql
    echo "[+] Schema applied successfully."
else
    echo "[-] Warning: database/setup.sql not found."
fi

echo "[*] Configuring Firewall (UFW)..."
sudo ufw allow 3306/tcp  # MySQL
sudo ufw allow 5000/tcp  # Vulnerable App
sudo ufw allow 22/tcp    # SSH
echo "y" | sudo ufw enable

echo "[*] Installing Python requirements..."
if [ -f "requirements.txt" ]; then
    pip3 install -r requirements.txt --break-system-packages
fi

echo "=========================================="
echo " PROVISIONING COMPLETE"
echo "=========================================="
echo "Database IP: $(hostname -I | awk '{print $1}')"
echo "User: project_user"
echo "Pass: project123"
echo "Port: 3306"
echo "=========================================="
