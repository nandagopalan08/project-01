import mysql.connector
import sys
import os

# Configuration for the helper script
# This script runs on the HOST machine (Windows) and connects to the VM (Lubuntu)

def setup_database():
    print("==========================================")
    print("   HOST -> VM DATABASE SETUP UTILITY      ")
    print("==========================================")
    print("This script connects to your VM's MySQL server to apply the NEW schema.")
    print("Ensure your VM is running and you know its IP address.")
    print("==========================================")

    # 1. Get VM Details
    vm_ip = input("Enter VM IP Address (e.g. 192.168.1.13): ").strip()
    if not vm_ip:
        print("Error: IP Address is required.")
        return

    # 2. Connection Config
    config = {
        'host': vm_ip,
        'user': 'admin',      # We are using the 'admin' user created by reinit_db.sh
        'password': 'admin123',
        'autocommit': True
    }
    
    print(f"\n[*] Attempting to connect to MySQL at {vm_ip}...")

    conn = None
    try:
        conn = mysql.connector.connect(**config)
        print("[SUCCESS] Connected to VM Database!")
    except mysql.connector.Error as err:
        print(f"\n[ERROR] Connection Failed: {err}")
        print("\nPossible Causes:")
        print("1. **MySQL isn't configured to allow remote connections**.")
        print("   -> Did you run 'bash database/reinit_db.sh' INSIDE the VM?")
        print("2. **Firewall Blocking**.")
        print("   -> Run 'sudo ufw allow 3306' inside the VM.")
        print("3. **Wrong IP or Network**.")
        print("   -> Run 'hostname -I' inside VM to confirm IP.")
        print("   -> Try 'ping <vm_ip>' from this terminal.")
        return

    # 3. Read and Execute SQL
    cursor = conn.cursor()
    try:
        print("\n[*] Reading 'database/setup.sql'...")
        with open('database/setup.sql', 'r') as f:
            sql_script = f.read()

        # Split by command (simple split by ';')
        commands = sql_script.split(';')
        
        print(f"[*] Executing Schema on {vm_ip}...")
        
        # We need to handle multi-statements or just execute one by one
        success_count = 0
        for cmd in commands:
            if cmd.strip():
                try:
                    cursor.execute(cmd)
                    success_count += 1
                except mysql.connector.Error as err:
                    # Ignore harmless warnings about things not existing during DROP
                    if "Unknown table" in str(err) or "Can't drop database" in str(err):
                        pass
                    else:
                        print(f"   [Warning] {err}")
        
        print(f"\n[SUCCESS] Database setup complete! {success_count} commands executed.")
        print("Now you can run the applications.")

    except FileNotFoundError:
        print("[ERROR] Could not find 'database/setup.sql'.")
    except Exception as e:
        print(f"[ERROR] An unexpected error occurred: {e}")
    finally:
        if conn:
            conn.close()
            print("\n[INFO] Connection closed.")

if __name__ == '__main__':
    setup_database()
