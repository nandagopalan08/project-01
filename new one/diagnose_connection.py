import socket
import mysql.connector
import requests
import sys
import time

def check_port(ip, port, service_name):
    # Create a socket object
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.settimeout(2) # 2 second timeout
    try:
        print(f"[*] Checking {service_name} at {ip}:{port}...", end=' ')
        result = s.connect_ex((ip, port))
        if result == 0:
            print("OPEN (Success)")
            return True
        else:
            print("CLOSED/FILTERED (Failed)")
            return False
    except Exception as e:
        print(f"ERROR: {e}")
        return False
    finally:
        s.close()

def check_mysql_login(ip):
    print(f"[*] Attempting MySQL Login (User: project_user)...", end=' ')
    try:
        conn = mysql.connector.connect(
            host=ip,
            user='project_user',
            password='project123',
            database='vulnerable_db',
            connection_timeout=3
        )
        conn.close()
        print("SUCCESS (Login OK)")
        return True
    except mysql.connector.Error as err:
        print(f"FAILED. Error: {err}")
        if "Access denied" in str(err):
            print("    -> Hint: Is the 'project_user' user created? Did you run 'bash reinit_db.sh' in the VM?")
        if "Can't connect" in str(err):
             print("    -> Hint: Is MySQL running? Is bind-address = 0.0.0.0?")
        return False

def check_http(url):
    print(f"[*] Checking HTTP Access at {url}...", end=' ')
    try:
        response = requests.get(url, timeout=3)
        print(f"SUCCESS (Status: {response.status_code})")
        return True
    except requests.exceptions.ConnectionError:
        print("FAILED (Connection Error)")
        print("    -> Hint: Is the app running? (python3 vulnerable_app/app.py)")
        return False
    except Exception as e:
        print(f"FAILED ({e})")
        return False

def main():
    print("==========================================")
    print("   CONNECTION DIAGNOSTIC TOOL             ")
    print("==========================================")
    
    if len(sys.argv) > 1:
        ip = sys.argv[1]
    else:
        ip = input("Enter VM IP Address: ").strip()
    
    if not ip:
        print("IP required.")
        return

    print(f"\n--- 1. Network Connectivity ({ip}) ---")
    # Simple ping check via shell is platform dependent, skip to port check which is more reliable for services
    
    print(f"\n--- 2. Database Checks ---")
    port_3306 = check_port(ip, 3306, "MySQL Port")
    
    db_login = False
    if port_3306:
        db_login = check_mysql_login(ip)
    
    print(f"\n--- 3. Vulnerable App Checks ---")
    port_5000 = check_port(ip, 5000, "App Port")
    
    app_http = False
    if port_5000:
        app_http = check_http(f"http://{ip}:5000")

    print("\n==========================================")
    print("   DIAGNOSTIC RESULTS & FIXES             ")
    print("==========================================")
    
    if not port_3306:
        print("[!] MySQL Port 3306 is UNREACHABLE.")
        print("    FIX: Inside VM, run: sudo ufw allow 3306")
        print("    FIX: Check /etc/mysql/mysql.conf.d/mysqld.cnf for 'bind-address = 0.0.0.0'")
        
    elif not db_login:
        print("[!] MySQL Login FAILED.")
        print("    FIX: Inside VM, run: bash reinit_db.sh")
        print("         (This creates the 'admin' user and grants permissions)")

    if not port_5000:
        print("[!] Vulnerable App Port 5000 is UNREACHABLE.")
        print("    FIX: Inside VM, run: python3 vulnerable_app/app.py")
        print("    FIX: Inside VM, run: sudo ufw allow 5000")
    
    elif not app_http:
        print("[!] Vulnerable App Port is Open but HTTP failed.")
        print("    FIX: Restart the app inside the VM.")

    if port_3306 and db_login and port_5000 and app_http:
        print("[OK] All systems GO! You can run 'start.ps1' now.")

if __name__ == "__main__":
    main()
