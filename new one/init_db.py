import mysql.connector
import sys
import os

def init_db():
    print("Initializing Database...")
    config = {
        'host': os.getenv('DB_HOST', 'localhost'),
        'user': 'root',
        'password': os.getenv('DB_PASSWORD', '') # Default to env var or empty
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
