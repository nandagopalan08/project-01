-- ==========================================
-- Production-Ready Database Schema
-- Compatible with XAMPP (MariaDB/MySQL) and Linux MySQL
-- Supports IPv4/IPv6, Indexes, and Foreign Keys
-- ==========================================

-- ------------------------------------------
-- 1. Vulnerable Database (Client App)
-- ------------------------------------------
CREATE DATABASE IF NOT EXISTS vulnerable_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE vulnerable_db;

-- Users Table
-- optimized for lookups by username
DROP TABLE IF EXISTS users;
CREATE TABLE IF NOT EXISTS users (
    user_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL,
    password VARCHAR(255) NOT NULL, -- In real apps, store bcrypt hashes
    role ENUM('user', 'admin') DEFAULT 'user',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY idx_username (username)
) ENGINE=InnoDB;

-- Cars Table (Product Catalog)
DROP TABLE IF EXISTS cars;
CREATE TABLE IF NOT EXISTS cars (
    car_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    make VARCHAR(50) NOT NULL,
    model VARCHAR(50) NOT NULL,
    year YEAR NOT NULL,
    price DECIMAL(12, 2) NOT NULL,
    image_url VARCHAR(2048), -- URLs can be long
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_make_model (make, model)
) ENGINE=InnoDB;

-- Comments Table (Vulnerable Content)
DROP TABLE IF EXISTS comments;
CREATE TABLE IF NOT EXISTS comments (
    comment_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    car_id INT UNSIGNED NOT NULL,
    user VARCHAR(50) DEFAULT 'Anonymous',
    comment_text TEXT,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (car_id) REFERENCES cars(car_id) ON DELETE CASCADE,
    INDEX idx_car_id (car_id)
) ENGINE=InnoDB;

-- Login Logs (Audit Trail)
DROP TABLE IF EXISTS login_logs;
CREATE TABLE IF NOT EXISTS login_logs (
    log_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50),
    ip_address VARCHAR(45), -- IPv6 support (max 45 chars)
    status ENUM('Success', 'Failed', 'Error') DEFAULT 'Failed',
    user_agent VARCHAR(255),
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_ip (ip_address),
    INDEX idx_username_time (username, timestamp)
) ENGINE=InnoDB;

-- Seed Data: Users
INSERT IGNORE INTO users (username, password, role) VALUES 
('admin', 'admin123', 'admin'),
('user', 'password', 'user');

-- Seed Data: Cars
INSERT INTO cars (make, model, year, price, image_url, description) VALUES 
('Tesla', 'Model S', 2023, 79990.00, 'https://images.unsplash.com/photo-1617788138017-80ad40651399?q=80&w=1000&auto=format&fit=crop', 'Electric luxury sedan with autopilot capabilities.'),
('Porsche', '911 Carrera', 2022, 115000.00, 'https://images.unsplash.com/photo-1503376763036-066120622c74?q=80&w=1000&auto=format&fit=crop', 'Iconic sports car with rear-engine layout.'),
('BMW', 'M3 Competition', 2024, 85000.00, 'https://images.unsplash.com/photo-1555215695-3004980adade?q=80&w=1000&auto=format&fit=crop', 'High-performance sedan for the ultimate driving experience.'),
('Mercedes', 'AMG GT', 2023, 110000.00, 'https://images.unsplash.com/photo-1618843479313-40f8afb4b4d8?q=80&w=1000&auto=format&fit=crop', 'Luxury coupe with aggressive styling and V8 power.'),
('Ferrari', 'F8 Tributo', 2022, 280000.00, 'https://images.unsplash.com/photo-1592198084033-aade902d1aae?q=80&w=1000&auto=format&fit=crop', 'Mid-engine V8 supercar from Maranello.'),
('Lamborghini', 'Huracan', 2023, 250000.00, 'https://images.unsplash.com/photo-1544636331-e26879cd4d9b?q=80&w=1000&auto=format&fit=crop', 'V10 naturally aspirated monster.');

-- ------------------------------------------
-- 2. Security Database (Gateway)
-- ------------------------------------------
CREATE DATABASE IF NOT EXISTS security_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE security_db;

-- Monitored Applications
DROP TABLE IF EXISTS vulnerable_applications;
CREATE TABLE IF NOT EXISTS vulnerable_applications (
    app_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    app_name VARCHAR(100) NOT NULL,
    app_url VARCHAR(255) NOT NULL,
    status ENUM('active', 'inactive', 'maintenance') DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY idx_app_url (app_url)
) ENGINE=InnoDB;

-- Attack Logs (IDS/IPS Data)
DROP TABLE IF EXISTS attacks;
CREATE TABLE IF NOT EXISTS attacks (
    attack_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    attack_type VARCHAR(50) NOT NULL, -- e.g., 'SQL Injection', 'XSS'
    payload TEXT,                     -- The malicious payload
    ip_address VARCHAR(45) NOT NULL,  -- IPv6 support
    user_agent VARCHAR(255),
    request_path VARCHAR(255),
    app_id INT UNSIGNED,
    attack_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (app_id) REFERENCES vulnerable_applications(app_id) ON DELETE SET NULL,
    INDEX idx_attack_type (attack_type),
    INDEX idx_attacker_ip (ip_address),
    INDEX idx_time (attack_time)
) ENGINE=InnoDB;

-- Security Actions (Blocks/Bans)
DROP TABLE IF EXISTS security_logs;
CREATE TABLE IF NOT EXISTS security_logs (
    log_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    action_taken VARCHAR(50) NOT NULL, -- e.g., 'Block IP', 'Alert'
    reason TEXT,
    ip_address VARCHAR(45),
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_action_time (timestamp)
) ENGINE=InnoDB;

-- Login Attempts (Brute Force Tracking)
DROP TABLE IF EXISTS login_attempts;
CREATE TABLE IF NOT EXISTS login_attempts (
    attempt_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    ip_address VARCHAR(45) NOT NULL,
    attempt_count INT UNSIGNED DEFAULT 1,
    last_attempt TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    is_locked BOOLEAN DEFAULT FALSE,
    lockout_end TIMESTAMP NULL,
    UNIQUE KEY idx_ip_attempts (ip_address)
) ENGINE=InnoDB;

-- Seed Data: Register App
INSERT INTO vulnerable_applications (app_name, app_url)
SELECT 'Vulnerable Web App', 'http://localhost:5000'
WHERE NOT EXISTS (SELECT 1 FROM vulnerable_applications WHERE app_url = 'http://localhost:5000');
