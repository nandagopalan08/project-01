# Web Application Security Simulation Lab

## Project Description

This project focuses on designing and deploying a normal web application inside a Virtual Machine (VM) to simulate a real-world production environment. The hosted application is intentionally exposed to controlled and simulated cyber-attacks in order to identify common web vulnerabilities such as SQL Injection, Cross-Site Scripting (XSS), and Brute Force attacks.

A separate security monitoring and protection layer is developed to observe incoming requests, analyze attack patterns, log malicious activities, and apply preventive actions in real time. The system evaluates how attacks affect the application and demonstrates how security mechanisms can reduce or prevent exploitation with minimal effort.

The project provides a safe, isolated environment to study web application security, attack behavior, and defense strategies without affecting real systems.

## Key Objectives

- **Host a standard web application inside a Virtual Machine**
- **Simulate real-world web attacks** in a controlled environment
- **Detect vulnerabilities** using request analysis
- **Log and monitor malicious activities**
- **Apply protection mechanisms** such as request blocking and rate limiting
- **Demonstrate secure vs vulnerable system behavior**

## Project Environment

- **Normal Web Application**: Hosted inside VMware station (Vulnerable Flask App)
- **Virtual Machine**: Acts as isolated server environment (managed via Vagrant)
- **Attack Simulation**: Performed through browser and crafted payloads
- **Security Layer**: Monitors, detects, and protects the application

## Attack Simulation Scope

- **SQL Injection** attacks via input fields
- **Cross-Site Scripting (XSS)** via user input
- **Brute-force** login attempts
- **Unauthorized request access**

## Protection Mechanisms

- **Input pattern detection** (SQLi, XSS signatures)
- **Malicious request blocking**
- **IP-based rate limiting** (Anti-Brute Force)
- **Attack logging and monitoring dashboard**

## Getting Started

### Prerequisites

- **VirtualBox**: For virtualization.
- **Vagrant**: For VM management.
- **Python 3**: For running locally (optional).

### Running in VM (Recommended)

1.  Open a terminal in the project directory.
2.  Run `vagrant up` to provision and start the VM.
3.  The applications will start automatically.
    *   **Vulnerable App**: [http://localhost:5000](http://localhost:5000)
    *   **Security Gateway**: [http://localhost:5001](http://localhost:5001)
    *   **Admin Dashboard**: [http://localhost:5001/admin_panel](http://localhost:5001/admin_panel)

### Running Locally (Alternative)

If you cannot run a VM, you can simulate the environment locally:

1.  Install dependencies: `pip install -r requirements.txt`
2.  Initialize the database: `python init_db.py` (Ensure MySQL is running)
3.  Run the start script:
    *   **Windows**: `.\start.ps1`
    *   **Linux/Mac**: `bash start.sh` (Create this if needed, or run apps manually)

## Usage

1.  **Attack**: Navigate to the Security Gateway ([http://localhost:5001](http://localhost:5001)) which proxies traffic to the Vulnerable App.
2.  **SQL Injection**: Try entering `' OR '1'='1` in the Login username field.
3.  **XSS**: Try searching for `<script>alert('XSS')</script>`.
4.  **Brute Force**: Attempt to login 5 times with incorrect credentials.
5.  **Monitor**: specific attacks will be blocked. Check the **Admin Dashboard** to see the logs.

---
*Disclaimer: This project is for educational purposes only. Do not use these techniques on systems you do not own.*
