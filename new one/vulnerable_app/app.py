from flask import Flask, request, render_template, redirect, url_for, session, render_template_string
import mysql.connector
import os

app = Flask(__name__)
app.secret_key = 'vulnerable_secret'

# Database Connection Config
# Database Connection Config
db_config = {
    'host': 'localhost',
    'user': 'root',
    'password': os.getenv('DB_PASSWORD', ''),  # Use environment variable
    'database': 'vulnerable_db'
}

def get_db_connection():
    try:
        conn = mysql.connector.connect(**db_config)
        return conn
    except mysql.connector.Error as err:
        return None

@app.route('/')
def home():
    return render_template('index.html')

@app.route('/login', methods=['GET', 'POST'])
def login():
    error = None
    if request.method == 'POST':
        username = request.form.get('username')
        password = request.form.get('password')
        
        conn = get_db_connection()
        if conn:
            cursor = conn.cursor(dictionary=True)
            # VULNERABLE CODE: Direct string formatting allows SQL Injection
            query = f"SELECT * FROM users WHERE username = '{username}' AND password = '{password}'"
            try:
                cursor.execute(query) # Intentionally vulnerable
                user = cursor.fetchone()
                if user:
                    session['user'] = user['username']
                    return redirect(url_for('dashboard'))
                else:
                    error = "Invalid Credentials"
            except mysql.connector.Error as err:
                error = f"Database Error: {err}"
            finally:
                cursor.close()
                conn.close()
        else:
            error = "Could not connect to database"

    return render_template('login.html', error=error)

@app.route('/dashboard')
def dashboard():
    if 'user' in session:
        return render_template('dashboard.html', username=session['user'])
    return redirect(url_for('login'))

@app.route('/logout')
def logout():
    session.pop('user', None)
    return redirect(url_for('login'))

@app.route('/search')
def search():
    query = request.args.get('q', '')
    # VULNERABLE CODE: Reflected XSS
    # Taking input from URL and rendering it directly without escaping
    return render_template_string(f'''
        {{% extends "base.html" %}}
        {{% block content %}}
        <h1>Search Results</h1>
        <p>You searched for: {query}</p>
        <a href="/">Back Home</a>
        {{% endblock %}}
    ''') 

if __name__ == '__main__':
    # Listen on all interfaces so VM is accessible from Host
    app.run(host='0.0.0.0', port=5000, debug=True)
