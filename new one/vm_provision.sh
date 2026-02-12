#!/bin/bash

# VM Provisioning Script for Lubuntu/Ubuntu
# Run this script inside the VM to set up the environment.

echo "--- Updating Package Lists ---"
sudo apt-get update

echo "--- Installing Python and MySQL ---"
sudo apt-get install -y python3 python3-pip python3-venv mysql-server libmysqlclient-dev pkg-config

echo "--- Configuring MySQL ---"
# Start MySQL Service
sudo systemctl start mysql
sudo systemctl enable mysql

# Secure MySQL (Simulated - setting root pass to 'root')
# Allow remote root login (ONLY FOR LAB ENVIRONMENT)
sudo mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'root';"
sudo mysql -e "CREATE USER IF NOT EXISTS 'root'@'%' IDENTIFIED WITH mysql_native_password BY 'root';"
sudo mysql -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION;"
sudo mysql -e "FLUSH PRIVILEGES;"

# Allow remote connections in my.cnf
# By default, MySQL binds to 127.0.0.1. We need to comment out bind-address or set to 0.0.0.0
CONF_FILE=$(find /etc/mysql -name "mysqld.cnf" | head -n 1)
if [ -z "$CONF_FILE" ]; then
    CONF_FILE="/etc/mysql/mysql.conf.d/mysqld.cnf"
fi

echo "Modifying MySQL Config at $CONF_FILE to allow remote connections..."
sudo sed -i 's/bind-address.*/bind-address = 0.0.0.0/' "$CONF_FILE"
sudo systemctl restart mysql

echo "--- Setting up Database Schema ---"
# Check if database/setup.sql exists
if [ -f "database/setup.sql" ]; then
    sudo mysql -u root -proot < database/setup.sql
    echo "Database Schema applied successfully."
else
    echo "ERROR: database/setup.sql not found! Please ensure you copied the 'database' folder."
    exit 1
fi

echo "--- Installing Python Requirements ---"
if [ -f "requirements.txt" ]; then
    pip3 install -r requirements.txt --break-system-packages
else
    echo "ERROR: requirements.txt not found!"
    exit 1
fi

echo "--- Setup Complete ---"
echo "To start the Vulnerable App, run:"
echo "python3 vulnerable_app/app.py"
echo ""
echo "Note the VM IP Address:"
hostname -I
