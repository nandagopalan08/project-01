-- Create Vulnerable Database
CREATE DATABASE IF NOT EXISTS vulnerable_db;
USE vulnerable_db;

DROP TABLE IF EXISTS users;
CREATE TABLE IF NOT EXISTS users (
    user_id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL, -- In real app use hash, here plain for demo/vuln
    role VARCHAR(20) DEFAULT 'user',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Insert dummy data into vulnerable app
-- Use INSERT IGNORE to avoid duplicate entry errors if data persists or re-run
INSERT IGNORE INTO users (username, password, role) VALUES ('admin', 'admin123', 'admin');
INSERT IGNORE INTO users (username, password, role) VALUES ('user', 'password', 'user');

-- Create Security Database
CREATE DATABASE IF NOT EXISTS security_db;
USE security_db;

DROP TABLE IF EXISTS attacks;
DROP TABLE IF EXISTS vulnerable_applications;
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

DROP TABLE IF EXISTS security_logs;
CREATE TABLE IF NOT EXISTS security_logs (
    log_id INT AUTO_INCREMENT PRIMARY KEY,
    action_taken VARCHAR(50),
    reason TEXT,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
);

DROP TABLE IF EXISTS login_attempts;
CREATE TABLE IF NOT EXISTS login_attempts (
    attempt_id INT AUTO_INCREMENT PRIMARY KEY,
    ip_address VARCHAR(50),
    attempt_count INT DEFAULT 0,
    last_attempt DATETIME,
    is_locked BOOLEAN DEFAULT FALSE
);

-- Register the default vulnerable app
INSERT INTO vulnerable_applications (app_name, app_url) SELECT 'Vulnerable Web App', 'http://localhost:5000' WHERE NOT EXISTS (SELECT * FROM vulnerable_applications WHERE app_name = 'Vulnerable Web App');

-- Switch back to Vulnerable Database for App Data
USE vulnerable_db;

-- Cars Table for Car Selling App
DROP TABLE IF EXISTS comments;
DROP TABLE IF EXISTS cars;
CREATE TABLE IF NOT EXISTS cars (
    car_id INT AUTO_INCREMENT PRIMARY KEY,
    make VARCHAR(50),
    model VARCHAR(50),
    year INT,
    price DECIMAL(10, 2),
    image_url VARCHAR(255),
    description TEXT
);

-- Login History/Logs
DROP TABLE IF EXISTS login_logs;
CREATE TABLE IF NOT EXISTS login_logs (
    log_id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50),
    ip_address VARCHAR(50),
    status VARCHAR(20), -- 'Success' or 'Failed'
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Comments Table (Vulnerable to XSS)
CREATE TABLE IF NOT EXISTS comments (
    comment_id INT AUTO_INCREMENT PRIMARY KEY,
    car_id INT,
    user VARCHAR(50),
    comment_text TEXT,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (car_id) REFERENCES cars(car_id) ON DELETE CASCADE
);

-- Dummy Data for Cars
INSERT INTO cars (make, model, year, price, image_url, description) VALUES 
('Tesla', 'Model S', 2023, 79990.00, 'https://images.unsplash.com/photo-1617788138017-80ad40651399?q=80&w=1000&auto=format&fit=crop', 'Electric luxury sedan with autopilot capabilities.'),
('Porsche', '911 Carrera', 2022, 115000.00, 'https://images.unsplash.com/photo-1503376763036-066120622c74?q=80&w=1000&auto=format&fit=crop', 'Iconic sports car with rear-engine layout.'),
('BMW', 'M3 Competition', 2024, 85000.00, 'https://images.unsplash.com/photo-1555215695-3004980adade?q=80&w=1000&auto=format&fit=crop', 'High-performance sedan for the ultimate driving experience.'),
('Mercedes', 'AMG GT', 2023, 110000.00, 'https://images.unsplash.com/photo-1618843479313-40f8afb4b4d8?q=80&w=1000&auto=format&fit=crop', 'Luxury coupe with aggressive styling and V8 power.'),
('Ferrari', 'F8 Tributo', 2022, 280000.00, 'https://images.unsplash.com/photo-1592198084033-aade902d1aae?q=80&w=1000&auto=format&fit=crop', 'Mid-engine V8 supercar from Maranello.'),
('Lamborghini', 'Huracan', 2023, 250000.00, 'https://images.unsplash.com/photo-1544636331-e26879cd4d9b?q=80&w=1000&auto=format&fit=crop', 'V10 naturally aspirated monster.');
