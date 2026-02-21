import mysql.connector
import sys
import os

def setup_database():
    print("==========================================")
    print("   HOST -> VM DATABASE UPDATE UTILITY     ")
    print("==========================================")
    print("Connecting as ROOT to apply the correct schema.")

    # 1. Get VM Details
    if len(sys.argv) > 1:
        vm_ip = sys.argv[1]
    else:
        vm_ip = input("Enter VM IP Address: ").strip()

    # 2. Connection Config
    config = {
        'host': vm_ip,
        'user': 'admin', 
        'password': 'admin123',
        'autocommit': True
    }
    
    print(f"\n[*] Connecting to {vm_ip} as root...")

    try:
        conn = mysql.connector.connect(**config)
        print("[SUCCESS] Connected!")
        
        cursor = conn.cursor()
        
        print("\n[*] Reading 'database/setup.sql'...")
        with open('database/setup.sql', 'r') as f:
            sql_script = f.read()

        # Split commands
        commands = sql_script.split(';')
        
        print(f"[*] Applying Schema...")
        
        success_count = 0
        for cmd in commands:
            if cmd.strip():
                try:
                    cursor.execute(cmd)
                    success_count += 1
                except mysql.connector.Error as err:
                    # Ignore harmless warnings
                    if "Unknown table" in str(err) or "Can't drop database" in str(err):
                        pass
                    else:
                        print(f"   [Warning] {err}")
        
        print(f"\n[SUCCESS] Database updated! {success_count} commands executed.")
        
    except Exception as e:
        print(f"[ERROR] {e}")
    finally:
        if 'conn' in locals() and conn.is_connected():
            conn.close()

if __name__ == '__main__':
    setup_database()
