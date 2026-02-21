import mysql.connector

try:
    conn = mysql.connector.connect(host='192.168.1.8', user='project_user', password='project123', database='vulnerable_db')
    cursor = conn.cursor()
    
    # Create required tables
    cursor.execute("""
    CREATE TABLE IF NOT EXISTS login_attempts (
        attempt_id INT AUTO_INCREMENT PRIMARY KEY,
        ip_address VARCHAR(45),
        attempt_count INT DEFAULT 0,
        last_attempt TIMESTAMP,
        is_locked BOOLEAN DEFAULT FALSE
    )
    """)
    
    cursor.execute("""
    CREATE TABLE IF NOT EXISTS vulnerable_applications (
        app_id INT AUTO_INCREMENT PRIMARY KEY,
        app_name VARCHAR(100),
        app_url VARCHAR(255)
    )
    """)
    
    cursor.execute("""
    CREATE TABLE IF NOT EXISTS attacks (
        attack_id INT AUTO_INCREMENT PRIMARY KEY,
        attack_type VARCHAR(50),
        payload TEXT,
        ip_address VARCHAR(45),
        app_id INT,
        attack_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )
    """)
    
    cursor.execute("""
    CREATE TABLE IF NOT EXISTS security_logs (
        log_id INT AUTO_INCREMENT PRIMARY KEY,
        action_taken VARCHAR(100),
        reason TEXT,
        timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )
    """)
    
    conn.commit()
    print("SUCCESS: Missing security tables created.")
    conn.close()
except Exception as e:
    print('Failed to create tables:', e)
