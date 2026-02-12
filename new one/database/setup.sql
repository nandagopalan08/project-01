-- Create Vulnerable Database
CREATE DATABASE IF NOT EXISTS vulnerable_db;
USE vulnerable_db;

CREATE TABLE IF NOT EXISTS users (
    user_id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL, -- In real app use hash, here plain for demo/vuln
    role VARCHAR(20) DEFAULT 'user',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Insert dummy data into vulnerable app
INSERT INTO users (username, password, role) VALUES ('admin', 'admin123', 'admin');
INSERT INTO users (username, password, role) VALUES ('user', 'password', 'user');

-- Create Security Database
CREATE DATABASE IF NOT EXISTS security_db;
USE security_db;

CREATE TABLE IF NOT EXISTS vulnerable_applications (
    app_id INT AUTO_INCREMENT PRIMARY KEY,
    app_name VARCHAR(100) NOT NULL,
    app_url VARCHAR(255) NOT NULL,
    status VARCHAR(20) DEFAULT 'active'
);

CREATE TABLE IF NOT EXISTS attacks (
    attack_id INT AUTO_INCREMENT PRIMARY KEY,
    attack_type VARCHAR(50),
    payload TEXT,
    ip_address VARCHAR(50),
    attack_time DATETIME DEFAULT CURRENT_TIMESTAMP,
    app_id INT,
    FOREIGN KEY (app_id) REFERENCES vulnerable_applications(app_id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS security_logs (
    log_id INT AUTO_INCREMENT PRIMARY KEY,
    action_taken VARCHAR(50),
    reason TEXT,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS login_attempts (
    attempt_id INT AUTO_INCREMENT PRIMARY KEY,
    ip_address VARCHAR(50),
    attempt_count INT DEFAULT 0,
    last_attempt DATETIME,
    is_locked BOOLEAN DEFAULT FALSE
);

-- Register the default vulnerable app
INSERT INTO vulnerable_applications (app_name, app_url) VALUES ('Vulnerable Web App', 'http://localhost:5000');
