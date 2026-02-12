Write-Host "Hybrid Security Lab - Startup Script" -ForegroundColor Cyan
Write-Host "--------------------------------------"
Write-Host "This script starts the SECURITY GATEWAY on your Windows host."
Write-Host "The VULNERABLE APP must be running inside your Lubuntu VM."
Write-Host "--------------------------------------"

# 1. Configuration
$vmIP = Read-Host "Enter the IP Address of your Lubuntu VM (e.g., 192.168.1.50) [Check with 'hostname -I' in VM]"
if ([string]::IsNullOrWhiteSpace($vmIP)) {
    Write-Host "VM IP is required. Exiting..." -ForegroundColor Red
    exit
}

$dbPassword = Read-Host "Enter VM MySQL 'root' Password (default is 'root' if using vm_provision.sh)"
if ([string]::IsNullOrWhiteSpace($dbPassword)) {
    $dbPassword = "root"
    Write-Host "Using default password: 'root'" -ForegroundColor DarkGray
}

# 2. Set Environment Variables for the Security Gateway (Running Locally)
$env:DB_HOST = $vmIP
$env:DB_USER = "root"
$env:DB_PASSWORD = $dbPassword
$env:VULNERABLE_APP_URL = "http://$($vmIP):5000"

# 3. Start the Security Gateway
Write-Host "--------------------------------------"
Write-Host "Starting Security Gateway..." -ForegroundColor Cyan
Write-Host "Targeting Vulnerable App at: $env:VULNERABLE_APP_URL"
Write-Host "Connecting to Database at:   $env:DB_HOST"
Write-Host "--------------------------------------"

# Check if we can reach the VM (Basic Ping)
if (Test-Connection -ComputerName $vmIP -Count 1 -Quiet) {
    Write-Host "VM ($vmIP) is reachable." -ForegroundColor Green
} else {
    Write-Host "WARNING: VM ($vmIP) is not responding to ping. Proceeding anyway..." -ForegroundColor Yellow
}

# Start the Python Process
Try {
    Start-Process python -ArgumentList "security_gateway/app.py" -WindowStyle Normal
    
    Write-Host "Security Gateway launched in a new window." -ForegroundColor Green
    Write-Host ""
    Write-Host "Access Points:"
    Write-Host "1. Security Gateway (Protected):   http://127.0.0.1:5001"
    Write-Host "2. Admin Dashboard:                http://127.0.0.1:5001/admin_panel"
    Write-Host "3. Vulnerable App (Direct VM):     http://$($vmIP):5000"
}
Catch {
    Write-Host "Error starting Python process. Ensure Python is installed and in your PATH." -ForegroundColor Red
    Write-Host $_.Exception.Message
}

Write-Host "--------------------------------------"
Write-Host "Press any key to close this launcher..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
