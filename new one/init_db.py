import mysql.connector
import sys
import os

def init_db():
    print("Initializing Database...")
    config = {
        'host': os.getenv('DB_HOST', '192.168.1.5'),
        'user': 'root',
        'password': os.getenv('DB_PASSWORD', 'root') # Default to 'root' as per VM setup
    }
    
    # Try connecting with default config
    try:
        conn = mysql.connector.connect(**config)
    except mysql.connector.Error:
        # If failed, maybe password is required?
        print("Could not connect with empty password.")
        pwd = input("Enter your MySQL root password (leave empty if none): ")
        config['password'] = pwd
        try:
            conn = mysql.connector.connect(**config)
        except mysql.connector.Error as err:
            print(f"Error connecting to MySQL: {err}")
            if err.errno == 2059:
                print("\n[!] Authentication Plugin Error: The server requested an authentication method unknown to the client.")
                print("    Please run the updated 'vm_provision.sh' inside the VM to fix the user privileges.")
            elif err.errno == 1130:
                print("\n[!] Host Not Allowed Error: The MySQL server rejected the connection from this IP.")
                print("    Please ensure you ran the GRANT commands in 'vm_provision.sh' inside the VM.")
            return

    cursor = conn.cursor()
    
    try:
        with open('database/setup.sql', 'r') as f:
            sql_script = f.read()
            
        # Split by ; to execute commands one by one
        commands = sql_script.split(';')
        for command in commands:
            if command.strip():
                try:
                    cursor.execute(command)
                except mysql.connector.Error as err:
                    print(f"Warning executing command: {err}")
                    
        conn.commit()
        print("Database initialized successfully!")
        
    except FileNotFoundError:
        print("Error: database/setup.sql not found.")
    except Exception as e:
        print(f"An error occurred: {e}")
    finally:
        cursor.close()
        conn.close()

if __name__ == '__main__':
    init_db()
