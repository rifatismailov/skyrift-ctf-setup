# =============================================================================
# SkyRift CTF — Windows Server 2019 Setup Script
# Machine: 10.10.50.150 | Windows Server 2019
# Flags: Flag_8 (flag{sh4r3_1s_c4r3}), Flag_9 (flag{unqu0ted_p4th_pwn}),
#        Flag_10 (flag{f0und_th3_k3ys})
# =============================================================================
# Run as Administrator in PowerShell:
# Set-ExecutionPolicy Bypass -Scope Process -Force
# .\03_windows_server_setup.ps1
# =============================================================================

$ErrorActionPreference = "SilentlyContinue"

Write-Host "[*] SkyRift - Windows Server 2019 setup starting..." -ForegroundColor Cyan

# =============================================================================
# 1. CREATE LOCAL USERS
# =============================================================================
Write-Host "[*] Creating local users..." -ForegroundColor Cyan

# svc_deploy — service account used for drone firmware deployment
$svcPassword = ConvertTo-SecureString "Deploy@2024!Drone" -AsPlainText -Force
New-LocalUser -Name "svc_deploy" `
    -Password $svcPassword `
    -FullName "DroneCorp Deployment Service Account" `
    -Description "Service account for drone firmware deployment automation" `
    -PasswordNeverExpires $true `
    -UserMayNotChangePassword $true

# Add svc_deploy to Users group (not admins)
Add-LocalGroupMember -Group "Users" -Member "svc_deploy"

Write-Host "[+] Users created." -ForegroundColor Green

# =============================================================================
# 2. ANONYMOUS SMB SHARE — Updates$
# =============================================================================
Write-Host "[*] Configuring SMB anonymous share..." -ForegroundColor Cyan

# Create the share directory
$shareDir = "C:\DroneUpdates"
New-Item -ItemType Directory -Path $shareDir -Force | Out-Null

# Enable guest access for SMB
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\LanManServer\Parameters" `
    -Name "restrictnullsessaccess" -Value 0 -Type DWORD

# Allow anonymous listing
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\LanManServer\Parameters" `
    -Name "NullSessionPipes" -Value @("srvsvc","wkssvc","netlogon","samr") -Type MultiString

Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\LanManServer\Parameters" `
    -Name "NullSessionShares" -Value @("Updates") -Type MultiString

# Configure guest account for anonymous browse
net user Guest /active:yes 2>$null

# Create the SMB share
New-SmbShare -Name "Updates" `
    -Path $shareDir `
    -Description "DroneCorp Firmware Update Distribution Share" `
    -FullAccess "Everyone" `
    -ReadAccess "Guest" `
    -FolderEnumerationMode AccessBased

# Set NTFS permissions — allow read for Everyone
$acl = Get-Acl $shareDir
$accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
    "Everyone", "ReadAndExecute", "ContainerInherit,ObjectInherit", "None", "Allow"
)
$acl.SetAccessRule($accessRule)
Set-Acl -Path $shareDir -AclObject $acl

Write-Host "[+] SMB share 'Updates' configured at $shareDir" -ForegroundColor Green

# =============================================================================
# 3. DEPLOY SCRIPT WITH HARDCODED CREDENTIALS (Flag_8)
# =============================================================================
Write-Host "[*] Creating deploy script with hardcoded credentials..." -ForegroundColor Cyan

# The deploy script with hardcoded svc_deploy credentials + Flag_8 embedded
$deployScript = @'
# =============================================================================
# DroneCorp — Firmware Update Deployment Script
# deploy_update.ps1 | Version 2.1.4
# Author: DroneCorp IT (10.10.50.150)
# Last modified: 2026-07-12
# =============================================================================
# Distributes firmware updates to drone fleet endpoints.
# Requires: svc_deploy service account with write access to drone workstations.
# =============================================================================
# flag{sh4r3_1s_c4r3}
# =============================================================================

param(
    [string]$TargetHost = "10.10.50.50",
    [string]$FirmwareVersion = "v2.4.2",
    [string]$FirmwareFile = "C:\DroneUpdates\firmware\px4_v2.4.2.bin"
)

# -----------------------------------------------------------------------
# Service Account Credentials
# TODO: move to vault/secrets manager — temp password for testing
# Ticket: IT-2026-0034 (open since Jan 2026 — low priority apparently)
# -----------------------------------------------------------------------
$svcUser = "svc_deploy"
$svcPass = "Deploy@2024!Drone"   # <-- TODO: remove hardcoded password!

$credential = New-Object System.Management.Automation.PSCredential(
    $svcUser,
    (ConvertTo-SecureString $svcPass -AsPlainText -Force)
)

Write-Host "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] DroneCorp Firmware Deployment v2.1.4"
Write-Host "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Target: $TargetHost | Firmware: $FirmwareVersion"

try {
    # Connect to target
    $session = New-PSSession -ComputerName $TargetHost -Credential $credential

    # Copy firmware file
    Copy-Item -Path $FirmwareFile -Destination "C:\ProgramData\DroneFirmware\" -ToSession $session

    # Trigger update agent on target
    Invoke-Command -Session $session -ScriptBlock {
        Start-Service -Name "DroneUpdateAgent"
        Write-Host "DroneUpdateAgent started. Firmware deployment initiated."
    }

    Remove-PSSession $session
    Write-Host "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Deployment complete: $TargetHost — $FirmwareVersion"

    # Log to DB (legacy connection — update if DB changes)
    # DB host: 10.10.50.100 | user: tech2 | pass: adfGt54DCf
    # TODO: implement DB logging (currently skipped)

} catch {
    Write-Host "[ERROR] Deployment failed: $_" -ForegroundColor Red
    exit 1
}
'@

Set-Content -Path "$shareDir\deploy_update.ps1" -Value $deployScript

# Firmware directory stub
New-Item -ItemType Directory -Path "$shareDir\firmware" -Force | Out-Null
New-Item -ItemType File -Path "$shareDir\firmware\px4_v2.4.2.bin" -Force | Out-Null
Set-Content -Path "$shareDir\firmware\px4_v2.4.2.bin" -Value "DRONECORP_FW_v2.4.2_BINARY_PLACEHOLDER"
Set-Content -Path "$shareDir\firmware\px4_v2.4.2.sha256" -Value "6f1a2b3c4d5e6f1a2b3c4d5e6f1a2b3c4d5e6f1a2b3c4d5e6f1a2b3c4d5e6f1a"

# Readme in share
$shareReadme = @"
DroneCorp Firmware Distribution Share
======================================
This share contains firmware packages for distribution to drone fleet workstations.

Contents:
  deploy_update.ps1  — automated deployment script
  firmware\          — firmware binary packages
  README.txt         — this file

Access: svc_deploy account (contact IT helpdesk)
Server: IT Department, 10.10.50.150

NOTE: Do not modify files in this share without IT approval.
"@
Set-Content -Path "$shareDir\README.txt" -Value $shareReadme

Write-Host "[+] Deploy script and Flag_8 placed in share." -ForegroundColor Green

# =============================================================================
# 4. INSTALL DroneUpdateAgent SERVICE — UNQUOTED PATH VULNERABILITY
# =============================================================================
Write-Host "[*] Creating vulnerable DroneUpdateAgent service..." -ForegroundColor Cyan

# Create the actual service binary directory (with space in path)
$agentDir = "C:\Program Files\Drone Update Agent"
New-Item -ItemType Directory -Path $agentDir -Force | Out-Null

# Write a minimal fake agent binary (batch wrapper for realism)
# In production: replace with a real compiled .exe
# For CTF: we use a PowerShell script renamed as .exe launcher
$agentScript = @'
# DroneUpdateAgent — DroneCorp Firmware Update Service
# This is the main update agent. It polls for new firmware and applies updates.
Write-EventLog -LogName Application -Source "DroneUpdateAgent" -EventId 1001 -EntryType Information -Message "DroneUpdateAgent started. Polling for updates..." -ErrorAction SilentlyContinue
Start-Sleep -Seconds 30
Write-EventLog -LogName Application -Source "DroneUpdateAgent" -EventId 1002 -EntryType Information -Message "DroneUpdateAgent polling cycle complete." -ErrorAction SilentlyContinue
'@
# Create a stub exe (actually a renamed PowerShell — in a real lab, compile a proper stub)
$agentContent = "DRONE_UPDATE_AGENT_STUB_v1.4.2"
Set-Content -Path "$agentDir\agent.exe" -Value $agentContent

# Set write permissions on C:\Program Files\ for Everyone (CTF vulnerability)
# This is the key misconfiguration that enables the unquoted path attack
$pfAcl = Get-Acl "C:\Program Files"
$writeRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
    "Everyone", "Write,CreateFiles,CreateDirectories", "None", "None", "Allow"
)
$pfAcl.AddAccessRule($writeRule)
Set-Acl -Path "C:\Program Files" -AclObject $pfAcl

# Allow svc_deploy to write to C:\Program Files\
$writeRule2 = New-Object System.Security.AccessControl.FileSystemAccessRule(
    "svc_deploy", "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow"
)
$pfAcl.AddAccessRule($writeRule2)
Set-Acl -Path "C:\Program Files" -AclObject $pfAcl

Write-Host "[+] Writable C:\Program Files\ configured." -ForegroundColor Green

# Register the DroneUpdateAgent service with UNQUOTED path (the vulnerability)
sc.exe create "DroneUpdateAgent" `
    binPath= "C:\Program Files\Drone Update Agent\agent.exe" `
    DisplayName= "DroneCorp Drone Update Agent" `
    start= "auto" `
    obj= "LocalSystem" 2>$null

sc.exe description "DroneUpdateAgent" "DroneCorp automated firmware update agent for UAV fleet." 2>$null

# Grant svc_deploy the right to start/stop the service
# This is needed for the privilege escalation to work
sc.exe sdset "DroneUpdateAgent" "D:(A;;RPWPCR;;;SY)(A;;RPWPCR;;;BA)(A;;RPWPCRDTLOSWSDRC;;;S-1-5-21-*)" 2>$null

# Use sc sdshow to grant service control to svc_deploy
# (The SDDL below grants start/stop/pause/query to svc_deploy — simplified for CTF)
# In practice, use sysinternals accesschk to verify
$svcSddl = "D:(A;;CCLCSWRPWPDTLOCRRC;;;SY)(A;;CCDCLCSWRPWPDTLOCRSDRCWDWO;;;BA)" +
            "(A;;CCLCSWRPWPDTLOCRRC;;;svc_deploy)" +
            "(A;;CCLCSWLOCRRC;;;IU)(A;;CCLCSWLOCRRC;;;SU)"
sc.exe sdset "DroneUpdateAgent" $svcSddl 2>$null

Write-Host "[+] DroneUpdateAgent service created with unquoted path." -ForegroundColor Green
Write-Host "    Path: C:\Program Files\Drone Update Agent\agent.exe" -ForegroundColor Yellow
Write-Host "    Attack vector: drop malicious C:\Program Files\Drone.exe" -ForegroundColor Yellow

# =============================================================================
# 5. FLAG_9 — Administrator Desktop
# =============================================================================
Write-Host "[*] Placing Flag_9 on Administrator Desktop..." -ForegroundColor Cyan

$adminDesktop = "C:\Users\Administrator\Desktop"
New-Item -ItemType Directory -Path $adminDesktop -Force | Out-Null

# Flag_9 embedded in admin_notes.txt (admin-only)
$adminNotes = @"
DroneCorp IT — Administrator Notes
=====================================
Server: Windows Update Server (10.10.50.150)
Role: Firmware distribution & update orchestration

Access log key: flag{unqu0ted_p4th_pwn}

Pending tasks:
- Migrate svc_deploy creds to vault (IT-2026-0034)
- Review DroneUpdateAgent service path (unquoted — known issue)
- Update firmware signing certificates (expires 2027-01)

Contact: it-admin@dronecorp.internal
"@
Set-Content -Path "$adminDesktop\admin_notes.txt" -Value $adminNotes

# Restrict to Administrator only
$flag9Acl = Get-Acl "$adminDesktop\admin_notes.txt"
$flag9Acl.SetAccessRuleProtection($true, $false)
$adminRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
    "Administrator", "FullControl", "Allow"
)
$systemRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
    "SYSTEM", "FullControl", "Allow"
)
$adminsRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
    "Administrators", "FullControl", "Allow"
)
$flag9Acl.AddAccessRule($adminRule)
$flag9Acl.AddAccessRule($systemRule)
$flag9Acl.AddAccessRule($adminsRule)
Set-Acl -Path "$adminDesktop\admin_notes.txt" -AclObject $flag9Acl

Write-Host "[+] Flag_9 embedded in $adminDesktop\admin_notes.txt" -ForegroundColor Green

# =============================================================================
# 6. FLAG_10 + UPDATE SERVER CREDENTIALS — Registry (Admin-only)
# =============================================================================
Write-Host "[*] Creating Flag_10 registry key (admin-only)..." -ForegroundColor Cyan

# Create the registry path
$regPath = "HKLM:\SOFTWARE\DroneCorp\UpdateSync"
New-Item -Path "HKLM:\SOFTWARE\DroneCorp" -Force | Out-Null
New-Item -Path $regPath -Force | Out-Null

# Set the values
New-ItemProperty -Path $regPath -Name "server_ip"    -Value "192.168.125.55" -PropertyType String -Force
New-ItemProperty -Path $regPath -Name "ssh_login"    -Value "grayraven"      -PropertyType String -Force
New-ItemProperty -Path $regPath -Name "ssh_password" -Value "grayraven124"   -PropertyType String -Force
New-ItemProperty -Path $regPath -Name "flag_final"   -Value "flag{f0und_th3_k3ys}" -PropertyType String -Force
New-ItemProperty -Path $regPath -Name "description"  -Value "Update Server SSH credentials for firmware sync" -PropertyType String -Force

# Also create a config file at ProgramData (admin-only ACL)
$configDir = "C:\ProgramData\DroneOps"
New-Item -ItemType Directory -Path $configDir -Force | Out-Null

$updateConfig = @"
; DroneCorp UpdateSync Configuration
; Classification: CONFIDENTIAL — IT Administrator access only
; Last updated: 2026-07-10 by IT Department

[UpdateServer]
server_ip    = 192.168.125.55
ssh_login    = grayraven
ssh_password = grayraven124
ssh_port     = 22

[Flags]
flag_final   = flag{f0und_th3_k3ys}

[Notes]
; This file contains credentials for the remote Update Server.
; Access is restricted to Administrators only.
; Contact IT helpdesk if you need access.
"@
Set-Content -Path "$configDir\update_server.conf" -Value $updateConfig

# Set ACL on config file — Administrators only, deny svc_deploy
$confAcl = Get-Acl "$configDir\update_server.conf"
$confAcl.SetAccessRuleProtection($true, $false)

$adminsFullRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
    "Administrators", "FullControl", "Allow"
)
$systemFullRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
    "SYSTEM", "FullControl", "Allow"
)
$svcDenyRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
    "svc_deploy", "ReadAndExecute,Write,Modify", "Deny"
)
$confAcl.AddAccessRule($adminsFullRule)
$confAcl.AddAccessRule($systemFullRule)
$confAcl.AddAccessRule($svcDenyRule)
Set-Acl -Path "$configDir\update_server.conf" -AclObject $confAcl

# Set ACL on registry key — deny svc_deploy
$regAcl = Get-Acl $regPath
$regDenyRule = New-Object System.Security.AccessControl.RegistryAccessRule(
    "svc_deploy", "ReadKey", "Deny"
)
$regAcl.AddAccessRule($regDenyRule)
Set-Acl -Path $regPath -AclObject $regAcl

Write-Host "[+] Flag_10 placed in registry and $configDir\update_server.conf" -ForegroundColor Green
Write-Host "    Both locations: admin-only, svc_deploy access DENIED." -ForegroundColor Yellow

# =============================================================================
# 7. REALISTIC CONTENT — IT Server appearance
# =============================================================================
Write-Host "[*] Creating realistic IT server content..." -ForegroundColor Cyan

# IT ticketing stub
$ticketsDir = "C:\DroneOps\Tickets"
New-Item -ItemType Directory -Path $ticketsDir -Force | Out-Null

$tickets = @"
DroneCorp IT Helpdesk — Open Tickets
=====================================
Generated: 2026-08-28

TICKET-2026-0187 [OPEN/LOW]  - PostgreSQL 14 migration (DB 10.10.50.100) — assigned: tech2
TICKET-2026-0034 [OPEN/LOW]  - Move svc_deploy password to vault — assigned: IT Admin
TICKET-2026-0201 [OPEN/MED]  - Gimbal part delivery tracking — assigned: Procurement
TICKET-2026-0215 [OPEN/HIGH] - DRONE017 ESC replacement sourcing — assigned: Tech-1
TICKET-2026-0098 [CLOSED]    - QGroundControl license renewal (done 2025-09-14) — closed
TICKET-2026-0112 [OPEN/MED]  - Windows Server license renewal (due 2026-09-15) — assigned: IT Admin
TICKET-2026-0145 [OPEN/LOW]  - OpenVPN Access Server license renewal — assigned: IT Admin
TICKET-2026-0188 [CLOSED]    - DRONE008 GPS module order (fulfilled 2026-08-16) — closed
TICKET-2026-0192 [OPEN/LOW]  - ELK Stack log retention policy review — assigned: IT Security
TICKET-2026-0199 [OPEN/HIGH] - Mandatory firmware v2.4.2 rollout completion — assigned: grayraven
"@
Set-Content -Path "$ticketsDir\open_tickets.txt" -Value $tickets

# Software license inventory on the server
$licenseDir = "C:\DroneOps\Licenses"
New-Item -ItemType Directory -Path $licenseDir -Force | Out-Null

$licenseLog = @"
DroneCorp Software License Registry
=====================================
Server: 10.10.50.150 | IT Department

QGroundControl Enterprise x5 — 1st UAV Sqn — Expires 2026-09-15  [RENEWAL PENDING]
QGroundControl Enterprise x3 — 2nd ISR Sqn — Expires 2026-09-15  [RENEWAL PENDING]
Windows Server 2019 Std     — This server   — Expires 2027-11-01
Microsoft Office 365 x20    — All staff     — Expires 2026-12-31
PX4 Pro License x10         — Fleet-wide    — Expires 2028-02-15
OpenVPN Access Server        — Comms Team   — EXPIRED 2026-07-31  [RENEWAL IN PROCESS]

See: database 10.10.50.100 / table software_licenses for full registry.
"@
Set-Content -Path "$licenseDir\license_registry.txt" -Value $licenseLog

# Event log source registration
New-EventLog -LogName Application -Source "DroneUpdateAgent" -ErrorAction SilentlyContinue

# Scheduled task for "daily sync" — realism
$taskAction = New-ScheduledTaskAction -Execute "PowerShell.exe" `
    -Argument "-NoProfile -File C:\DroneUpdates\deploy_update.ps1 -TargetHost 10.10.50.50"
$taskTrigger = New-ScheduledTaskTrigger -Daily -At "03:00"
$taskSettings = New-ScheduledTaskSettingsSet -StartWhenAvailable
Register-ScheduledTask -TaskName "DroneFirmwareSync" `
    -Action $taskAction `
    -Trigger $taskTrigger `
    -Settings $taskSettings `
    -RunLevel Highest `
    -Description "Daily firmware sync to drone fleet workstations" `
    -Force

Write-Host "[+] Realistic IT server content created." -ForegroundColor Green

# =============================================================================
# 8. HOSTNAME
# =============================================================================
Rename-Computer -NewName "DRONEOPS-WIN" -Force -ErrorAction SilentlyContinue

# =============================================================================
# 9. ENABLE SMB v1 (for compatibility with older smbclient — optional realism)
# =============================================================================
# Enable-WindowsOptionalFeature -Online -FeatureName SMB1Protocol -NoRestart -ErrorAction SilentlyContinue

# Enable SMB v2/v3 (default on Server 2019, just ensure it's on)
Set-SmbServerConfiguration -EnableSMB2Protocol $true -Force

# =============================================================================
# 10. FIREWALL — allow SMB from 10.10.50.0/24
# =============================================================================
New-NetFirewallRule -DisplayName "DroneCorp SMB Allow Internal" `
    -Direction Inbound `
    -Protocol TCP `
    -LocalPort 445 `
    -RemoteAddress "10.10.50.0/24" `
    -Action Allow `
    -Profile Any `
    -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "============================================================" -ForegroundColor Green
Write-Host "[+] Windows Server 2019 setup COMPLETE." -ForegroundColor Green
Write-Host ""
Write-Host "    Share:  \\10.10.50.150\Updates  (anonymous/guest)" -ForegroundColor Cyan
Write-Host "    Flag_8: \\10.10.50.150\Updates\deploy_update.ps1 (comment)" -ForegroundColor Cyan
Write-Host "    Flag_9: C:\Users\Administrator\Desktop\admin_notes.txt" -ForegroundColor Cyan
Write-Host "    Flag_10: HKLM\SOFTWARE\DroneCorp\UpdateSync" -ForegroundColor Cyan
Write-Host "             C:\ProgramData\DroneOps\update_server.conf" -ForegroundColor Cyan
Write-Host ""
Write-Host "    Unquoted path: C:\Program Files\Drone Update Agent\agent.exe" -ForegroundColor Yellow
Write-Host "    Attack: drop C:\Program Files\Drone.exe -> restart DroneUpdateAgent" -ForegroundColor Yellow
Write-Host "    Verify writable: icacls 'C:\Program Files'" -ForegroundColor Yellow
Write-Host "    Recon cmd: wmic service get name,pathname,startmode | findstr /i /v 'C:\\Windows'" -ForegroundColor Yellow
Write-Host "============================================================" -ForegroundColor Green
Write-Host ""
Write-Host "NOTE: Restart required to finalize hostname change to DRONEOPS-WIN" -ForegroundColor Yellow
