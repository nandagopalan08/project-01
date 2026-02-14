import mysql.connector
import sys
import os

def init_db():
    print("--- Remote Database Updater ---")
    print("This script will connect to your VM's MySQL server and update the schema.")
    
    # Ask for VM IP
    host = input("Enter VM IP Address (e.g., 192.168.1.x) [Default: localhost]: ").strip()
    if not host:
        host = 'localhost'
        
    pwd = input("Enter VM MySQL 'root' Password [Default: root]: ").strip()
    if not pwd:
        pwd = 'root'
        
    config = {
        'host': host,
        'user': 'root',
        'password': pwd
    }
    
    print(f"Connecting to {host} as root...")
    
    try:
        conn = mysql.connector.connect(**config)
        print("Connected successfully!")
    except mysql.connector.Error as err:
        print(f"\n[ERROR] Could not connect to MySQL at {host}.")
        print(f"Details: {err}")
        print("\nTroubleshooting:")
        print("1. Ensure VM is running.")
        print("2. Ensure MySQL is running on VM (sudo systemctl status mysql).")
        print("3. Ensure VM firewall allows port 3306 (sudo ufw allow 3306).")
        print("4. Check if 'bind-address' in /etc/mysql/mysql.conf.d/mysqld.cnf is 0.0.0.0")
        return

    cursor = conn.cursor()
    
    try:
        # Read Setup SQL
        with open('database/setup.sql', 'r') as f:
            sql_script = f.read()
            
        # Split by ; to execute commands one by one
        # Improved splitting logic to avoid empty commands
        commands = sql_script.split(';')
        
        print(f"Executing SQL commands from database/setup.sql...")
        
        count = 0
        for command in commands:
            if command.strip():
                try:
                    cursor.execute(command)
                    count += 1
                except mysql.connector.Error as err:
                    # Ignore common errors like 'Table already exists' if script is re-runnable
                    if "already exists" in str(err):
                        pass
                    else:
                        print(f"Warning executing command: {err}")
                    
        conn.commit()
        print(f"Database update complete! Executed {count} commands.")
        
    except FileNotFoundError:
        print("Error: database/setup.sql not found. Are you in the project root?")
    except Exception as e:
        print(f"An error occurred: {e}")
    finally:
        cursor.close()
        conn.close()

if __name__ == '__main__':
    init_db()
