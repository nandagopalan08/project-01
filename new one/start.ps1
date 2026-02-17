$ErrorActionPreference = "Stop"

Write-Host "Hybrid Security Lab - Startup Script" -ForegroundColor Cyan
Write-Host "--------------------------------------"
Write-Host "This script configures and starts the project on your Windows host."
Write-Host "It connects to the Database running inside your VM."
Write-Host "--------------------------------------"

# 1. Configuration
$rawVmIP = Read-Host "Enter the IP Address of your VM (e.g., 192.168.1.13) [Check with 'hostname -I' in VM]"

if ([string]::IsNullOrWhiteSpace($rawVmIP)) {
    Write-Host "VM IP is required. Exiting..." -ForegroundColor Red
    exit
}

# Fix: Handle case where user pastes multiple IPs
$vmIP = $rawVmIP.Split(' ', [StringSplitOptions]::RemoveEmptyEntries)[0].Trim()

# Warning for NAT IP
if ($vmIP -eq "10.0.2.15") {
    Write-Host "WARNING: You entered '10.0.2.15' (Default NAT IP)." -ForegroundColor Yellow
    Write-Host "This IP is usually NOT reachable from Windows." -ForegroundColor Red
    Write-Host "Please set your VM Network Adapter to 'Bridged Adapter' to get a reachable IP." -ForegroundColor Yellow
    Write-Host "Proceeding, but connection will likely fail..." -ForegroundColor DarkGray
    Start-Sleep -Seconds 2
}

# 2. Set Environment Variables
# We use the 'admin' user created by our reinit_db.sh script
$env:DB_HOST = $vmIP
$env:DB_USER = "admin"
$env:DB_PASSWORD = "admin123"
$env:VULNERABLE_APP_URL = "http://$($vmIP):5000" 

# 3. Validation
Write-Host "Testing connection to VM Database at $vmIP..." -ForegroundColor Gray
try {
    # Simple Python one-liner to test connection
    $testCmd = "import mysql.connector; mysql.connector.connect(user='admin', password='admin123', host='$vmIP', database='security_db'); print('OK')"
    # Hide error output to keep it clean, catch block handles it
    $res = python -c $testCmd 2>$null
    if ($res -match "OK") {
        Write-Host "SUCCESS: Connected to Database!" -ForegroundColor Green
    } else {
        throw "Connection failed"
    }
} catch {
    Write-Host "ERROR: Could not connect to the Database at $vmIP." -ForegroundColor Red
    Write-Host "Troubleshooting:" -ForegroundColor Yellow
    Write-Host "1. Did you run 'bash database/reinit_db.sh' INSIDE the VM?"
    Write-Host "2. Is the VM firewall allowing port 3306? (sudo ufw allow 3306)"
    Write-Host "3. Is the IP correct?"
    
    $retry = Read-Host "Do you want to continue anyway? (y/n)"
    if ($retry -ne "y") { exit }
}

# 4. Start the Applications
Write-Host "--------------------------------------"
Write-Host "Starting Security Gateway..." -ForegroundColor Cyan
Write-Host "Connecting to DB at: $env:DB_HOST"
Write-Host "--------------------------------------"

# Start Security Gateway (Admin Panel)
Start-Process python -ArgumentList "security_gateway/app.py" -WindowStyle Normal

# Option to start Vulnerable App locally too (if desired)
$startVuln = Read-Host "Do you want to run the Vulnerable App LOCALLY as well? (y/n) [Default: n, assuming it runs in VM]"
if ($startVuln -eq "y") {
    Start-Process python -ArgumentList "vulnerable_app/app.py" -WindowStyle Normal
    Write-Host "Started Vulnerable App on http://localhost:5000" -ForegroundColor Green
}

Write-Host "--------------------------------------"
Write-Host "Dashboard Access:"
Write-Host ">> Admin Panel:       http://127.0.0.1:5001/admin_panel"
Write-Host "   (Login: admin / securep@ss)"
Write-Host ">> Security Gateway:  http://127.0.0.1:5001"
if ($startVuln -eq "y") {
    Write-Host ">> Vulnerable App:    http://127.0.0.1:5000"
    Write-Host "   (Login: admin / admin123)"
} else {
    Write-Host ">> Vulnerable App:    http://$($vmIP):5000 (Running in VM)"
    Write-Host "   (Login: admin / admin123)"
}
Write-Host "--------------------------------------"
Write-Host "Press any key to close this launcher..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
