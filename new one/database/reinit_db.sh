#!/bin/bash
# SAVE THIS FILE AS reinit_db.sh ON YOUR VM AND RUN IT
# Usage: bash reinit_db.sh

echo "=========================================="
echo "   RE-INITIALIZING DATABASE ON VM         "
echo "=========================================="

# 1. Ensure MySQL is running
echo "[*] Restarting MySQL Service..."
sudo systemctl restart mysql

# 2. Configure Bind Address to allow remote connections
# Check if we need to modify the config
if grep -q "bind-address.*=.*127.0.0.1" /etc/mysql/mysql.conf.d/mysqld.cnf; then
    echo "[*] Updating bind-address to 0.0.0.0 for remote access..."
    sudo sed -i 's/^bind-address.*/bind-address = 0.0.0.0/' /etc/mysql/mysql.conf.d/mysqld.cnf
    sudo systemctl restart mysql
fi
# Also checking alternate location just in case
if [ -f /etc/mysql/my.cnf ]; then
     sudo sed -i 's/^bind-address.*/bind-address = 0.0.0.0/' /etc/mysql/my.cnf
fi

# 3. Create/Reset 'admin' user with Native Password 
# This is crucial for fixing the 'plugin not loaded' error and 1130 error
echo "[*] Resetting 'admin' user permissions..."

sudo mysql -u root <<EOF
-- Drop user if exists to start fresh
DROP USER IF EXISTS 'admin'@'%';
DROP USER IF EXISTS 'admin'@'localhost';

-- Create admin user accessible from ANY IP (%)
-- Identified with mysql_native_password for compatibility
CREATE USER 'admin'@'%' IDENTIFIED WITH mysql_native_password BY 'admin123';
CREATE USER 'admin'@'localhost' IDENTIFIED WITH mysql_native_password BY 'admin123';

-- Grant Full Privileges
GRANT ALL PRIVILEGES ON *.* TO 'admin'@'%' WITH GRANT OPTION;
GRANT ALL PRIVILEGES ON *.* TO 'admin'@'localhost' WITH GRANT OPTION;

FLUSH PRIVILEGES;
EOF

# 4. Run the Schema Setup
echo "[*] Applying Database Schema (database/setup.sql)..."
if [ -f "database/setup.sql" ]; then
    # Use the new admin user to run the script to verify credentials work
    mysql -u admin -padmin123 < database/setup.sql
    if [ $? -eq 0 ]; then
        echo "[SUCCESS] Database initialized successfully."
    else
        echo "[ERROR] Failed to run setup.sql with admin user."
    fi
else
    echo "[ERROR] database/setup.sql not found in current directory."
fi

echo "=========================================="
echo "   SETUP COMPLETE"
echo "=========================================="
echo "Your Database Credentials:"
echo "User: admin"
echo "Pass: admin123"
echo "Host: (Run 'hostname -I' to see your IP)"
