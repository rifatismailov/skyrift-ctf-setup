#!/bin/bash
# =============================================================================
# SkyRift CTF — Operator_station Setup Script
# Machine: 10.10.50.50 | Ubuntu 22.04 Desktop
# Users: operator (CTF entry), commador (privesc target)
# Flags: Flag_4 (flag{n1ce_t0_s33_y0u}), Flag_5 (flag{Y0u_l1ke_privileges})
# =============================================================================
# Run as root: sudo bash 01_operator_station_setup.sh
# =============================================================================

set -e

echo "[*] SkyRift — Operator_station setup starting..."

# =============================================================================
# 1. CREATE USERS
# =============================================================================
echo "[*] Creating users..."

# operator — CTF entry point
# Group 'operator' may exist as system group — use -g if so, else create fresh
if ! id operator &>/dev/null; then
    if getent group operator &>/dev/null; then
        useradd -m -s /bin/bash -g operator -c "Drone Operator, 1st UAV Squadron" operator
    else
        useradd -m -s /bin/bash -c "Drone Operator, 1st UAV Squadron" operator
    fi
fi
echo "operator:3edcVFR456" | chpasswd

# commador — privilege escalation target
if ! id commador &>/dev/null; then
    useradd -m -s /bin/bash -c "Commander, 1st UAV Squadron" commador
fi
echo "commador:C0mm4nd3r!@#Skyr1ft" | chpasswd

# Ensure operator is NOT in commador group
gpasswd -d operator commador 2>/dev/null || true

# =============================================================================
# 2. FLAG_4 — placed in /home/operator/flag.txt
# =============================================================================
echo "[*] Placing Flag_4..."
cat > /home/operator/flag.txt << 'EOF'
flag{n1ce_t0_s33_y0u}
EOF
chmod 644 /home/operator/flag.txt
chown operator:operator /home/operator/flag.txt

# =============================================================================
# 3. REALISTIC CONTENT — operator home directory
# =============================================================================
echo "[*] Populating operator home with realistic drone operator content..."

# --- QGroundControl stub ---
mkdir -p /home/operator/Applications
# QGroundControl AppImage stub (just a marker file for realism)
touch /home/operator/Applications/QGroundControl.AppImage
chmod +x /home/operator/Applications/QGroundControl.AppImage

mkdir -p /home/operator/.config/QGroundControl.org
cat > /home/operator/.config/QGroundControl.org/QGroundControl.conf << 'EOF'
[General]
SettingsVersion=6
LastConnectedLink=MAVLinkUDP
DefaultVideoSource=VideoStream
AutoConnectToMAVLink=true

[MAVLink]
GCSSystemID=255
HeartbeatRate=1
UDPListenPort=14550
UDPTargetHostIP=10.10.50.50

[VideoReceiver]
VideoUDPPort=5600
VideoRTSPUrl=rtsp://0.0.0.0:8554/live

[AppSettings]
OfflineMapProvider=Google
SavePath=/home/operator/missions
EOF

# --- Mission files (QGroundControl .plan format) ---
mkdir -p /home/operator/missions

cat > /home/operator/missions/SORTIE_2026-08-01_DRONE042.plan << 'EOF'
{
    "fileType": "Plan",
    "geoFence": { "circles": [], "polygons": [], "version": 2 },
    "groundStation": "QGroundControl",
    "mission": {
        "cruiseSpeed": 15,
        "firmwareType": 12,
        "globalPlanAltitudeMode": 1,
        "hoverSpeed": 5,
        "items": [
            { "autoContinue": true, "command": 22, "frame": 3, "params": [15, 0, 0, 0, 48.45210, 35.46120, 100], "type": "SimpleItem" },
            { "autoContinue": true, "command": 16, "frame": 3, "params": [0, 0, 0, 0, 48.45380, 35.46240, 80],  "type": "SimpleItem" },
            { "autoContinue": true, "command": 16, "frame": 3, "params": [0, 0, 0, 0, 48.45510, 35.46400, 80],  "type": "SimpleItem" },
            { "autoContinue": true, "command": 16, "frame": 3, "params": [0, 0, 0, 0, 48.45620, 35.46580, 80],  "type": "SimpleItem" },
            { "autoContinue": true, "command": 20, "frame": 3, "params": [0, 0, 0, 0, 48.45210, 35.46120, 0],   "type": "SimpleItem" }
        ],
        "plannedHomePosition": [48.45210, 35.46120, 0],
        "vehicleType": 2,
        "version": 2
    },
    "rallyPoints": { "points": [], "version": 2 },
    "version": 1
}
EOF

cat > /home/operator/missions/SORTIE_2026-08-05_DRONE017.plan << 'EOF'
{
    "fileType": "Plan",
    "geoFence": { "circles": [], "polygons": [], "version": 2 },
    "groundStation": "QGroundControl",
    "mission": {
        "cruiseSpeed": 12,
        "firmwareType": 12,
        "globalPlanAltitudeMode": 1,
        "hoverSpeed": 4,
        "items": [
            { "autoContinue": true, "command": 22, "frame": 3, "params": [10, 0, 0, 0, 48.44910, 35.45830, 120], "type": "SimpleItem" },
            { "autoContinue": true, "command": 16, "frame": 3, "params": [0, 0, 0, 0, 48.45100, 35.46010, 100],  "type": "SimpleItem" },
            { "autoContinue": true, "command": 16, "frame": 3, "params": [0, 0, 0, 0, 48.45270, 35.46190, 100],  "type": "SimpleItem" },
            { "autoContinue": true, "command": 20, "frame": 3, "params": [0, 0, 0, 0, 48.44910, 35.45830, 0],    "type": "SimpleItem" }
        ],
        "plannedHomePosition": [48.44910, 35.45830, 0],
        "vehicleType": 2,
        "version": 2
    },
    "rallyPoints": { "points": [], "version": 2 },
    "version": 1
}
EOF

cat > /home/operator/missions/SORTIE_2026-08-12_DRONE031_NIGHT.plan << 'EOF'
{
    "fileType": "Plan",
    "geoFence": {
        "circles": [],
        "polygons": [
            { "inclusion": true, "polygon": [[48.4490,35.4570],[48.4490,35.4650],[48.4560,35.4650],[48.4560,35.4570]] }
        ],
        "version": 2
    },
    "groundStation": "QGroundControl",
    "mission": {
        "cruiseSpeed": 10,
        "firmwareType": 12,
        "globalPlanAltitudeMode": 1,
        "hoverSpeed": 3,
        "items": [
            { "autoContinue": true, "command": 22, "frame": 3, "params": [8, 0, 0, 0, 48.45020, 35.45920, 60],  "type": "SimpleItem" },
            { "autoContinue": true, "command": 16, "frame": 3, "params": [0, 0, 0, 0, 48.45180, 35.46050, 50],  "type": "SimpleItem" },
            { "autoContinue": true, "command": 16, "frame": 3, "params": [0, 0, 0, 0, 48.45300, 35.46200, 50],  "type": "SimpleItem" },
            { "autoContinue": true, "command": 20, "frame": 3, "params": [0, 0, 0, 0, 48.45020, 35.45920, 0],   "type": "SimpleItem" }
        ],
        "plannedHomePosition": [48.45020, 35.45920, 0],
        "vehicleType": 2,
        "version": 2
    },
    "rallyPoints": { "points": [], "version": 2 },
    "version": 1
}
EOF

# --- Flight logs (MAVLink-style text logs) ---
mkdir -p /home/operator/logs

cat > /home/operator/logs/flight_DRONE042_20260801.log << 'EOF'
[2026-08-01 06:12:33] SYSTEM  Boot sequence complete. MAVLink v2 active.
[2026-08-01 06:12:35] INFO    Drone ID: DRONE042 | Serial: DRN-042-SKYR
[2026-08-01 06:12:36] INFO    GPS fix acquired. Sats: 14 | HDOP: 0.82
[2026-08-01 06:12:40] COMM    QGC connected @ 14550/UDP
[2026-08-01 06:13:01] INFO    Battery: 98% | 22.1V
[2026-08-01 06:13:10] CMD     ARM received — pre-arm checks passed
[2026-08-01 06:13:15] FLIGHT  TAKEOFF initiated. Alt target: 100m
[2026-08-01 06:14:02] FLIGHT  Cruising. Speed: 15.1 m/s | Alt: 100.2m
[2026-08-01 06:21:44] FLIGHT  WP2 reached. Heading 047°
[2026-08-01 06:29:12] FLIGHT  WP3 reached. Heading 063°
[2026-08-01 06:38:55] FLIGHT  WP4 reached. Descending to 80m.
[2026-08-01 06:51:07] FLIGHT  RTL initiated. Battery: 42%
[2026-08-01 06:58:33] FLIGHT  LANDED. Mission complete.
[2026-08-01 06:58:35] INFO    Flight time: 45m 18s | Distance: 12.4 km
[2026-08-01 06:58:36] SYSTEM  Disarm. Logging closed.
EOF

cat > /home/operator/logs/flight_DRONE017_20260805.log << 'EOF'
[2026-08-05 14:30:00] SYSTEM  Boot sequence complete. MAVLink v2 active.
[2026-08-05 14:30:02] INFO    Drone ID: DRONE017 | Serial: DRN-017-SKYR
[2026-08-05 14:30:05] INFO    GPS fix acquired. Sats: 11 | HDOP: 1.14
[2026-08-05 14:30:09] COMM    QGC connected @ 14550/UDP
[2026-08-05 14:30:20] INFO    Battery: 100% | 22.4V
[2026-08-05 14:30:31] CMD     ARM received — pre-arm checks passed
[2026-08-05 14:30:35] FLIGHT  TAKEOFF initiated. Alt target: 120m
[2026-08-05 14:31:20] FLIGHT  Cruising. Speed: 12.3 m/s | Alt: 120.1m
[2026-08-05 14:48:10] WARN    Wind speed elevated: 8.2 m/s. Auto-hold engaged.
[2026-08-05 14:48:50] INFO    Wind nominal. Resuming mission.
[2026-08-05 15:02:44] FLIGHT  WP3 reached.
[2026-08-05 15:09:31] FLIGHT  RTL initiated. Battery: 38%
[2026-08-05 15:16:02] FLIGHT  LANDED. Mission complete.
[2026-08-05 15:16:03] INFO    Flight time: 45m 23s | Distance: 9.8 km
EOF

cat > /home/operator/logs/flight_DRONE031_20260812_NIGHT.log << 'EOF'
[2026-08-12 21:05:00] SYSTEM  Boot. Night mode active (IR cam enabled).
[2026-08-12 21:05:03] INFO    Drone ID: DRONE031 | Serial: DRN-031-SKYR
[2026-08-12 21:05:10] INFO    GPS fix. Sats: 9 | HDOP: 1.52
[2026-08-12 21:05:15] WARN    HDOP marginal for night ops. Operator confirmed proceed.
[2026-08-12 21:05:22] COMM    QGC connected @ 14550/UDP
[2026-08-12 21:05:35] INFO    Battery: 100% | 22.3V
[2026-08-12 21:05:50] CMD     ARM received
[2026-08-12 21:06:00] FLIGHT  TAKEOFF. Alt target: 60m
[2026-08-12 21:06:45] FLIGHT  Cruising at 10 m/s | Alt: 60.4m
[2026-08-12 21:24:12] ERROR   Camera gimbal stall detected. Resetting...
[2026-08-12 21:24:20] INFO    Gimbal recovered.
[2026-08-12 21:41:09] FLIGHT  RTL. Battery: 31%
[2026-08-12 21:47:55] FLIGHT  LANDED.
[2026-08-12 21:47:56] INFO    Flight time: 41m 55s | Distance: 6.1 km
EOF

cat > /home/operator/logs/flight_errors_summary.log << 'EOF'
=== Flight Error Summary — August 2026 ===

DRONE042 20260801: OK. No errors.
DRONE017 20260805: WARN wind hold (1 event, auto-resolved).
DRONE031 20260812: ERROR gimbal stall (recovered mid-flight). Recommend inspection before next sortie.
DRONE008 20260815: ABORT — GPS lost during takeoff. Mission cancelled. Drone recovered manually.
DRONE055 20260818: OK. Minor comm lag (>200ms) during WP2. Logged for review.
DRONE017 20260820: ERROR — Motor 3 overcurrent at T+12min. Emergency RTL. Drone grounded for maintenance.
DRONE042 20260822: OK.
DRONE031 20260825: OK. Night sortie. IR cam functional.
DRONE008 20260827: OK. GPS issue from 20260815 resolved after firmware update.
DRONE055 20260829: WARN — low battery alert at 25% (mission abbreviated).
EOF

# --- Shift reports ---
mkdir -p /home/operator/shift_reports

cat > /home/operator/shift_reports/shift_report_2026-08-01.md << 'EOF'
# Shift Report — 2026-08-01
**Operator:** Mykola Bondar (callsign: OPERATOR-1)
**Shift:** 05:30 – 14:00

## Completed sorties
| Drone | Mission | Duration | Status |
|-------|---------|----------|--------|
| DRONE042 | SORTIE_2026-08-01_DRONE042 | 45m 18s | OK |

## Issues
- None.

## Notes
- DRONE042 battery performance nominal. No maintenance needed.
- Next scheduled sortie: DRONE017 on 2026-08-05 (afternoon).
EOF

cat > /home/operator/shift_reports/shift_report_2026-08-05.md << 'EOF'
# Shift Report — 2026-08-05
**Operator:** Mykola Bondar (callsign: OPERATOR-1)
**Shift:** 13:00 – 21:00

## Completed sorties
| Drone | Mission | Duration | Status |
|-------|---------|----------|--------|
| DRONE017 | SORTIE_2026-08-05_DRONE017 | 45m 23s | OK (wind hold x1) |

## Issues
- Wind gust caused auto-hold at T+17min. Resolved automatically. Mission continued.

## Notes
- Check DRONE017 gimbal before next sortie (precautionary).
- Spoke with commador re: DRONE031 night sortie approval — confirmed for Aug 12.
EOF

cat > /home/operator/shift_reports/shift_report_2026-08-12.md << 'EOF'
# Shift Report — 2026-08-12
**Operator:** Mykola Bondar (callsign: OPERATOR-1)
**Shift:** 20:00 – 04:00

## Completed sorties
| Drone | Mission | Duration | Status |
|-------|---------|----------|--------|
| DRONE031 | SORTIE_2026-08-12_DRONE031_NIGHT | 41m 55s | WARN (gimbal) |

## Issues
- Gimbal stall at T+18min. Auto-recovered. Recommend inspection before reuse.

## Notes
- Submitted incident report IR-2026-0812-01 to commador.
- DRONE031 moved to maintenance queue.
EOF

cat > /home/operator/shift_reports/shift_report_2026-08-15.md << 'EOF'
# Shift Report — 2026-08-15
**Operator:** Mykola Bondar (callsign: OPERATOR-1)
**Shift:** 06:00 – 14:00

## Completed sorties
| Drone | Mission | Status |
|-------|---------|--------|
| DRONE008 | RECON_2026-08-15 | ABORTED — GPS loss at takeoff |

## Issues
- DRONE008 GPS module suspected faulty. Grounded pending diagnostics.
- Mission rescheduled.

## Notes
- Requested firmware update for DRONE008 from the update server (commador approved).
- Logged ticket to tech2 team for DB record update on DRONE008 status.
EOF

# --- PX4 Autopilot config stubs ---
mkdir -p /home/operator/.px4/config

cat > /home/operator/.px4/config/px4_params_DRONE042.txt << 'EOF'
# PX4 Parameters — DRONE042 — DRN-042-SKYR
# Exported: 2026-07-28

BAT_N_CELLS=6
BAT_CAPACITY=10000
COM_ARM_EKF_AB=0.00500
COM_ARM_EKF_GB=0.00087
COM_ARM_EKF_HB=0.01000
EKF2_AID_MASK=1
EKF2_GPS_CHECK=245
EKF2_HGT_MODE=0
MC_PITCH_P=6.5
MC_ROLL_P=6.5
MC_YAW_P=2.8
MPC_XY_VEL_MAX=12
MPC_Z_VEL_MAX_UP=3
MPC_Z_VEL_MAX_DN=1.5
NAV_ACC_RAD=2
RTL_RETURN_ALT=80
RTL_LAND_DELAY=0
SYS_AUTOSTART=4001
SYS_USE_IO=0
EOF

cat > /home/operator/.px4/config/px4_params_DRONE017.txt << 'EOF'
# PX4 Parameters — DRONE017 — DRN-017-SKYR
# Exported: 2026-07-28

BAT_N_CELLS=6
BAT_CAPACITY=8000
COM_ARM_EKF_AB=0.00500
COM_ARM_EKF_GB=0.00087
EKF2_AID_MASK=1
MC_PITCH_P=6.2
MC_ROLL_P=6.2
MC_YAW_P=2.6
MPC_XY_VEL_MAX=10
RTL_RETURN_ALT=100
SYS_AUTOSTART=4001
EOF

# --- bash_history (hints for players) ---
cat > /home/operator/.bash_history << 'EOF'
ls -la
cd missions
ls
cat SORTIE_2026-08-01_DRONE042.plan
cd ..
cd logs
tail -50 flight_DRONE042_20260801.log
cd ..
sudo -l
/home/operator/Applications/QGroundControl.AppImage
ping 10.10.50.100
ping 10.10.50.150
cd shift_reports
ls
cat shift_report_2026-08-15.md
cd ..
cat flag.txt
find / -perm -4000 2>/dev/null
sudo -l
EOF
chown operator:operator /home/operator/.bash_history

# --- Set correct ownership on all operator files ---
chown -R operator:operator /home/operator/
chmod 750 /home/operator/missions /home/operator/logs /home/operator/shift_reports

# =============================================================================
# 4. VULNERABLE SUDO SCRIPT — GTFOBins command injection
# =============================================================================
echo "[*] Setting up privilege escalation script..."

mkdir -p /opt/dronecorp/tools
mkdir -p /var/log/dronecorp

# Create some real log files in /var/log/dronecorp for the "legitimate" use
for d in DRONE042 DRONE017 DRONE031 DRONE008 DRONE055; do
    touch "/var/log/dronecorp/${d}_export.log"
    echo "# Exported flight log for ${d} — $(date -d '7 days ago' '+%Y-%m-%d')" > "/var/log/dronecorp/${d}_export.log"
done

# Create the export destination directory for commador
mkdir -p /home/commador/exports
chown commador:commador /home/commador/exports
chmod 750 /home/commador/exports

# The vulnerable script
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

chmod 755 /opt/dronecorp/tools/flight_log_export.py
chown root:root /opt/dronecorp/tools/flight_log_export.py

# --- Sudoers entry ---
cat > /etc/sudoers.d/operator_dronecorp << 'EOF'
# DroneCorp — allow operator to export flight logs as commador
# Approved by: Commander Kovalenko | Date: 2026-06-15
operator ALL=(commador) NOPASSWD: /opt/dronecorp/tools/flight_log_export.py
EOF
chmod 440 /etc/sudoers.d/operator_dronecorp

# --- Also place linpeas hint (optional realism) ---
mkdir -p /opt/tools
touch /opt/tools/linpeas.sh
chmod 755 /opt/tools/linpeas.sh
echo "#!/bin/bash" > /opt/tools/linpeas.sh
echo "# Download latest: curl -L https://github.com/carlospolop/PEASS-ng/releases/latest/download/linpeas.sh | sh" >> /opt/tools/linpeas.sh

# =============================================================================
# 5. COMMADOR — flag + realistic content
# =============================================================================
echo "[*] Populating commador home directory..."

# Flag_5 is embedded in /opt/dronecorp/tools/flight_log_export.py docstring

# --- Personnel roster ---
mkdir -p /home/commador/personnel

cat > /home/commador/personnel/squadron_roster.csv << 'EOF'
ID,Callsign,FullName,Rank,Position,Unit,ClearanceLevel,AssignedDate,Status
1,OPERATOR-1,Mykola Bondar,Senior Specialist,Drone Operator,1st UAV Sqn,SECRET,2024-03-15,Active
2,OPERATOR-2,Yaroslav Kravchuk,Specialist,Drone Operator,1st UAV Sqn,SECRET,2024-05-20,Active
3,OPERATOR-3,Dmytro Lysenko,Junior Specialist,Drone Operator,1st UAV Sqn,CONFIDENTIAL,2025-01-10,Active
4,TECH-1,Andrii Shevchenko,Senior Technician,Maintenance Lead,1st UAV Sqn,SECRET,2023-11-01,Active
5,TECH-2,Olena Pryshchepa,Technician,Systems Maintenance,1st UAV Sqn,CONFIDENTIAL,2024-07-14,Active
6,INTEL-1,Sofiia Horova,Intelligence Analyst,ISR Data Analyst,1st UAV Sqn,TOP SECRET,2024-02-28,Active
7,COMMS-1,Vasyl Melnyk,Specialist,Communications,1st UAV Sqn,SECRET,2023-09-05,Active
8,COMMS-2,Iryna Kovalchuk,Junior Specialist,Communications,1st UAV Sqn,CONFIDENTIAL,2025-03-01,Active
9,ENG-1,Roman Petrenko,Senior Engineer,Firmware Engineer,DroneCorp HQ,SECRET,2022-06-18,Attached
10,ENG-2,Viktoriia Sirenko,Engineer,Avionics Engineer,DroneCorp HQ,SECRET,2023-01-25,Attached
11,SUPPLY-1,Oleksandr Tkachuk,Warrant Officer,Supply/Logistics,1st UAV Sqn,CONFIDENTIAL,2023-07-30,Active
12,MED-1,Natalia Fedorenko,Medic,Unit Medic,1st UAV Sqn,CONFIDENTIAL,2024-04-12,Active
13,DRIVER-1,Serhii Boyko,Junior Specialist,Vehicle Operator,1st UAV Sqn,UNCLASSIFIED,2025-06-01,Active
14,RESERVE-1,Taras Havryliuk,Specialist,Drone Operator (Reserve),Reserve Pool,SECRET,2024-08-01,On Leave
15,CMD,Viktor Kovalenko,Major,Squadron Commander,1st UAV Sqn,TOP SECRET,2022-01-10,Active
16,DEPUTY-1,Olha Marchenko,Captain,Deputy Commander,1st UAV Sqn,TOP SECRET,2023-03-22,Active
17,OPERATOR-4,Pavlo Hrytsenko,Specialist,Drone Operator,1st UAV Sqn,SECRET,2025-07-15,Probation
18,TECH-3,Maksym Rudenko,Junior Technician,Maintenance,1st UAV Sqn,CONFIDENTIAL,2025-08-01,Active
EOF

# --- Monthly reports ---
mkdir -p /home/commador/reports

cat > /home/commador/reports/monthly_report_2026_06.txt << 'EOF'
MONTHLY REPORT — June 2026
Commander: Major Viktor Kovalenko | 1st UAV Squadron

FLIGHT HOURS:
  Total: 312h 44m
  Operational sorties: 47
  Training sorties: 18
  Aborted: 2 (equipment faults)

DRONE FLEET STATUS (as of 2026-06-30):
  Operational: 8 / 12
  Under maintenance: 3
  Write-off: 1 (DRONE003 — motor failure, beyond repair)

NOTABLE EVENTS:
  - DRONE042 firmware successfully updated to v2.4.1 via update server.
  - Replacement parts for DRONE031 gimbal ordered from DroneCorp supplier.
  - New operator (OPERATOR-4 / Hrytsenko) completed orientation flights.

ISSUES:
  - Supply chain delay on spare rotors for X-6 series (2-week backlog).
  - DB connection to 10.10.50.100 intermittent on June 12–14 (resolved by tech2 team).

PLANNED FOR JULY:
  - Night qualification for OPERATOR-3.
  - Firmware rollout to DRONE017, DRONE031, DRONE055.
  - Quarterly inventory audit.

Signed: Major V. Kovalenko
EOF

cat > /home/commador/reports/monthly_report_2026_07.txt << 'EOF'
MONTHLY REPORT — July 2026
Commander: Major Viktor Kovalenko | 1st UAV Squadron

FLIGHT HOURS:
  Total: 298h 12m
  Operational sorties: 41
  Training sorties: 22
  Aborted: 3

DRONE FLEET STATUS (as of 2026-07-31):
  Operational: 9 / 12
  Under maintenance: 2
  Awaiting parts: 1

NOTABLE EVENTS:
  - Firmware updates completed for DRONE017, DRONE055 via update server (10.10.50.180).
  - OPERATOR-3 passed night qualification (marginal; 1 re-attempt required).
  - Quarterly inventory audit completed — 2 discrepancies in spare parts (escalated to SUPPLY-1).

ISSUES:
  - DRONE031 gimbal repair delayed due to part mismatch from supplier.
  - Communications lag reported on COMMS-2 channel on July 21. Under investigation.
  - Legacy DB backup script (/home/commador/scripts/backup_db.sh) failed Jul 3, 18, 27 — see cron logs.

PLANNED FOR AUGUST:
  - Night ISR sortie series (OPERATOR-1 lead).
  - Maintenance window for DRONE008.
  - Windows server license renewal (contact DroneCorp IT — 10.10.50.150).

Signed: Major V. Kovalenko
EOF

cat > /home/commador/reports/monthly_report_2026_08.txt << 'EOF'
MONTHLY REPORT — August 2026 (partial, in progress)
Commander: Major Viktor Kovalenko | 1st UAV Squadron

FLIGHT HOURS (to date):
  Total: 187h 30m
  Operational sorties: 28
  Training: 11
  Aborted: 2

NOTABLE EVENTS:
  - DRONE008 GPS module replaced. Firmware re-applied from update server.
  - DRONE017 motor overcurrent incident on Aug 20 — grounded for inspection.
  - Night ISR series ongoing. OPERATOR-1 performing well.

ISSUES:
  - DRONE031 gimbal stall incident (Aug 12). Incident report submitted.
  - DRONE017 grounded — motor ESC replacement required.
  - DB backup script still failing intermittently — flagged tech2.

Signed: Major V. Kovalenko (draft)
EOF

# --- Operational plans ---
mkdir -p /home/commador/plans

cat > /home/commador/plans/operational_plan_Q3_2026.txt << 'EOF'
OPERATIONAL PLAN — Q3 2026 (July – September)
1st UAV Squadron | Classification: SECRET

OBJECTIVES:
1. Maintain ≥70% drone fleet operational readiness.
2. Complete all scheduled firmware updates via DroneCorp Update Server (10.10.50.180).
3. Conduct 4 night ISR qualification exercises.
4. Reduce unscheduled maintenance events by 15% vs Q2.

PERSONNEL:
  Operators on rotation: OPERATOR-1, OPERATOR-2, OPERATOR-3 (qual pending)
  Maintenance lead: TECH-1 (primary), TECH-2 (backup)

FLEET PRIORITY:
  Priority 1: DRONE042, DRONE017, DRONE055
  Priority 2: DRONE008, DRONE031
  Priority 3: Training fleet

DATABASE COORDINATION:
  - All sortie data must be logged to dronecorp_db (host: 10.10.50.100) within 24h of mission completion.
  - DB contact: tech2 team (access via commador only).

NOTES:
  - Windows server (10.10.50.150) manages licensing and IT ticketing for the squadron.
  - Update server contacts: check /home/commador/scripts/backup_db.sh for legacy config.

Approved: Major V. Kovalenko
EOF

cat > /home/commador/plans/sortie_schedule_2026_09.txt << 'EOF'
SORTIE SCHEDULE — September 2026
1st UAV Squadron

DATE        DRONE     OPERATOR    TYPE           STATUS
2026-09-01  DRONE042  OPERATOR-1  Recon          Planned
2026-09-02  DRONE055  OPERATOR-2  Training       Planned
2026-09-03  DRONE008  OPERATOR-1  Maintenance    Planned (post-repair check)
2026-09-05  DRONE017  OPERATOR-3  Training (day) Planned (if repaired)
2026-09-08  DRONE042  OPERATOR-1  Night ISR      Planned — commador approval required
2026-09-10  DRONE031  OPERATOR-2  Recon          Planned (post-gimbal fix)
2026-09-12  DRONE055  OPERATOR-1  Recon          Planned
2026-09-15  ALL       -           Inspection     Mandatory quarterly check
2026-09-20  DRONE042  OPERATOR-1  Night ISR      Planned
2026-09-25  DRONE017  OPERATOR-2  Training       Planned
EOF

# --- Incidents ---
mkdir -p /home/commador/incidents

cat > /home/commador/incidents/IR-2026-0812-01.txt << 'EOF'
INCIDENT REPORT
Report ID: IR-2026-0812-01
Date: 2026-08-12
Reported by: OPERATOR-1 (Mykola Bondar)
Reviewed by: Major Viktor Kovalenko

DRONE: DRONE031 (Serial: DRN-031-SKYR)
MISSION: SORTIE_2026-08-12_DRONE031_NIGHT

INCIDENT: Gimbal stall at mission time T+18min. Gimbal recovered via auto-reset after ~8 seconds.
Mission continued. No data loss. Landing successful.

ROOT CAUSE: Suspected mechanical wear in gimbal pitch axis bearing. Previous replacement due Q2 2026
but delayed due to part unavailability.

ACTION TAKEN:
  - DRONE031 moved to maintenance queue (TECH-1 assigned).
  - Ordered replacement gimbal assembly (ETA: 10 business days).
  - Supplier: DronePartsUA, contact via 10.10.50.150 IT ticketing.

CORRECTIVE ACTION: No personnel action required. Equipment failure, not operator error.

Signed: Major V. Kovalenko
EOF

cat > /home/commador/incidents/IR-2026-0815-01.txt << 'EOF'
INCIDENT REPORT
Report ID: IR-2026-0815-01
Date: 2026-08-15
Reported by: OPERATOR-1 (Mykola Bondar)
Reviewed by: Major Viktor Kovalenko

DRONE: DRONE008 (Serial: DRN-008-SKYR)
MISSION: RECON_2026-08-15 (aborted)

INCIDENT: GPS lock lost during takeoff sequence (T+5s). Auto-land triggered. No injuries, drone intact.

ROOT CAUSE: GPS module hardware failure. Module replaced 2026-08-16.
Firmware re-flashed from update server (10.10.50.180).

ACTION TAKEN:
  - GPS module replaced by TECH-1.
  - Firmware update applied.
  - DB record updated (tech2).
  - Drone returned to operational status 2026-08-17.

Signed: Major V. Kovalenko
EOF

# --- Correspondence ---
mkdir -p /home/commador/correspondence

cat > /home/commador/correspondence/from_hq_2026-07-14.txt << 'EOF'
FROM: DroneCorp HQ — Engineering Division (ENG-1, Roman Petrenko)
TO:   Commander, 1st UAV Squadron
DATE: 2026-07-14
SUBJ: Firmware v2.4.2 release — mandatory update

Commander,

Firmware v2.4.2 is now available on the update server (10.10.50.180).
This release addresses a critical autopilot PID tuning regression introduced in v2.4.1.

ALL squadron drones should be updated before end of month.
Coordinate with the update server admin (grayraven) for scheduling.

Firmware update instructions are available in the update server documentation.

Regards,
Roman Petrenko
Senior Engineer, DroneCorp HQ
EOF

cat > /home/commador/correspondence/to_supplier_2026-08-13.txt << 'EOF'
FROM: Commander, 1st UAV Squadron (Major Viktor Kovalenko)
TO:   DronePartsUA — Sales (sales@dronepartsua.example)
DATE: 2026-08-13
SUBJ: Urgent order — DRONE031 gimbal assembly

Hello,

Following incident IR-2026-0812-01, we require one (1) replacement gimbal pitch assembly
compatible with our X-6 series airframe (DRN-031-SKYR).

Order reference: PO-2026-0813-UAV1
Delivery address: coordinates on file.

Please confirm availability and shipping ETA.

Viktor Kovalenko
Major, 1st UAV Squadron
EOF

cat > /home/commador/correspondence/from_it_2026-08-10.txt << 'EOF'
FROM: DroneCorp IT (Windows Server Admin, 10.10.50.150)
TO:   Commander, 1st UAV Squadron
DATE: 2026-08-10
SUBJ: Software license renewal — QGroundControl

Commander,

The QGroundControl Enterprise license for your squadron expires 2026-09-15.

Please submit your renewal request via the IT ticketing system on the Windows server (10.10.50.150).
Credentials for ticket submission: standard squadron account (svc_deploy has access to the share).

The license keys are managed centrally. No action required on individual workstations after renewal.

DroneCorp IT Department
EOF

# --- Scripts with DB credentials (the key clue for players) ---
mkdir -p /home/commador/scripts

cat > /home/commador/scripts/backup_db.sh << 'EOF'
#!/bin/bash
# Legacy backup script — DB connection info (do not share externally)
# Created: 2025-11-10 | Last modified: 2026-01-22
# FIXME: migrate to proper secrets manager (ticket IT-2026-0034, open since Jan)
#
# host: 10.10.50.100
# user: tech2
# pass: adfGt54DCf
#
pg_dump -h 10.10.50.100 -U tech2 dronecorp_db > /home/commador/backups/db_backup_$(date +%F).sql 2>/home/commador/backups/backup_$(date +%F).err

if [ $? -eq 0 ]; then
    echo "$(date): backup OK" >> /home/commador/backups/backup.log
else
    echo "$(date): BACKUP FAILED — check .err file" >> /home/commador/backups/backup.log
fi
EOF
chmod 700 /home/commador/scripts/backup_db.sh

# Backup logs showing failures (realism)
mkdir -p /home/commador/backups
cat > /home/commador/backups/backup.log << 'EOF'
2026-07-03 03:00:02: BACKUP FAILED — check .err file
2026-07-10 03:00:01: backup OK
2026-07-17 03:00:03: backup OK
2026-07-18 03:00:04: BACKUP FAILED — check .err file
2026-07-24 03:00:02: backup OK
2026-07-27 03:00:01: BACKUP FAILED — check .err file
2026-08-03 03:00:01: backup OK
2026-08-10 03:00:02: backup OK
2026-08-17 03:00:04: BACKUP FAILED — check .err file
2026-08-24 03:00:01: BACKUP FAILED — check .err file
EOF

cat > /home/commador/backups/backup_2026-07-03.err << 'EOF'
pg_dump: error: connection to server at "10.10.50.100", port 5432 failed: FATAL:  password authentication failed for user "tech2"
pg_dump: error: (additional info: connection to server on socket ... failed)
EOF

# --- Set ownership and permissions for commador ---
chown -R commador:commador /home/commador/
chmod 750 /home/commador
chown commador:commador /home/commador

# Ensure operator cannot read commador home
chmod 750 /home/commador
# operator is not in commador group — confirmed above

# =============================================================================
# 6. INSTALL QGroundControl dependencies (Ubuntu 22.04 — realistic)
# =============================================================================
echo "[*] Installing realistic packages..."
apt-get update -qq
apt-get install -y -qq \
    openssh-server \
    net-tools \
    nmap \
    curl \
    python3 \
    python3-pip \
    smbclient \
    postgresql-client-14 \
    ruby-full \
    ruby-dev \
    libreadline-dev \
    fuse \
    libgstreamer1.0-dev \
    gstreamer1.0-plugins-good \
    gstreamer1.0-plugins-bad \
    gstreamer1.0-plugins-ugly \
    gstreamer1.0-libav \
    libqt5gui5 \
    2>/dev/null || true

echo "[*] Installing evil-winrm..."
gem install evil-winrm --no-document 2>/dev/null || true

# Ensure SSH is running and operator can log in
systemctl enable ssh 2>/dev/null || true
systemctl start ssh 2>/dev/null || true

# =============================================================================
# 7. HOSTNAME
# =============================================================================
hostnamectl set-hostname operator-station 2>/dev/null || hostname operator-station

echo ""
echo "============================================================"
echo "[+] Operator_station setup COMPLETE."
echo ""
echo "    Flag_4: /home/operator/flag.txt"
echo "    Flag_5: /home/commador/flag.txt"
echo ""
echo "    Privesc:"
echo "      sudo -u commador /opt/dronecorp/tools/flight_log_export.py"
echo "      Input: ; /bin/bash ;"
echo ""
echo "    DB creds in: /home/commador/scripts/backup_db.sh"
echo "============================================================"
