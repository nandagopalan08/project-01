from flask import Flask, request, render_template, redirect, url_for, session, render_template_string
import mysql.connector
import os
import datetime

app = Flask(__name__)
app.secret_key = 'vulnerable_secret'

# Database Connection Config
# Database Connection Config
db_config = {
    'host': os.getenv('DB_HOST', '127.0.0.1'),
    'user': 'project_user',
    'password': 'project123',
    'database': 'vulnerable_db'
}

def get_db_connection():
    try:
        conn = mysql.connector.connect(**db_config)
        return conn
    except mysql.connector.Error as err:
        print(f"Error connecting to DB: {err}")
        return None

def log_login_attempt(username, status, ip):
    conn = get_db_connection()
    if conn:
        try:
            cursor = conn.cursor()
            query = "INSERT INTO login_logs (username, ip_address, status) VALUES (%s, %s, %s)"
            cursor.execute(query, (username, ip, status))
            conn.commit()
        except mysql.connector.Error as err:
            print(f"Error logging login: {err}")
        finally:
            conn.close()

@app.route('/')
def home():
    cars = []
    conn = get_db_connection()
    if conn:
        try:
            cursor = conn.cursor(dictionary=True)
            cursor.execute("SELECT * FROM cars")
            cars = cursor.fetchall()
        except mysql.connector.Error as err:
            return f"Database Error: {err}"
        finally:
            conn.close()
    else:
        return "<h1>Database Connection Failed</h1><p>Ensure MySQL is running and credentials are correct.</p><p>Check the terminal for detailed error logs.</p>"
        
    return render_template('index.html', cars=cars)

@app.route('/car/<int:car_id>')
def car_detail(car_id):
    car = None
    conn = get_db_connection()
    if conn:
        try:
            cursor = conn.cursor(dictionary=True)
            cursor.execute("SELECT * FROM cars WHERE car_id = %s", (car_id,))
            car = cursor.fetchone()
            
            # Fetch comments for this car
            cursor.execute("SELECT * FROM comments WHERE car_id = %s ORDER BY timestamp DESC", (car_id,))
            comments = cursor.fetchall()
        finally:
            conn.close()
    
    if car:
        return render_template('car_details.html', car=car, comments=comments)
    return "Car not found", 404

@app.route('/login', methods=['GET', 'POST'])
def login():
    error = None
    if request.method == 'POST':
        username = request.form.get('username')
        password = request.form.get('password')
        client_ip = request.remote_addr
        
        conn = get_db_connection()
        if conn:
            cursor = conn.cursor(dictionary=True)
            # VULNERABLE CODE: Direct string formatting allows SQL Injection
            query = f"SELECT * FROM users WHERE username = '{username}' AND password = '{password}'"
            try:
                cursor.execute(query) # Intentionally vulnerable
                # If multiple results returned (e.g. ' OR '1'='1), we take the first one
                user = cursor.fetchone() 
                
                if user:
                    session['user'] = user['username']
                    session['role'] = user['role']
                    log_login_attempt(username, 'Success', client_ip)
                    
                    if user['role'] == 'admin':
                        return redirect(url_for('admin_dashboard'))
                    else:
                        return redirect(url_for('home'))
                else:
                    error = "Invalid Credentials"
                    log_login_attempt(username, 'Failed', client_ip)
            except mysql.connector.Error as err:
                error = f"Database Error: {err}"
                log_login_attempt(username, f"Error: {err}", client_ip)
            finally:
                cursor.close()
                conn.close()
        else:
            error = "Could not connect to database"

    return render_template('login.html', error=error)

@app.route('/admin')
def admin_dashboard():
    # Only allow admin access
    if 'user' not in session or session.get('role') != 'admin':
        return redirect(url_for('login'))
        
    login_logs = []
    attacks = [] # Mock or fetch from security_db if possible
    
    conn = get_db_connection()
    if conn:
        try:
            cursor = conn.cursor(dictionary=True)
            
            # Fetch Login Logs
            cursor.execute("SELECT * FROM login_logs ORDER BY timestamp DESC LIMIT 50")
            login_logs = cursor.fetchall()
            
            # Try to fetch attacks from security_db if the user has permissions
            # We use a try-except block here specifically for the cross-db query
            try:
                cursor.execute("SELECT * FROM security_db.attacks ORDER BY attack_time DESC LIMIT 50")
                attacks = cursor.fetchall()
            except mysql.connector.Error:
                # Fallback if cannot access security_db or table doesn't exist
                attacks = []
                
        finally:
            conn.close()

    return render_template('admin.html', username=session['user'], login_logs=login_logs, attacks=attacks)

@app.route('/sell', methods=['GET', 'POST'])
def sell_car():
    if 'user' not in session:
        return redirect(url_for('login'))
        
    if request.method == 'POST':
        make = request.form.get('make')
        model = request.form.get('model')
        year = request.form.get('year')
        price = request.form.get('price')
        description = request.form.get('description')
        image_url = request.form.get('image_url') # VULNERABLE: No validation on URL or file upload mechanism
        
        conn = get_db_connection()
        if conn:
            try:
                cursor = conn.cursor()
                query = "INSERT INTO cars (make, model, year, price, description, image_url) VALUES (%s, %s, %s, %s, %s, %s)"
                cursor.execute(query, (make, model, year, price, description, image_url))
                conn.commit()
                return redirect(url_for('home'))
            except mysql.connector.Error as err:
                return f"Error adding car: {err}"
            finally:
                conn.close()
                
    return render_template('sell.html')

@app.route('/car/<int:car_id>/comment', methods=['POST'])
def add_comment(car_id):
    comment_text = request.form.get('comment')
    user = session.get('user', 'Anonymous')
    
    conn = get_db_connection()
    if conn:
        try:
            cursor = conn.cursor()
            # VULNERABLE CODE: Stored XSS and SQL Injection
            # Direct string formatting without sanitization
            query = f"INSERT INTO comments (car_id, user, comment_text) VALUES ({car_id}, '{user}', '{comment_text}')"
            cursor.execute(query)
            conn.commit()
        except mysql.connector.Error as err:
            return f"Error posting comment: {err}"
        finally:
            conn.close()
            
    return redirect(url_for('car_detail', car_id=car_id))

@app.route('/logout')
def logout():
    session.pop('user', None)
    session.pop('role', None)
    return redirect(url_for('login'))

@app.route('/search')
def search():
    query = request.args.get('q', '')
    # VULNERABLE CODE: Reflected XSS
    return render_template_string(f'''
        {{% extends "base.html" %}}
        {{% block content %}}
        <div class="row">
            <div class="col-md-12">
                <h1>Search Results</h1>
                <p>You searched for: {query}</p>
                <div class="alert alert-info">No cars found matching your criteria.</div>
                <a href="/" class="btn btn-secondary">Back to Cars</a>
            </div>
        </div>
        {{% endblock %}}
    ''') 

@app.route('/read')
def read_file():
    # VULNERABLE CODE: Path Traversal / Local File Inclusion (LFI)
    filename = request.args.get('file')
    if not filename:
        return "Please specify a file parameter, e.g., /read?file=requirements.txt"
    try:
        # Directly opens user-supplied path
        with open(filename, 'r') as f:
            content = f.read()
        return f"<pre>{content}</pre>"
    except Exception as e:
        return f"Error reading file"

if __name__ == '__main__':
    # Listen on all interfaces so VM is accessible from Host
    app.run(host='0.0.0.0', port=5000, debug=True)
