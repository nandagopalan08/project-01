#!/bin/bash

# VM Database Repair Script
# Run this script INSIDE your VM if the web app cannot connect to database.

echo "--- Stopping MySQL ---"
sudo systemctl stop mysql

echo "--- Starting MySQL in Safe Mode (Skip Grants) ---"
sudo mysqld_safe --skip-grant-tables & 
PID=$!
sleep 5

echo "--- Resetting Root Password ---"
mysql -u root <<EOF
FLUSH PRIVILEGES;
ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'root';
ALTER USER 'root'@'%' IDENTIFIED WITH mysql_native_password BY 'root';
FLUSH PRIVILEGES;
EOF

echo "--- Stopping Safe Mode ---"
kill $PID
sleep 5

echo "--- Restarting MySQL Service ---"
sudo systemctl start mysql

echo "--- Applying Database Schema ---"
if [ -f "/vagrant/database/setup.sql" ]; then
    sudo mysql -u root -proot < /vagrant/database/setup.sql
    echo "Database schema updated successfully!"
elif [ -f "database/setup.sql" ]; then
    sudo mysql -u root -proot < database/setup.sql
    echo "Database schema updated successfully!"
else
    echo "ERROR: Could not find database/setup.sql file."
fi

echo "--- Done! ---"
echo "Restart your python app now."
