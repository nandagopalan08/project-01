Write-Host "Hybrid Security Lab - Startup Script" -ForegroundColor Cyan
Write-Host "--------------------------------------"
Write-Host "This script starts the SECURITY GATEWAY on your Windows host."
Write-Host "The VULNERABLE APP must be running inside your Lubuntu VM."
Write-Host "--------------------------------------"

# 1. Configuration
$rawVmIP = Read-Host "Enter the IP Address of your Lubuntu VM (e.g., 192.168.1.50) [Check with 'hostname -I' in VM]"

if ([string]::IsNullOrWhiteSpace($rawVmIP)) {
    Write-Host "VM IP is required. Exiting..." -ForegroundColor Red
    exit
}

# Fix: Handle case where user pastes multiple IPs (e.g. "10.0.2.15 fd17:...")
$vmIP = $rawVmIP.Split(' ', [StringSplitOptions]::RemoveEmptyEntries)[0].Trim()

# Warning for NAT IP
if ($vmIP -eq "10.0.2.15") {
    Write-Host "--------------------------------------------------------" -ForegroundColor Yellow
    Write-Host "WARNING: You entered '10.0.2.15'." -ForegroundColor Red
    Write-Host "This is usually the default NAT IP and is NOT reachable from Windows." -ForegroundColor Yellow
    Write-Host "Please ensure your VM Network is set to 'Bridged Adapter' in VirtualBox." -ForegroundColor Yellow
    Write-Host "If you use Bridged, your IP should look like 192.168.x.x" -ForegroundColor Yellow
    Write-Host "--------------------------------------------------------" -ForegroundColor Yellow
    Start-Sleep -Seconds 3
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
