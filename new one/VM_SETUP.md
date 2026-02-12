# Manual VM Setup Guide (Lubuntu/Ubuntu)

Since you already have a **Lubuntu VM** installed, follow these steps to host the **Vulnerable App** inside it.

## Step 1: Network Configuration (Critical)
1.  Shut down your VM.
2.  Open **VirtualBox**.
3.  Right-click your VM -> **Settings** -> **Network**.
4.  Change **Attached to** to **Bridged Adapter**.
5.  Select your active Windows network adapter (Wi-Fi or Ethernet).
6.  Start the VM.
7.  Open a terminal in the VM and run:
    ```bash
    hostname -I
    ```
    *Note down this IP address (e.g., 192.168.1.xxx).*

## Step 2: Transfer Project Files
You need to get the project files into the VM.
*   **Option A (Shared Folders)**: Install VirtualBox Guest Additions and mount a shared folder.
*   **Option B (Copy/Paste)**: If Drag & Drop is enabled (Settings -> General -> Advanced), drag the project folder.
*   **Option C (Download)**: If you possess the source as a zip, download it inside the VM.

## Step 3: Provision the VM
Once the files are in the VM (e.g., in `~/project`), open a terminal in that folder and run:

1.  **Make the script executable**:
    ```bash
    chmod +x vm_provision.sh
    ```
2.  **Run the script**:
    ```bash
    ./vm_provision.sh
    ```
    *This will install Python, MySQL, configure the database users, and set up the schema.*

## Step 4: Start the Vulnerable App (Inside VM)
After provisioning is complete, keep the terminal open and run:

```bash
python3 vulnerable_app/app.py
```
*You should see: `Running on http://0.0.0.0:5000`*

## Step 5: Start the Security Gateway (On Windows Host)
Now that the VM is running the app:

1.  Open **PowerShell** on Windows in the project folder.
2.  Run:
    ```powershell
    .\start.ps1
    ```
3.  Enter the **VM IP Address** you got in Step 1.
4.  The Security Gateway will launch and connect to the VM.

## Troubleshooting
*   **Connection Failed**: Try pinging the VM from Windows (`ping <VM_IP>`). If it fails, check your Firewall or Ensure Bridged Adapter is selected.
*   **MySQL Connection Error**: Ensure `vm_provision.sh` ran successfully and you haven't changed the root password manually. The script sets it to `root`.
