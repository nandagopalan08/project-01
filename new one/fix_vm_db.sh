#!/bin/bash

# VM Database Fix Script
# Run this inside the VM to fix connection issues by creating a dedicated admin user.

echo "--- Fixing MySQL Configuration ---"

# 1. Enable Remote Connections
CONF_FILE=$(find /etc/mysql -name "mysqld.cnf" | head -n 1)
if [ -z "$CONF_FILE" ]; then
    CONF_FILE="/etc/mysql/mysql.conf.d/mysqld.cnf"
fi

if [ -f "$CONF_FILE" ]; then
    echo "Updating bind-address in $CONF_FILE..."
    sudo sed -i 's/^#\?bind-address.*/bind-address = 0.0.0.0/' "$CONF_FILE"
    sudo sed -i 's/^#\?mysqlx-bind-address.*/mysqlx-bind-address = 0.0.0.0/' "$CONF_FILE"
fi

# 2. Restart MySQL to apply config
echo "Restarting MySQL Service..."
sudo systemctl restart mysql

# 3. Create Dedicated Admin User (Bypasses root plugin issues)
echo "Creating 'admin' user..."
sudo mysql -e "CREATE USER IF NOT EXISTS 'admin'@'%' IDENTIFIED BY 'admin123';"
sudo mysql -e "CREATE USER IF NOT EXISTS 'admin'@'localhost' IDENTIFIED BY 'admin123';"

# 4. Grant Privileges
echo "Granting privileges..."
sudo mysql -e "GRANT ALL PRIVILEGES ON *.* TO 'admin'@'%' WITH GRANT OPTION;"
sudo mysql -e "GRANT ALL PRIVILEGES ON *.* TO 'admin'@'localhost' WITH GRANT OPTION;"
sudo mysql -e "FLUSH PRIVILEGES;"

echo "--- Database Access Fixed ---"
echo "VM IP Address:"
hostname -I
echo "New Credentials:"
echo "User: admin"
echo "Pass: admin123"
