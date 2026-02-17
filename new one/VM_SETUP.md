# VM Configuration Guide (Lubuntu)

This guide helps you set up the project to run in a **Host (Windows)** -> **VM (Lubuntu)** environment.

## 1. Network Setup (First Time Only)
1.  **Shut Down** your VM.
2.  In VirtualBox: **Settings** -> **Network**.
3.  Set **Attached to** -> **Bridged Adapter**.
4.  Start the VM.
5.  In VM Terminal, check IP: `hostname -I` (Should be something like `192.168.1.x`).

## 2. Database Initialization (Crucial!)
You must initialize the database inside the VM for remote access.

1.  Copy the `database` folder (specifically `reinit_db.sh` and `setup.sql`) to your VM.
2.  Open a terminal inside the VM in that folder.
3.  Run the **Re-initialization Script**:
    ```bash
    bash reinit_db.sh
    ```
    *   **What this does**:
        *   Restarts MySQL.
        *   Sets `bind-address = 0.0.0.0` (allows remote connections).
        *   Creates user `admin` with password `admin123` (using `mysql_native_password` plugin).
        *   Applies the production-ready schema (`setup.sql`).

## 3. Run the Vulnerable App (Inside VM)
The vulnerable application needs to run inside the VM to simulate the target server.

1.  In the VM terminal:
    ```bash
    python3 vulnerable_app/app.py
    ```
    *Ensure it says `Running on http://0.0.0.0:5000` (NOT 127.0.0.1).*

## 4. Start the Project (On Windows Host)
1.  Open **PowerShell** in your project folder.
2.  Run the **Diagnostic Tool** first to verify connectivity:
    ```powershell
    python diagnose_connection.py
    ```
3.  If diagnostics pass, run the main startup script:
    ```powershell
    .\start.ps1
    ```
4.  Enter the **VM IP Address** when prompted.

## Troubleshooting
*   **"MySQL Login FAILED"**: 
    *   Run `bash reinit_db.sh` inside the VM again. This fixes permissions and plugins.
*   **"MySQL Port 3306 UNREACHABLE"**: 
    *   Check VM Firewall: `sudo ufw allow 3306` inside VM.
    *   Check `bind-address` in `/etc/mysql/mysql.conf.d/mysqld.cnf` is `0.0.0.0`.
*   **"Vulnerable App UNREACHABLE"**:
    *   Ensure the app is actually running in the VM (`python3 vulnerable_app/app.py`).
    *   Check VM Firewall: `sudo ufw allow 5000`.
