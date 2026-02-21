-- ==========================================
-- DATABASE RESET & SETUP SCRIPT
-- Project: Web Attack Simulation & Monitoring
-- Target: Final Year Cybersecurity Project
-- ==========================================

-- 1. Create Database
CREATE DATABASE IF NOT EXISTS vulnerable_db;
USE vulnerable_db;

-- 2. Create Project User (Consistent across VM/Host)
-- Using plain IDENTIFIED BY for maximum compatibility across MariaDB/MySQL
DROP USER IF EXISTS 'project_user'@'%';
DROP USER IF EXISTS 'project_user'@'localhost';
CREATE USER 'project_user'@'%' IDENTIFIED BY 'project123';
CREATE USER 'project_user'@'localhost' IDENTIFIED BY 'project123';
GRANT ALL PRIVILEGES ON vulnerable_db.* TO 'project_user'@'%';
GRANT ALL PRIVILEGES ON vulnerable_db.* TO 'project_user'@'localhost';
FLUSH PRIVILEGES;

-- 3. Core Tables for Vulnerable App
DROP TABLE IF EXISTS users;
CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL,
    password VARCHAR(255) NOT NULL,
    role VARCHAR(20) DEFAULT 'user',
    bio TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

DROP TABLE IF EXISTS cars;
CREATE TABLE cars (
    car_id INT AUTO_INCREMENT PRIMARY KEY,
    make VARCHAR(50) NOT NULL,
    model VARCHAR(50) NOT NULL,
    year INT NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    description TEXT,
    image_url VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

DROP TABLE IF EXISTS comments;
CREATE TABLE comments (
    id INT AUTO_INCREMENT PRIMARY KEY,
    car_id INT NOT NULL,
    user VARCHAR(50) NOT NULL,
    comment_text TEXT NOT NULL,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (car_id) REFERENCES cars(car_id) ON DELETE CASCADE
);

DROP TABLE IF EXISTS sessions;
CREATE TABLE sessions (
    session_id VARCHAR(255) PRIMARY KEY,
    user_id INT,
    expiry DATETIME,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- 4. Security Gateway & Monitoring Tables
DROP TABLE IF EXISTS monitored_sites;
CREATE TABLE monitored_sites (
    id INT AUTO_INCREMENT PRIMARY KEY,
    app_name VARCHAR(100),
    app_url VARCHAR(255),
    status VARCHAR(20) DEFAULT 'active'
);

DROP TABLE IF EXISTS attack_logs;
CREATE TABLE attack_logs (
    id INT AUTO_INCREMENT PRIMARY KEY,
    attack_type VARCHAR(50), -- SQLi, XSS, Brute Force
    payload TEXT,
    source_ip VARCHAR(45),
    target_path VARCHAR(255),
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    detection_flags VARCHAR(255),
    mitigation_status VARCHAR(50) -- Blocked, Logged Only
);

DROP TABLE IF EXISTS security_events;
CREATE TABLE security_events (
    id INT AUTO_INCREMENT PRIMARY KEY,
    event_name VARCHAR(100),
    description TEXT,
    severity ENUM('Low', 'Medium', 'High', 'Critical'),
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

DROP TABLE IF EXISTS login_logs;
CREATE TABLE login_logs (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50),
    attempt_status ENUM('Success', 'Failed'),
    source_ip VARCHAR(45),
    user_agent TEXT,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

DROP TABLE IF EXISTS blocked_ips;
CREATE TABLE blocked_ips (
    ip_address VARCHAR(45) PRIMARY KEY,
    reason TEXT,
    blocked_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at DATETIME
);

-- 5. Seed Data for Demo
INSERT INTO users (username, password, role, bio) VALUES 
('admin', 'admin123', 'admin', 'System Administrator'),
('victim', 'password123', 'user', 'Normal user for testing XSS'),
('attacker', 'p@ssword', 'user', 'Test account');

INSERT INTO monitored_sites (app_name, app_url) VALUES 
('Vulnerable Client App', 'http://127.0.0.1:5000');
