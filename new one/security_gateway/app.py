from flask import Flask, request, render_template, redirect, url_for, Response, session
import requests
import mysql.connector
import datetime
import os
from detection import analyze_request

app = Flask(__name__)

# Config
# Config
VULNERABLE_APP_URL = os.getenv('VULNERABLE_APP_URL', "http://127.0.0.1:5000")
DB_CONFIG = {
    'host': os.getenv('DB_HOST', 'localhost'),
    'user': 'admin',
    'password': 'admin123',
    'database': 'security_db'
}

def get_db():
    try:
        return mysql.connector.connect(**DB_CONFIG)
    except:
        return None

# Helper to get App ID (Assuming single app for now, or finding by URL)
def get_app_id():
    # consistent ID for the demo
    return 1 

def log_attack(attack_type, payload):
    conn = get_db()
    if conn:
        try:
            cursor = conn.cursor()
            app_id = get_app_id()
            # Ensure app exists (optional, mostly guaranteed by setup.sql)
            
            query = "INSERT INTO attacks (attack_type, payload, ip_address, app_id) VALUES (%s, %s, %s, %s)"
            cursor.execute(query, (attack_type, payload, request.remote_addr, app_id))
            conn.commit()
        except mysql.connector.Error as err:
            print(f"Error logging attack: {err}")
        finally:
            conn.close()

def log_security_action(action, reason):
    conn = get_db()
    if conn:
        try:
            cursor = conn.cursor()
            query = "INSERT INTO security_logs (action_taken, reason) VALUES (%s, %s)"
            cursor.execute(query, (action, reason))
            conn.commit()
        except mysql.connector.Error as err:
            print(f"Error logging security action: {err}")
        finally:
            conn.close()

def check_brute_force_lock(ip):
    conn = get_db()
    if not conn: return False
    cursor = conn.cursor(dictionary=True)
    
    # Get latest attempt for IP
    cursor.execute("SELECT * FROM login_attempts WHERE ip_address = %s ORDER BY last_attempt DESC LIMIT 1", (ip,))
    record = cursor.fetchone()
    
    is_locked_out = False
    
    if record and record['is_locked']:
        # Check if lock time expired (e.g., 5 mins)
        if record['last_attempt'] and (datetime.datetime.now() - record['last_attempt']).seconds < 300:
            is_locked_out = True
        else:
            # Unlock - Create new record or update? 
            # Strategy: Insert a clean record or update existing to unlock. 
            # Let's update the existing one to unlock it.
            cursor.execute("UPDATE login_attempts SET is_locked = FALSE, attempt_count = 0 WHERE attempt_id = %s", (record['attempt_id'],))
            conn.commit()
            log_security_action("Unlock IP", f"Lock expired for {ip}")
    
    conn.close()
    return is_locked_out

def update_login_attempt(ip, is_success):
    conn = get_db()
    if not conn: return
    cursor = conn.cursor(dictionary=True)
    
    cursor.execute("SELECT * FROM login_attempts WHERE ip_address = %s ORDER BY last_attempt DESC LIMIT 1", (ip,))
    record = cursor.fetchone()
    now = datetime.datetime.now()
    
    if is_success:
        # Reset count on success
        if record:
             cursor.execute("UPDATE login_attempts SET attempt_count = 0, is_locked = FALSE, last_attempt = %s WHERE attempt_id = %s", (now, record['attempt_id']))
    else:
        if record:
            new_count = record['attempt_count'] + 1
            is_locked = new_count >= 5
            cursor.execute("UPDATE login_attempts SET attempt_count = %s, last_attempt = %s, is_locked = %s WHERE attempt_id = %s", 
                           (new_count, now, is_locked, record['attempt_id']))
            if is_locked and not record['is_locked']:
                 log_security_action("Block IP", f"Brute Force Detected: locking {ip}")
        else:
             cursor.execute("INSERT INTO login_attempts (ip_address, attempt_count, last_attempt, is_locked) VALUES (%s, 1, %s, FALSE)", (ip, now))
    
    conn.commit()
    conn.close()

app.secret_key = 'security_gateway_secret_key'  # Change this in production!

# ... (Database Config and Helpers remain same) ...

@app.route('/gateway_login', methods=['GET', 'POST'])
def gateway_login():
    error = None
    if request.method == 'POST':
        username = request.form.get('username')
        password = request.form.get('password')
        
        # Hardcoded Admin Credentials for Gateway (Separate from Vulnerable App)
        if username == 'admin' and password == 'securep@ss': 
            session['security_admin'] = True
            return redirect(url_for('admin_panel'))
        else:
            error = "Invalid Security Credentials"
            
    return render_template('login.html', error=error)

@app.route('/logout')
def admin_logout():
    session.pop('security_admin', None)
    return redirect(url_for('gateway_login'))

@app.route('/admin_panel')
def admin_panel():
    if not session.get('security_admin'):
        return redirect(url_for('gateway_login'))
        
    conn = get_db()
    attacks = []
    security_logs = []
    
    if conn:
        try:
            cursor = conn.cursor(dictionary=True)
            # Fetch Attacks
            cursor.execute("""
                SELECT a.*, v.app_name 
                FROM attacks a 
                LEFT JOIN vulnerable_applications v ON a.app_id = v.app_id 
                ORDER BY a.attack_time DESC
            """)
            attacks = cursor.fetchall()
            
            # Fetch Security Logs
            cursor.execute("SELECT * FROM security_logs ORDER BY timestamp DESC")
            security_logs = cursor.fetchall()
        except mysql.connector.Error as err:
            print(f"Error fetching admin panel data: {err}")
        finally:
            conn.close()
            
    return render_template('admin.html', attacks=attacks, security_logs=security_logs)

# Catch-all Proxy Route
@app.route('/', defaults={'path': ''}, methods=['GET', 'POST'])
@app.route('/<path:path>', methods=['GET', 'POST'])
def proxy(path):
    target_url = f"{VULNERABLE_APP_URL}/{path}"
    
    # 1. Security Check: Attack Signatures
    is_malicious, attack_type, payload = analyze_request(request)
    if is_malicious:
        log_attack(attack_type, payload)
        log_security_action("Block Request", f"Blocked {attack_type} from {request.remote_addr}")
        return render_template('blocked.html', type=attack_type), 403

    # 2. Security Check: Rate Limiting (Brute Force)
    if path == 'login' and request.method == 'POST':
        if check_brute_force_lock(request.remote_addr):
            return render_template('blocked.html', type="Brute Force Lockout"), 403

    # 3. Forward Request
    # Exclude headers that might cause issues
    excluded_headers = ['Host', 'Content-Length']
    headers = {k: v for k, v in request.headers if k not in excluded_headers}
    
    try:
        resp = requests.request(
            method=request.method,
            url=target_url,
            headers=headers,
            data=request.form,
            params=request.args,
            cookies=request.cookies,
            allow_redirects=False # Important to capture 302
        )
        
        # 4. Post-Response Analysis (Brute Force)
        if path == 'login' and request.method == 'POST':
            if resp.status_code == 302:
                # Redirect usually means success in our app
                update_login_attempt(request.remote_addr, True)
            else:
                # 200 OK usually means the page reloaded with an error
                update_login_attempt(request.remote_addr, False)

        # Build Flask response
        excluded_headers = ['content-encoding', 'content-length', 'transfer-encoding', 'connection']
        headers = [(name, value) for (name, value) in resp.raw.headers.items()
                   if name.lower() not in excluded_headers]
        
        response = Response(resp.content, resp.status_code, headers)
        return response

    except requests.exceptions.ConnectionError:
        return "Error: Could not connect to client application. Is it running?"

if __name__ == '__main__':
    app.run(port=5001, debug=True)
