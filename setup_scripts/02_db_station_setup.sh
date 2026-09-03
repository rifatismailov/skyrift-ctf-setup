#!/bin/bash
# =============================================================================
# SkyRift CTF — DB_station Setup Script
# Machine: 10.10.50.100 | Ubuntu 22.04 Desktop
# Service: PostgreSQL 10 (intentionally old/legacy)
# DB User: tech2 / adfGt54DCf (superuser — enables COPY TO PROGRAM RCE)
# Flags: Flag_6 (flag{adfGt54DCf}), Flag_7 (flag{0mg_RC3})
# =============================================================================
# Run as root: sudo bash 02_db_station_setup.sh
# =============================================================================

set -e

echo "[*] SkyRift — DB_station setup starting..."

# =============================================================================
# 1. INSTALL POSTGRESQL 10
# =============================================================================
echo "[*] Installing PostgreSQL 10..."

apt-get update -qq
apt-get install -y -qq \
    curl \
    gnupg \
    lsb-release \
    openssh-server \
    net-tools \
    python3 \
    2>/dev/null || true

# Add PostgreSQL 10 repo (Ubuntu 22.04 ships with 14; we need old version)
curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor -o /etc/apt/trusted.gpg.d/postgresql.gpg 2>/dev/null

echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list
apt-get update -qq
apt-get install -y -qq postgresql-10 2>/dev/null || {
    echo "[!] PostgreSQL 10 not available in repo, trying 12 as fallback..."
    apt-get install -y -qq postgresql-12 2>/dev/null || apt-get install -y -qq postgresql 2>/dev/null
}

# Start PostgreSQL
PG_VERSION=$(pg_lsclusters -h | awk '{print $1}' | head -1)
echo "[*] Using PostgreSQL version: ${PG_VERSION}"
systemctl enable postgresql 2>/dev/null || true
systemctl start postgresql 2>/dev/null || true

# Wait for postgres to be ready
sleep 3

# =============================================================================
# 2. CREATE DB USER AND DATABASE
# =============================================================================
echo "[*] Creating database user tech2 and database dronecorp_db..."

sudo -u postgres psql -c "DROP ROLE IF EXISTS tech2;" 2>/dev/null || true
sudo -u postgres psql -c "CREATE ROLE tech2 WITH LOGIN PASSWORD 'adfGt54DCf' SUPERUSER;"
sudo -u postgres psql -c "DROP DATABASE IF EXISTS dronecorp_db;" 2>/dev/null || true
sudo -u postgres psql -c "CREATE DATABASE dronecorp_db OWNER tech2;"

# =============================================================================
# 3. CREATE SCHEMA AND POPULATE 15 TABLES (min 25 records each)
# =============================================================================
echo "[*] Creating tables and inserting realistic data..."

sudo -u postgres psql -d dronecorp_db << 'SQLEOF'

-- ============================================================
-- TABLE 1: base_locations
-- ============================================================
CREATE TABLE base_locations (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    code VARCHAR(20) UNIQUE NOT NULL,
    lat DECIMAL(9,6),
    lon DECIMAL(9,6),
    capacity INT,
    region VARCHAR(100),
    status VARCHAR(20) DEFAULT 'Active'
);

INSERT INTO base_locations (name, code, lat, lon, capacity, region, status) VALUES
('Alpha Base',           'BASE-A', 48.452100, 35.461200, 12, 'Dnipro Region', 'Active'),
('Bravo Forward Post',   'BASE-B', 48.394500, 35.382100, 6,  'Dnipro Region', 'Active'),
('Charlie Staging Area', 'BASE-C', 48.512300, 35.521000, 4,  'Zaporizhzhia Region', 'Active'),
('Delta Depot',          'BASE-D', 48.610000, 35.280000, 8,  'Dnipro Region', 'Active'),
('Echo Support Base',    'BASE-E', 48.701200, 35.199500, 10, 'Kharkiv Region', 'Active'),
('Foxtrot Outpost',      'BASE-F', 48.310400, 35.640200, 3,  'Zaporizhzhia Region', 'Standby'),
('Golf Maintenance Hub', 'BASE-G', 48.558900, 35.448100, 15, 'Dnipro Region', 'Active'),
('Hotel Relay Point',    'BASE-H', 48.421700, 35.713400, 2,  'Zaporizhzhia Region', 'Active'),
('India Command Post',   'BASE-I', 48.642300, 35.390800, 5,  'Dnipro Region', 'Active'),
('Juliet Airfield',      'BASE-J', 48.480000, 36.012000, 20, 'Dnipro Region', 'Active'),
('Kilo Reserve',         'BASE-K', 48.380100, 35.200400, 4,  'Zaporizhzhia Region', 'Standby'),
('Lima Training Ground', 'BASE-L', 48.714500, 35.621000, 8,  'Kharkiv Region', 'Active'),
('Mike Logistics Hub',   'BASE-M', 48.529000, 35.302000, 12, 'Dnipro Region', 'Active'),
('November Forward',     'BASE-N', 48.345600, 35.780300, 2,  'Zaporizhzhia Region', 'Active'),
('Oscar Reserve Base',   'BASE-O', 48.780000, 35.510000, 6,  'Kharkiv Region', 'Active'),
('Papa Launch Site',     'BASE-P', 48.401200, 35.499000, 3,  'Dnipro Region', 'Active'),
('Quebec Relay',         'BASE-Q', 48.612000, 35.711000, 2,  'Kharkiv Region', 'Standby'),
('Romeo Staging',        'BASE-R', 48.355000, 35.350000, 5,  'Zaporizhzhia Region', 'Active'),
('Sierra Cache',         'BASE-S', 48.472000, 35.615000, 4,  'Dnipro Region', 'Active'),
('Tango Forward',        'BASE-T', 48.298000, 35.558000, 3,  'Zaporizhzhia Region', 'Active'),
('Uniform Hub',          'BASE-U', 48.664000, 35.480000, 7,  'Kharkiv Region', 'Active'),
('Victor Outpost',       'BASE-V', 48.330000, 35.880000, 2,  'Zaporizhzhia Region', 'Active'),
('Whiskey Depot',        'BASE-W', 48.500000, 36.110000, 10, 'Dnipro Region', 'Active'),
('Xray Relay',           'BASE-X', 48.420000, 36.200000, 1,  'Dnipro Region', 'Standby'),
('Yankee Forward',       'BASE-Y', 48.370000, 35.420000, 3,  'Zaporizhzhia Region', 'Active'),
('Zulu Reserve',         'BASE-Z', 48.690000, 35.320000, 6,  'Kharkiv Region', 'Active');


-- ============================================================
-- TABLE 2: squadrons
-- ============================================================
CREATE TABLE squadrons (
    id SERIAL PRIMARY KEY,
    squadron_name VARCHAR(100) NOT NULL,
    code VARCHAR(20) UNIQUE,
    commander VARCHAR(100),
    base_location_id INT REFERENCES base_locations(id),
    drone_count INT DEFAULT 0,
    personnel_count INT DEFAULT 0,
    established DATE,
    status VARCHAR(20) DEFAULT 'Active'
);

INSERT INTO squadrons (squadron_name, code, commander, base_location_id, drone_count, personnel_count, established, status) VALUES
('1st UAV Squadron',      'SQN-1', 'Major Viktor Kovalenko',   1, 12, 18, '2022-01-10', 'Active'),
('2nd ISR Squadron',      'SQN-2', 'Major Tetiana Bilyk',       4,  8, 14, '2022-06-15', 'Active'),
('3rd Strike Squadron',   'SQN-3', 'Lieutenant Colonel Mykhailo Hrytsenko', 10, 6, 10, '2023-03-01', 'Active'),
('4th Logistics Sqn',     'SQN-4', 'Captain Oksana Kravets',   7,  4,  8, '2023-07-20', 'Active'),
('5th Training Sqn',      'SQN-5', 'Captain Ihor Savchenko',  12,  5, 12, '2023-11-01', 'Active'),
('6th Reserve Squadron',  'SQN-6', 'Lieutenant Vadym Doroshenko', 11, 3, 6, '2024-02-15', 'Standby'),
('7th Night ISR Sqn',     'SQN-7', 'Major Olena Holub',         5,  4,  8, '2024-05-10', 'Active'),
('8th Strike Reserve',    'SQN-8', 'Captain Artem Kovalchuk',   2,  2,  5, '2024-08-01', 'Standby'),
('9th Forward Recon',     'SQN-9', 'Lieutenant Natalia Bondar', 6,  3,  6, '2024-10-15', 'Active'),
('10th Support Sqn',      'SQN-10','Captain Yevhen Pylypenko',  13, 4,  9, '2025-01-20', 'Active'),
('11th Reserve ISR',      'SQN-11','Lieutenant Serhii Marchenko',15, 2,  4, '2025-03-10', 'Standby'),
('12th Rapid Deployment', 'SQN-12','Major Dmytro Petrenko',      9,  5, 10, '2025-06-01', 'Active'),
('Alpha Training Cell',   'STC-A', 'Warrant Officer Inna Koval',12,  3,  5, '2025-07-15', 'Active'),
('Beta Test Cell',        'BTC-1', 'Engineer Roman Petrenko',    7,  2,  4, '2025-09-01', 'Active'),
('HQ Liaison Sqn',        'HQ-LI', 'Colonel Andriy Savenko',    1,  1,  3, '2022-01-10', 'Active'),
('Gamma Forward Sqn',     'SQN-G', 'Captain Lesia Tkachenko',   14, 4,  8, '2025-11-01', 'Active'),
('Delta ISR Sqn',         'SQN-D', 'Major Vasyl Horenko',        8,  3,  7, '2025-12-15', 'Active'),
('Epsilon Strike',        'SQN-E', 'Captain Olha Rybalko',       3,  3,  6, '2026-01-10', 'Active'),
('Zeta Night Ops',        'SQN-Z', 'Lieutenant Pavlo Zinchenko', 6,  2,  5, '2026-02-20', 'Active'),
('Eta Reserve',           'SQN-H', 'Warrant Officer Taras Koval',11,  1,  3, '2026-03-01', 'Standby'),
('Theta Logistics',       'SQN-T', 'Captain Nataliia Fedorchuk', 7,  2,  4, '2026-04-15', 'Active'),
('Iota Support',          'SQN-I', 'Lieutenant Andrii Savchuk',  13, 1,  3, '2026-05-01', 'Active'),
('Kappa Forward ISR',     'SQN-K', 'Captain Daria Bondarenko',   14, 3,  6, '2026-06-01', 'Active'),
('Lambda Strike Cell',    'SQN-L', 'Major Ivan Korolenko',        9,  2,  4, '2026-07-01', 'Active'),
('Mu Reserve Pool',       'SQN-M', 'Captain Halyna Lysak',       15, 1,  2, '2026-08-01', 'Standby');


-- ============================================================
-- TABLE 3: drones
-- ============================================================
CREATE TABLE drones (
    id SERIAL PRIMARY KEY,
    serial_number VARCHAR(50) UNIQUE NOT NULL,
    model VARCHAR(100) NOT NULL,
    squadron_id INT REFERENCES squadrons(id),
    base_location_id INT REFERENCES base_locations(id),
    firmware_version VARCHAR(20),
    status VARCHAR(30) DEFAULT 'Operational',
    manufacture_date DATE,
    last_maintenance DATE,
    total_flight_hours DECIMAL(8,2) DEFAULT 0,
    notes TEXT
);

INSERT INTO drones (serial_number, model, squadron_id, base_location_id, firmware_version, status, manufacture_date, last_maintenance, total_flight_hours, notes) VALUES
('DRN-001-SKYR','X-6 Recon',      1, 1, 'v2.4.2','Operational',  '2022-03-01','2026-07-15', 412.5,  NULL),
('DRN-002-SKYR','X-6 Recon',      1, 1, 'v2.4.2','Operational',  '2022-03-01','2026-06-20', 388.2,  NULL),
('DRN-003-SKYR','X-6 Recon',      1, 1, 'v2.3.0','Write-off',    '2022-03-01','2026-05-01', 521.0,  'Motor failure — beyond repair'),
('DRN-004-SKYR','X-6 Strike',     2, 4, 'v2.4.2','Operational',  '2022-06-15','2026-07-20', 290.3,  NULL),
('DRN-005-SKYR','X-6 Strike',     2, 4, 'v2.4.1','Maintenance',  '2022-06-15','2026-07-01', 310.8,  'ESC replacement pending'),
('DRN-006-SKYR','X-8 Heavy Lift', 3,10, 'v2.4.0','Operational',  '2023-02-10','2026-08-01', 180.1,  NULL),
('DRN-007-SKYR','X-8 Heavy Lift', 3,10, 'v2.4.2','Operational',  '2023-02-10','2026-07-25', 165.4,  NULL),
('DRN-008-SKYR','X-6 Recon',      1, 1, 'v2.4.2','Operational',  '2022-09-01','2026-08-17', 356.9,  'GPS module replaced 2026-08-16'),
('DRN-009-SKYR','X-4 Scout',      4, 7, 'v2.4.2','Operational',  '2023-07-01','2026-08-05', 140.2,  NULL),
('DRN-010-SKYR','X-4 Scout',      4, 7, 'v2.4.1','Standby',      '2023-07-01','2026-06-10', 122.7,  NULL),
('DRN-011-SKYR','X-6 Recon',      5,12, 'v2.4.2','Operational',  '2023-10-15','2026-08-12', 88.3,   'Training fleet'),
('DRN-012-SKYR','X-6 Recon',      5,12, 'v2.4.2','Operational',  '2023-10-15','2026-07-28', 79.1,   'Training fleet'),
('DRN-013-SKYR','X-8 Heavy Lift', 2, 4, 'v2.4.2','Operational',  '2023-04-20','2026-08-01', 201.6,  NULL),
('DRN-014-SKYR','X-4 Scout',      9, 6, 'v2.4.2','Operational',  '2024-01-10','2026-07-15', 65.4,   NULL),
('DRN-015-SKYR','X-4 Scout',      9, 6, 'v2.4.0','Maintenance',  '2024-01-10','2026-05-20', 72.8,   'Antenna replacement'),
('DRN-017-SKYR','X-6 Recon',      1, 1, 'v2.4.2','Maintenance',  '2022-09-01','2026-08-20', 341.7,  'Motor 3 ESC fault — grounded'),
('DRN-018-SKYR','X-6 Strike',     3,10, 'v2.4.2','Operational',  '2023-06-01','2026-08-10', 198.3,  NULL),
('DRN-019-SKYR','X-4 Scout',      7, 5, 'v2.4.2','Operational',  '2024-05-01','2026-08-15', 54.2,   'Night ISR config'),
('DRN-020-SKYR','X-4 Scout',      7, 5, 'v2.4.2','Operational',  '2024-05-01','2026-08-01', 49.8,   'Night ISR config'),
('DRN-031-SKYR','X-6 Recon',      1, 1, 'v2.4.1','Maintenance',  '2022-09-01','2026-08-12', 367.4,  'Gimbal repair — awaiting part'),
('DRN-042-SKYR','X-6 Recon',      1, 1, 'v2.4.2','Operational',  '2022-09-01','2026-08-22', 298.1,  NULL),
('DRN-055-SKYR','X-6 Recon',      1, 1, 'v2.4.2','Operational',  '2023-01-10','2026-08-18', 245.0,  'Low battery warning 2026-08-29'),
('DRN-060-SKYR','X-8 Heavy Lift',12, 9, 'v2.4.2','Operational',  '2025-06-01','2026-08-20', 32.5,   NULL),
('DRN-070-SKYR','X-4 Scout',     10,13, 'v2.4.2','Operational',  '2025-08-01','2026-08-28',  8.1,   'New; shake-down flights only'),
('DRN-099-SKYR','X-8 Heavy Lift', 4, 7, 'v2.4.0','Standby',      '2023-11-01','2026-04-10', 189.2,  'Reserve — not deployed');


-- ============================================================
-- TABLE 4: pilots
-- ============================================================
CREATE TABLE pilots (
    id SERIAL PRIMARY KEY,
    callsign VARCHAR(50) UNIQUE NOT NULL,
    full_name VARCHAR(100),
    rank VARCHAR(50),
    squadron_id INT REFERENCES squadrons(id),
    clearance_level VARCHAR(20) DEFAULT 'SECRET',
    qualifications TEXT,
    total_flight_hours DECIMAL(8,2) DEFAULT 0,
    night_qualified BOOLEAN DEFAULT FALSE,
    status VARCHAR(20) DEFAULT 'Active'
);

INSERT INTO pilots (callsign, full_name, rank, squadron_id, clearance_level, qualifications, total_flight_hours, night_qualified, status) VALUES
('OPERATOR-1',  'Mykola Bondar',       'Senior Specialist',  1, 'SECRET',     'X-4,X-6,X-8; Night qual', 1240.5, TRUE,  'Active'),
('OPERATOR-2',  'Yaroslav Kravchuk',   'Specialist',         1, 'SECRET',     'X-4,X-6; Night qual',     980.2,  TRUE,  'Active'),
('OPERATOR-3',  'Dmytro Lysenko',      'Junior Specialist',  1, 'CONFIDENTIAL','X-4,X-6',                340.8,  TRUE,  'Active'),
('OPERATOR-4',  'Pavlo Hrytsenko',     'Specialist',         1, 'SECRET',     'X-4 (probation)',         40.1,   FALSE, 'Active'),
('ISR-1',       'Kateryna Melnyk',     'Senior Specialist',  2, 'TOP SECRET', 'X-6,X-8; Night qual',    1560.3, TRUE,  'Active'),
('ISR-2',       'Bohdan Kovalenko',    'Specialist',         2, 'SECRET',     'X-6',                     720.4,  TRUE,  'Active'),
('STRIKE-1',    'Oleksii Petrenko',    'Senior Specialist',  3, 'TOP SECRET', 'X-8 Strike; Night qual', 1890.0, TRUE,  'Active'),
('STRIKE-2',    'Yulia Shvets',        'Specialist',         3, 'SECRET',     'X-8 Strike',              640.7,  FALSE, 'Active'),
('LOG-1',       'Vasyl Chorny',        'Warrant Officer',    4, 'CONFIDENTIAL','X-4',                    280.2,  FALSE, 'Active'),
('LOG-2',       'Oksana Yarova',       'Specialist',         4, 'CONFIDENTIAL','X-4',                    190.5,  FALSE, 'Active'),
('TRAIN-1',     'Ihor Savchenko',      'Captain',            5, 'SECRET',     'X-4,X-6; Instructor',    2100.8, TRUE,  'Active'),
('TRAIN-2',     'Liudmyla Fedorova',   'Specialist',         5, 'SECRET',     'X-4,X-6; Instructor',    1340.2, TRUE,  'Active'),
('NIGHT-1',     'Olena Holub',         'Major',              7, 'TOP SECRET', 'X-4,X-6; Night; ISR',    1720.5, TRUE,  'Active'),
('NIGHT-2',     'Serhii Dovhal',       'Specialist',         7, 'SECRET',     'X-4; Night qual',         420.3,  TRUE,  'Active'),
('RECON-1',     'Natalia Bondar',      'Lieutenant',         9, 'SECRET',     'X-4; Night qual',         380.1,  TRUE,  'Active'),
('RECON-2',     'Andrii Savchuk',      'Junior Specialist',  9, 'CONFIDENTIAL','X-4',                    140.5,  FALSE, 'Active'),
('SUPP-1',      'Yevhen Pylypenko',    'Captain',           10, 'SECRET',     'X-4,X-6',                 560.2,  FALSE, 'Active'),
('RAPID-1',     'Dmytro Petrenko',     'Major',             12, 'SECRET',     'X-4,X-6,X-8; Night',    1100.4, TRUE,  'Active'),
('RAPID-2',     'Inna Koval',          'Warrant Officer',   12, 'SECRET',     'X-4,X-6',                 480.7,  FALSE, 'Active'),
('FWD-1',       'Lesia Tkachenko',     'Captain',           16, 'SECRET',     'X-6; Night qual',         620.0,  TRUE,  'Active'),
('DELTA-1',     'Vasyl Horenko',       'Major',             17, 'SECRET',     'X-6,X-8; Night',         1050.3, TRUE,  'Active'),
('EPS-1',       'Olha Rybalko',        'Captain',           18, 'SECRET',     'X-8 Strike',              380.9,  FALSE, 'Active'),
('ZETA-1',      'Pavlo Zinchenko',     'Lieutenant',        19, 'SECRET',     'X-4; Night qual',         210.4,  TRUE,  'Active'),
('KAPPA-1',     'Daria Bondarenko',    'Captain',           23, 'SECRET',     'X-6; Night qual',         430.6,  TRUE,  'Active'),
('LAMBDA-1',    'Ivan Korolenko',      'Major',             24, 'SECRET',     'X-8 Strike; Night',       890.2,  TRUE,  'Active');


-- ============================================================
-- TABLE 5: firmware_versions
-- ============================================================
CREATE TABLE firmware_versions (
    id SERIAL PRIMARY KEY,
    version VARCHAR(20) UNIQUE NOT NULL,
    release_date DATE,
    compatible_models TEXT,
    changelog TEXT,
    is_stable BOOLEAN DEFAULT TRUE,
    released_by VARCHAR(100),
    checksum_sha256 VARCHAR(64)
);

INSERT INTO firmware_versions (version, release_date, compatible_models, changelog, is_stable, released_by, checksum_sha256) VALUES
('v1.0.0','2021-06-01','X-4,X-6',        'Initial release',                              TRUE, 'DroneCorp Eng', 'a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2'),
('v1.1.0','2021-09-15','X-4,X-6',        'GPS stability improvements',                    TRUE, 'DroneCorp Eng', 'b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3'),
('v1.2.0','2022-01-20','X-4,X-6',        'MAVLink v2 support added',                      TRUE, 'DroneCorp Eng', 'c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4'),
('v1.2.3','2022-03-10','X-4,X-6',        'Hotfix: RTL altitude bug',                      TRUE, 'DroneCorp Eng', 'd4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5'),
('v2.0.0','2022-07-01','X-4,X-6,X-8',   'X-8 support; geofence v2',                      TRUE, 'DroneCorp Eng', 'e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6'),
('v2.1.0','2022-10-15','X-4,X-6,X-8',   'Night ISR camera integration',                  TRUE, 'DroneCorp Eng', 'f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1'),
('v2.2.0','2023-03-20','X-4,X-6,X-8',   'Wind compensation algorithm v2',                TRUE, 'DroneCorp Eng', '1a2b3c4d5e6f1a2b3c4d5e6f1a2b3c4d5e6f1a2b3c4d5e6f1a2b3c4d5e6f1a2b'),
('v2.3.0','2023-08-01','X-4,X-6,X-8',   'EKF2 improvements; battery reporting',          TRUE, 'DroneCorp Eng', '2b3c4d5e6f1a2b3c4d5e6f1a2b3c4d5e6f1a2b3c4d5e6f1a2b3c4d5e6f1a2b3c'),
('v2.3.5','2023-11-10','X-4,X-6,X-8',   'Hotfix: gimbal PID values',                     TRUE, 'DroneCorp Eng', '3c4d5e6f1a2b3c4d5e6f1a2b3c4d5e6f1a2b3c4d5e6f1a2b3c4d5e6f1a2b3c4d'),
('v2.4.0','2024-04-15','X-4,X-6,X-8',   'Geofence v3; logging improvements',             TRUE, 'DroneCorp Eng', '4d5e6f1a2b3c4d5e6f1a2b3c4d5e6f1a2b3c4d5e6f1a2b3c4d5e6f1a2b3c4d5e'),
('v2.4.1','2025-02-20','X-4,X-6,X-8',   'Autopilot PID tuning update (regression bug!)', FALSE,'DroneCorp Eng', '5e6f1a2b3c4d5e6f1a2b3c4d5e6f1a2b3c4d5e6f1a2b3c4d5e6f1a2b3c4d5e6f'),
('v2.4.2','2025-07-14','X-4,X-6,X-8',   'Hotfix: PID regression from v2.4.1; mandatory', TRUE, 'DroneCorp Eng', '6f1a2b3c4d5e6f1a2b3c4d5e6f1a2b3c4d5e6f1a2b3c4d5e6f1a2b3c4d5e6f1a'),
('v2.4.3-beta','2026-05-01','X-4,X-6',  'Beta: new telemetry compression (not released)', FALSE,'DroneCorp Eng', '7a8b9c0d1e2f7a8b9c0d1e2f7a8b9c0d1e2f7a8b9c0d1e2f7a8b9c0d1e2f7a8b'),
('v2.5.0-dev','2026-08-01','X-4,X-6,X-8','Dev branch — do not deploy to production',      FALSE,'DroneCorp Eng', '8b9c0d1e2f7a8b9c0d1e2f7a8b9c0d1e2f7a8b9c0d1e2f7a8b9c0d1e2f7a8b9c'),
('v1.0.5-legacy','2021-12-01','X-4',     'Legacy patch — X-4 only; end of support',       FALSE,'DroneCorp Eng', '9c0d1e2f7a8b9c0d1e2f7a8b9c0d1e2f7a8b9c0d1e2f7a8b9c0d1e2f7a8b9c0d'),
('v2.0.3-hotfix','2022-09-05','X-4,X-6','Emergency hotfix: comms dropout',                TRUE, 'DroneCorp Eng', '0d1e2f7a8b9c0d1e2f7a8b9c0d1e2f7a8b9c0d1e2f7a8b9c0d1e2f7a8b9c0d1e'),
('v2.1.2','2023-01-15','X-4,X-6,X-8',   'Minor: logging verbosity controls',              TRUE, 'DroneCorp Eng', '1e2f7a8b9c0d1e2f7a8b9c0d1e2f7a8b9c0d1e2f7a8b9c0d1e2f7a8b9c0d1e2f'),
('v2.2.4','2023-06-30','X-4,X-6,X-8',   'Hotfix: geofence boundary calc error',           TRUE, 'DroneCorp Eng', '2f3a4b5c6d7e2f3a4b5c6d7e2f3a4b5c6d7e2f3a4b5c6d7e2f3a4b5c6d7e2f3a'),
('v2.3.8','2024-02-28','X-4,X-6,X-8',   'Maintenance: memory leak fix',                   TRUE, 'DroneCorp Eng', '3a4b5c6d7e2f3a4b5c6d7e2f3a4b5c6d7e2f3a4b5c6d7e2f3a4b5c6d7e2f3a4b'),
('v2.4.0-rc1','2024-03-01','X-4,X-6,X-8','RC1 for v2.4.0 — testing only',                FALSE,'DroneCorp Eng', '4b5c6d7e2f3a4b5c6d7e2f3a4b5c6d7e2f3a4b5c6d7e2f3a4b5c6d7e2f3a4b5c'),
('v2.4.0-rc2','2024-04-01','X-4,X-6,X-8','RC2 for v2.4.0',                               FALSE,'DroneCorp Eng', '5c6d7e2f3a4b5c6d7e2f3a4b5c6d7e2f3a4b5c6d7e2f3a4b5c6d7e2f3a4b5c6d'),
('v2.4.1-rc1','2025-01-10','X-4,X-6,X-8','RC1 for v2.4.1',                               FALSE,'DroneCorp Eng', '6d7e2f3a4b5c6d7e2f3a4b5c6d7e2f3a4b5c6d7e2f3a4b5c6d7e2f3a4b5c6d7e'),
('v2.4.2-rc1','2025-06-15','X-4,X-6,X-8','RC1 for v2.4.2 hotfix',                        FALSE,'DroneCorp Eng', '7e2f3a4b5c6d7e2f3a4b5c6d7e2f3a4b5c6d7e2f3a4b5c6d7e2f3a4b5c6d7e2f'),
('v2.4.2-rc2','2025-07-01','X-4,X-6,X-8','RC2 for v2.4.2 hotfix',                        FALSE,'DroneCorp Eng', '8f1a2b3c4d5e8f1a2b3c4d5e8f1a2b3c4d5e8f1a2b3c4d5e8f1a2b3c4d5e8f1a'),
('v2.4.2-r2','2026-01-20','X-4,X-6,X-8', 'Revision 2: minor telemetry fix',               TRUE, 'DroneCorp Eng', '9a0b1c2d3e4f9a0b1c2d3e4f9a0b1c2d3e4f9a0b1c2d3e4f9a0b1c2d3e4f9a0b');


-- ============================================================
-- TABLE 6: firmware_update_schedule
-- ============================================================
CREATE TABLE firmware_update_schedule (
    id SERIAL PRIMARY KEY,
    drone_id INT REFERENCES drones(id),
    firmware_version_id INT REFERENCES firmware_versions(id),
    scheduled_date DATE,
    completed_date DATE,
    status VARCHAR(20) DEFAULT 'Pending',
    performed_by VARCHAR(100),
    notes TEXT
);

INSERT INTO firmware_update_schedule (drone_id, firmware_version_id, scheduled_date, completed_date, status, performed_by, notes) VALUES
(1,  12, '2026-07-10','2026-07-12','Completed','grayraven','Via update server 10.10.50.180'),
(2,  12, '2026-07-10','2026-07-13','Completed','grayraven','Via update server 10.10.50.180'),
(4,  12, '2026-07-15','2026-07-17','Completed','grayraven',NULL),
(8,  12, '2026-08-17','2026-08-17','Completed','grayraven','Post GPS module replacement'),
(16, 12, '2026-07-12','2026-07-14','Completed','grayraven',NULL),
(21, 12, '2026-08-10',NULL,        'Pending',  NULL,       'Awaiting gimbal repair completion'),
(22, 12, '2026-08-20','2026-08-22','Completed','grayraven',NULL),
(23, 12, '2026-08-15','2026-08-18','Completed','grayraven',NULL),
(5,  10, '2026-06-01','2026-06-03','Completed','grayraven','v2.4.1 applied (later found to be buggy)'),
(5,  12, '2026-08-01',NULL,        'Pending',  NULL,       'Superseding v2.4.1 with v2.4.2'),
(11, 12, '2026-08-12','2026-08-12','Completed','grayraven',NULL),
(12, 12, '2026-08-12','2026-08-13','Completed','grayraven',NULL),
(19, 12, '2026-08-15','2026-08-16','Completed','grayraven',NULL),
(20, 12, '2026-08-15','2026-08-16','Completed','grayraven',NULL),
(24, 12, '2026-08-25','2026-08-28','Completed','grayraven','New drone initial firmware'),
(25, 10, '2026-09-01',NULL,        'Pending',  NULL,       'Scheduled Q3'),
(6,  10, '2026-09-05',NULL,        'Pending',  NULL,       'Scheduled Q3'),
(7,  10, '2026-09-05',NULL,        'Pending',  NULL,       'Scheduled Q3'),
(9,  12, '2026-07-20','2026-07-21','Completed','grayraven',NULL),
(10, 12, '2026-07-20',NULL,        'Pending',  NULL,       'Standby drone — low priority'),
(13, 12, '2026-07-25','2026-07-26','Completed','grayraven',NULL),
(14, 12, '2026-07-30','2026-08-01','Completed','grayraven',NULL),
(17, 12, '2026-08-22',NULL,        'Paused',   NULL,       'Drone grounded — motor fault'),
(18, 12, '2026-08-10','2026-08-11','Completed','grayraven',NULL),
(3,  9,  '2023-01-15','2023-01-15','Completed','grayraven','Last update before write-off');


-- ============================================================
-- TABLE 7: flight_plans
-- ============================================================
CREATE TABLE flight_plans (
    id SERIAL PRIMARY KEY,
    plan_name VARCHAR(100),
    drone_id INT REFERENCES drones(id),
    pilot_id INT REFERENCES pilots(id),
    squadron_id INT REFERENCES squadrons(id),
    planned_date DATE,
    planned_altitude_m INT,
    planned_distance_km DECIMAL(6,2),
    waypoints_count INT,
    mission_type VARCHAR(50),
    status VARCHAR(20) DEFAULT 'Planned',
    approved_by VARCHAR(100)
);

INSERT INTO flight_plans (plan_name, drone_id, pilot_id, squadron_id, planned_date, planned_altitude_m, planned_distance_km, waypoints_count, mission_type, status, approved_by) VALUES
('SORTIE_20260801_DRONE042',  22, 1, 1, '2026-08-01', 100, 12.4, 5, 'Reconnaissance', 'Completed',  'Major V. Kovalenko'),
('SORTIE_20260805_DRONE017',  16, 2, 1, '2026-08-05', 120,  9.8, 4, 'Reconnaissance', 'Completed',  'Major V. Kovalenko'),
('SORTIE_20260812_DRONE031',  21, 1, 1, '2026-08-12',  60,  6.1, 4, 'ISR Night',      'Completed',  'Major V. Kovalenko'),
('RECON_20260815_DRONE008',    8, 2, 1, '2026-08-15', 100,  8.0, 4, 'Reconnaissance', 'Aborted',    'Major V. Kovalenko'),
('TRAIN_20260802_DRONE011',   11, 4, 5, '2026-08-02',  50,  3.0, 3, 'Training',       'Completed',  'Capt. I. Savchenko'),
('TRAIN_20260802_DRONE012',   12, 4, 5, '2026-08-02',  50,  3.0, 3, 'Training',       'Completed',  'Capt. I. Savchenko'),
('ISR_20260808_DRONE019',     19, 13,7, '2026-08-08',  80,  7.5, 5, 'ISR Night',      'Completed',  'Major O. Holub'),
('ISR_20260810_DRONE020',     20, 14,7, '2026-08-10',  80,  7.2, 5, 'ISR Night',      'Completed',  'Major O. Holub'),
('RECON_20260818_DRONE055',   23, 1, 1, '2026-08-18',  90, 10.1, 5, 'Reconnaissance', 'Completed',  'Major V. Kovalenko'),
('SORTIE_20260822_DRONE042',  22, 1, 1, '2026-08-22', 100, 11.8, 5, 'Reconnaissance', 'Completed',  'Major V. Kovalenko'),
('SORTIE_20260825_DRONE031',  21, 2, 1, '2026-08-25',  60,  5.5, 3, 'ISR Night',      'Planned',    'Major V. Kovalenko'),
('STRIKE_20260901_DRONE006',   6, 7, 3, '2026-09-01', 150, 15.2, 6, 'Strike',         'Planned',    'Lt. Col. M. Hrytsenko'),
('RECON_20260901_DRONE042',   22, 1, 1, '2026-09-01', 100, 12.0, 5, 'Reconnaissance', 'Planned',    'Major V. Kovalenko'),
('TRAIN_20260902_DRONE011',   11, 4, 5, '2026-09-02',  50,  3.5, 3, 'Training',       'Planned',    'Capt. I. Savchenko'),
('RECON_20260903_DRONE008',    8, 2, 1, '2026-09-03', 100,  7.0, 4, 'Maintenance Chk','Planned',    'Major V. Kovalenko'),
('NIGHT_20260908_DRONE042',   22, 1, 1, '2026-09-08',  70,  8.5, 5, 'ISR Night',      'Pending Appr','Major V. Kovalenko'),
('RECON_20260910_DRONE031',   21, 2, 1, '2026-09-10',  90, 10.0, 5, 'Reconnaissance', 'Planned',    'Major V. Kovalenko'),
('RECON_20260912_DRONE055',   23, 1, 1, '2026-09-12',  90, 10.5, 5, 'Reconnaissance', 'Planned',    'Major V. Kovalenko'),
('ISR_20260915_DRONE019',     19, 13,7, '2026-09-15',  80,  7.0, 4, 'ISR Night',      'Planned',    'Major O. Holub'),
('NIGHT_20260920_DRONE042',   22, 1, 1, '2026-09-20',  70,  9.0, 5, 'ISR Night',      'Planned',    'Major V. Kovalenko'),
('TRAIN_20260925_DRONE017',   16, 2, 1, '2026-09-25', 100,  6.0, 4, 'Training',       'Planned',    'Major V. Kovalenko'),
('STRIKE_20260905_DRONE007',   7, 7, 3, '2026-09-05', 160, 14.8, 6, 'Strike',         'Planned',    'Lt. Col. M. Hrytsenko'),
('LOG_20260901_DRONE009',      9, 9, 4, '2026-09-01',  40,  2.5, 2, 'Logistics',      'Planned',    'Capt. O. Kravets'),
('RAPID_20260830_DRONE060',   24, 19,12,'2026-08-30',  60,  4.0, 3, 'Rapid Deploy',   'Completed',  'Major D. Petrenko'),
('RECON_20260829_DRONE055',   23, 2, 1, '2026-08-29',  90,  9.5, 5, 'Reconnaissance', 'Completed',  'Major V. Kovalenko');


-- ============================================================
-- TABLE 8: flight_logs
-- ============================================================
CREATE TABLE flight_logs (
    id SERIAL PRIMARY KEY,
    flight_plan_id INT REFERENCES flight_plans(id),
    drone_id INT REFERENCES drones(id),
    pilot_id INT REFERENCES pilots(id),
    start_time TIMESTAMP,
    end_time TIMESTAMP,
    flight_duration_min DECIMAL(6,2),
    distance_km DECIMAL(6,2),
    max_altitude_m INT,
    outcome VARCHAR(20) DEFAULT 'Success',
    incidents TEXT,
    battery_start_pct INT,
    battery_end_pct INT
);

INSERT INTO flight_logs (flight_plan_id, drone_id, pilot_id, start_time, end_time, flight_duration_min, distance_km, max_altitude_m, outcome, incidents, battery_start_pct, battery_end_pct) VALUES
(1,  22, 1, '2026-08-01 06:13:15','2026-08-01 06:58:33', 45.3, 12.4, 102, 'Success', NULL,                                    98, 22),
(2,  16, 2, '2026-08-05 14:30:35','2026-08-05 15:16:02', 45.4,  9.8, 122, 'Success', 'Wind hold x1 (auto-resolved)',          100, 18),
(3,  21, 1, '2026-08-12 21:06:00','2026-08-12 21:47:55', 41.9,  6.1,  62, 'Warning', 'Gimbal stall T+18min (auto-recovered)', 100, 11),
(4,   8, 2, '2026-08-15 07:05:00','2026-08-15 07:05:05',  0.1,  0.0,   5, 'Aborted', 'GPS loss at takeoff — emergency land',  100, 99),
(5,  11, 4, '2026-08-02 09:00:00','2026-08-02 09:28:10', 28.2,  3.0,  52, 'Success', NULL,                                    100, 55),
(6,  12, 4, '2026-08-02 09:35:00','2026-08-02 10:01:44', 26.7,  2.9,  51, 'Success', NULL,                                    100, 58),
(7,  19,13, '2026-08-08 21:10:00','2026-08-08 22:02:15', 52.2,  7.5,  82, 'Success', NULL,                                    100, 15),
(8,  20,14, '2026-08-10 21:30:00','2026-08-10 22:20:40', 50.7,  7.2,  81, 'Success', NULL,                                    100, 17),
(9,  23, 1, '2026-08-18 10:15:00','2026-08-18 11:01:20', 46.3, 10.1,  91, 'Success', NULL,                                    100, 20),
(10, 22, 1, '2026-08-22 07:00:00','2026-08-22 07:48:12', 48.2, 11.8, 101, 'Success', NULL,                                    100, 21),
(24, 24,19, '2026-08-30 10:00:00','2026-08-30 10:28:45', 28.8,  4.0,  62, 'Success', NULL,                                    100, 62),
(25, 23, 2, '2026-08-29 08:30:00','2026-08-29 09:16:00', 46.0,  9.5,  91, 'Warning', 'Low battery alert at 25% — shortened',  100, 14),
(NULL,1, 1, '2026-07-20 07:00:00','2026-07-20 07:52:30', 52.5, 13.1, 103, 'Success', NULL,                                    100, 19),
(NULL,2, 2, '2026-07-22 08:00:00','2026-07-22 08:44:10', 44.2, 11.4, 101, 'Success', NULL,                                    100, 23),
(NULL,4, 5, '2026-07-18 09:00:00','2026-07-18 09:50:20', 50.3, 12.8, 155, 'Success', NULL,                                    100, 18),
(NULL,6, 7, '2026-07-25 10:00:00','2026-07-25 10:58:00', 58.0, 14.9, 151, 'Success', NULL,                                    100, 12),
(NULL,7, 7, '2026-07-28 11:00:00','2026-07-28 11:55:30', 55.5, 14.5, 153, 'Success', NULL,                                    100, 14),
(NULL,9, 9, '2026-07-15 14:00:00','2026-07-15 14:22:00', 22.0,  2.4,  42, 'Success', NULL,                                    100, 72),
(NULL,13,5, '2026-07-30 08:00:00','2026-07-30 08:56:00', 56.0, 13.8, 152, 'Success', NULL,                                    100, 11),
(NULL,14,15,'2026-07-10 09:00:00','2026-07-10 09:30:00', 30.0,  4.2,  52, 'Success', NULL,                                    100, 65),
(NULL,18,8, '2026-08-05 13:00:00','2026-08-05 13:52:00', 52.0, 12.9, 121, 'Success', NULL,                                    100, 17),
(NULL,19,13,'2026-08-01 22:00:00','2026-08-01 22:51:00', 51.0,  7.4,  81, 'Success', NULL,                                    100, 16),
(NULL,20,14,'2026-08-03 22:00:00','2026-08-03 22:48:30', 48.5,  7.0,  80, 'Success', NULL,                                    100, 19),
(NULL,22, 1,'2026-07-15 07:00:00','2026-07-15 07:46:30', 46.5, 12.0, 101, 'Success', NULL,                                    100, 22),
(NULL,23, 2,'2026-08-10 09:00:00','2026-08-10 09:44:00', 44.0,  9.8,  91, 'Success', NULL,                                    100, 21);


-- ============================================================
-- TABLE 9: telemetry_positions
-- ============================================================
CREATE TABLE telemetry_positions (
    id SERIAL PRIMARY KEY,
    drone_id INT REFERENCES drones(id),
    flight_log_id INT REFERENCES flight_logs(id),
    recorded_at TIMESTAMP NOT NULL,
    lat DECIMAL(9,6),
    lon DECIMAL(9,6),
    altitude_m DECIMAL(8,2),
    speed_ms DECIMAL(5,2),
    heading_deg INT,
    battery_pct INT
);

INSERT INTO telemetry_positions (drone_id, flight_log_id, recorded_at, lat, lon, altitude_m, speed_ms, heading_deg, battery_pct) VALUES
(22,1,'2026-08-01 06:14:00',48.45300,35.46200,100.2,15.1, 47, 96),
(22,1,'2026-08-01 06:20:00',48.45400,35.46300, 99.8,15.3, 50, 88),
(22,1,'2026-08-01 06:26:00',48.45500,35.46400,100.1,15.0, 53, 79),
(22,1,'2026-08-01 06:32:00',48.45600,35.46500, 99.9,14.9, 55, 70),
(22,1,'2026-08-01 06:38:00',48.45700,35.46600,100.3,15.2, 57, 61),
(22,1,'2026-08-01 06:44:00',48.45600,35.46700, 99.7,15.0, 60, 52),
(22,1,'2026-08-01 06:50:00',48.45400,35.46500,100.0,14.8,220, 43),
(16,2,'2026-08-05 14:31:00',48.45000,35.45900,120.1,12.3, 30, 98),
(16,2,'2026-08-05 14:40:00',48.45200,35.46100,119.8,12.0, 33, 88),
(16,2,'2026-08-05 14:50:00',48.45350,35.46250,120.2,12.1, 36, 77),
(16,2,'2026-08-05 15:00:00',48.45480,35.46400,119.9,11.9, 38, 65),
(16,2,'2026-08-05 15:08:00',48.45100,35.46100,120.0, 6.0,200, 48),
(21,3,'2026-08-12 21:07:00',48.45100,35.45970, 60.4,10.0, 42, 98),
(21,3,'2026-08-12 21:15:00',48.45210,35.46050, 60.1, 9.8, 44, 87),
(21,3,'2026-08-12 21:23:00',48.45320,35.46180, 59.9,10.1, 46, 74),
(21,3,'2026-08-12 21:31:00',48.45200,35.46300, 60.2,10.0, 50, 60),
(21,3,'2026-08-12 21:39:00',48.45080,35.46180, 60.0, 9.9,220, 46),
( 8,4,'2026-08-15 07:05:00',48.45210,35.46120,  5.0, 0.0,  0,100),
(11,5,'2026-08-02 09:00:00',48.44900,35.45800, 50.2, 8.0, 30, 98),
(11,5,'2026-08-02 09:10:00',48.45000,35.45900, 50.0, 8.1, 33, 90),
(11,5,'2026-08-02 09:20:00',48.45100,35.46000, 50.1, 7.9, 36, 82),
(12,6,'2026-08-02 09:35:00',48.44900,35.45800, 51.0, 8.2, 30, 99),
(12,6,'2026-08-02 09:45:00',48.45000,35.45900, 50.8, 8.0, 33, 91),
(19,7,'2026-08-08 21:10:00',48.45050,35.45930, 80.3,10.0, 40, 98),
(20,8,'2026-08-10 21:30:00',48.45050,35.45930, 80.0,10.0, 40, 99);


-- ============================================================
-- TABLE 10: geofence_zones
-- ============================================================
CREATE TABLE geofence_zones (
    id SERIAL PRIMARY KEY,
    zone_name VARCHAR(100) UNIQUE NOT NULL,
    zone_type VARCHAR(30) DEFAULT 'Exclusion',
    restriction_type VARCHAR(50),
    min_altitude_m INT DEFAULT 0,
    max_altitude_m INT DEFAULT 500,
    coordinates TEXT,
    active BOOLEAN DEFAULT TRUE,
    added_date DATE,
    notes TEXT
);

INSERT INTO geofence_zones (zone_name, zone_type, restriction_type, min_altitude_m, max_altitude_m, coordinates, active, added_date, notes) VALUES
('ZONE-ALPHA-EXCL', 'Exclusion', 'No-fly — hostile proximity',   0, 500, '48.44,35.44;48.44,35.46;48.46,35.46;48.46,35.44', TRUE,  '2024-01-10', 'Active combat zone'),
('ZONE-BRAVO-REST', 'Restriction','Altitude restricted',         0, 100, '48.50,35.50;48.50,35.55;48.55,35.55;48.55,35.50', TRUE,  '2024-03-15', 'Near civilian area'),
('ZONE-CHARLIE-OPS','Operational','Own forces — caution',        50, 500,'48.45,35.46;48.45,35.48;48.47,35.48;48.47,35.46', TRUE,  '2024-06-01', 'Friendly unit boundary'),
('ZONE-DELTA-EXCL', 'Exclusion', 'No-fly — radar coverage',      0, 500, '48.38,35.40;48.38,35.45;48.42,35.45;48.42,35.40', TRUE,  '2024-07-20', 'Enemy radar umbrella'),
('ZONE-ECHO-RESTR', 'Restriction','Night operations only',       0, 200, '48.46,35.48;48.46,35.52;48.49,35.52;48.49,35.48', FALSE, '2024-08-05', 'Deactivated — situation changed'),
('ZONE-FOXTROT',    'Operational','Friendly AO',                100, 500,'48.60,35.38;48.60,35.42;48.64,35.42;48.64,35.38', TRUE,  '2024-09-10', NULL),
('ZONE-GOLF-EXCL',  'Exclusion', 'No-fly — artillery',          0, 500, '48.33,35.60;48.33,35.65;48.37,35.65;48.37,35.60', TRUE,  '2024-10-01', 'Artillery impact area'),
('ZONE-HOTEL',      'Restriction','ROE restricted',              0, 300, '48.42,35.70;48.42,35.74;48.45,35.74;48.45,35.70', TRUE,  '2024-11-15', 'Engage only with authorization'),
('ZONE-INDIA-RTL',  'Operational','Safe RTL corridor',           50, 200,'48.451,35.460;48.451,35.463;48.453,35.463;48.453,35.460',TRUE,'2025-01-05','RTL corridor for BASE-A'),
('ZONE-JULIET',     'Exclusion', 'No-fly — civilian airfield',   0, 500, '48.48,36.00;48.48,36.04;48.52,36.04;48.52,36.00', TRUE,  '2025-02-20', NULL),
('ZONE-KILO-OPS',   'Operational','Cleared launch area',         0, 200, '48.452,35.461;48.452,35.464;48.454,35.464;48.454,35.461',TRUE,'2025-03-01','Alpha Base launch zone'),
('ZONE-LIMA',       'Restriction','Low-altitude training',       0,  80, '48.71,35.60;48.71,35.64;48.74,35.64;48.74,35.60', TRUE,  '2025-04-10', 'Training area Lima'),
('ZONE-MIKE-EXCL',  'Exclusion', 'No-fly — EM interference',    0, 500, '48.53,35.29;48.53,35.33;48.57,35.33;48.57,35.29', FALSE, '2025-05-20', 'Deactivated'),
('ZONE-NOVEMBER',   'Restriction','Day ops only',                0, 200, '48.34,35.77;48.34,35.80;48.37,35.80;48.37,35.77', TRUE,  '2025-06-15', NULL),
('ZONE-OSCAR',      'Operational','Reserve training',            0, 150, '48.77,35.50;48.77,35.54;48.80,35.54;48.80,35.50', TRUE,  '2025-07-01', NULL),
('ZONE-PAPA-EXCL',  'Exclusion', 'No-fly — restricted comms',   0, 500, '48.40,35.49;48.40,35.51;48.42,35.51;48.42,35.49', TRUE,  '2025-08-10', NULL),
('ZONE-QUEBEC',     'Restriction','Minimum 200m alt',           200, 500,'48.61,35.70;48.61,35.74;48.64,35.74;48.64,35.70', TRUE,  '2025-09-01', NULL),
('ZONE-ROMEO',      'Operational','Staging area ops',            0, 300, '48.35,35.34;48.35,35.38;48.38,35.38;48.38,35.34', TRUE,  '2025-10-15', NULL),
('ZONE-SIERRA',     'Restriction','Stealth ops — silent mode',  50, 500, '48.47,35.61;48.47,35.63;48.49,35.63;48.49,35.61', TRUE,  '2025-11-20', 'No active comms during transit'),
('ZONE-TANGO-EXCL', 'Exclusion', 'No-fly — mines',              0, 500, '48.29,35.55;48.29,35.58;48.31,35.58;48.31,35.55', TRUE,  '2025-12-01', NULL),
('ZONE-UNIFORM',    'Operational','Kharkiv support ops',         0, 400, '48.66,35.46;48.66,35.50;48.69,35.50;48.69,35.46', TRUE,  '2026-01-10', NULL),
('ZONE-VICTOR',     'Exclusion', 'No-fly — AA coverage',        0, 500, '48.32,35.87;48.32,35.90;48.35,35.90;48.35,35.87', TRUE,  '2026-02-01', NULL),
('ZONE-WHISKEY',    'Restriction','Depot approach — careful',    0, 100, '48.49,36.10;48.49,36.13;48.51,36.13;48.51,36.10', TRUE,  '2026-03-15', NULL),
('ZONE-XRAY',       'Operational','Relay point airspace',        0, 200, '48.41,36.19;48.41,36.22;48.43,36.22;48.43,36.19', TRUE,  '2026-04-20', NULL),
('ZONE-YANKEE',     'Restriction','Border proximity caution',    0, 300, '48.36,35.41;48.36,35.43;48.38,35.43;48.38,35.41', TRUE,  '2026-05-05', NULL);


-- ============================================================
-- TABLE 11: maintenance_records
-- ============================================================
CREATE TABLE maintenance_records (
    id SERIAL PRIMARY KEY,
    drone_id INT REFERENCES drones(id),
    maintenance_date DATE,
    technician VARCHAR(100),
    maintenance_type VARCHAR(50),
    issue_description TEXT,
    resolution TEXT,
    parts_replaced TEXT,
    duration_hours DECIMAL(4,2),
    next_scheduled DATE,
    status VARCHAR(20) DEFAULT 'Completed'
);

INSERT INTO maintenance_records (drone_id, maintenance_date, technician, maintenance_type, issue_description, resolution, parts_replaced, duration_hours, next_scheduled, status) VALUES
(22,'2026-08-22','Andrii Shevchenko','Scheduled Inspection','Routine 300h inspection','All checks passed, firmware updated',NULL,2.0,'2026-11-22','Completed'),
(16,'2026-08-20','Andrii Shevchenko','Fault Investigation','Motor 3 overcurrent trip at T+12min','ESC burnt; drone grounded pending replacement','ESC unit Motor-3',0.5,'2026-09-05','In Progress'),
(21,'2026-08-12','Andrii Shevchenko','Fault Investigation','Gimbal stall mid-flight','Scheduled for full gimbal assembly replacement','Gimbal assembly (pending)',1.0,'2026-08-30','In Progress'),
( 8,'2026-08-16','Andrii Shevchenko','Fault Repair','GPS loss at takeoff','GPS module replaced; firmware re-applied','GPS module u-blox M8N',3.5,'2026-09-15','Completed'),
( 5,'2026-07-01','Olena Pryshchepa','Scheduled Inspection','300h inspection','ESC unit on Motor-2 shows marginal readings; monitoring','None yet',2.0,'2026-08-01','Completed'),
( 3,'2026-05-01','Andrii Shevchenko','Write-off Assessment','Motor failure — catastrophic','Beyond repair; written off','N/A',1.0,NULL,'Completed'),
( 1,'2026-07-15','Olena Pryshchepa','Scheduled Inspection','Routine','All OK; firmware updated to v2.4.2',NULL,2.0,'2026-10-15','Completed'),
( 2,'2026-06-20','Olena Pryshchepa','Scheduled Inspection','Routine','All OK',NULL,2.0,'2026-09-20','Completed'),
( 4,'2026-07-20','Olena Pryshchepa','Scheduled Inspection','Routine','All OK; firmware updated',NULL,2.0,'2026-10-20','Completed'),
(13,'2026-08-01','Andrii Shevchenko','Scheduled Inspection','Routine 200h inspection','All checks passed',NULL,2.0,'2026-11-01','Completed'),
(11,'2026-08-12','Olena Pryshchepa','Minor Repair','Post-training inspection','No faults',NULL,0.5,'2026-09-12','Completed'),
(12,'2026-08-13','Olena Pryshchepa','Minor Repair','Post-training inspection','No faults',NULL,0.5,'2026-09-13','Completed'),
(15,'2026-05-20','Andrii Shevchenko','Fault Repair','Antenna degradation','Antenna replaced','2.4GHz antenna',1.5,'2026-08-20','Completed'),
(19,'2026-08-15','Olena Pryshchepa','Post-sortie Inspection','Night ISR check','All OK',NULL,0.5,'2026-09-15','Completed'),
(20,'2026-08-15','Olena Pryshchepa','Post-sortie Inspection','Night ISR check','All OK',NULL,0.5,'2026-09-15','Completed'),
(24,'2026-08-28','Andrii Shevchenko','Initial Acceptance','New drone delivery check','All systems nominal; firmware applied',NULL,4.0,'2026-11-28','Completed'),
(23,'2026-08-18','Olena Pryshchepa','Post-sortie Inspection','Routine','Low battery cell noted — monitoring','None',0.5,'2026-09-18','Completed'),
( 9,'2026-08-05','Andrii Shevchenko','Scheduled Inspection','Routine 150h inspection','All OK',NULL,1.5,'2026-11-05','Completed'),
(14,'2026-07-15','Olena Pryshchepa','Scheduled Inspection','Routine 60h inspection','All OK',NULL,1.0,'2026-10-15','Completed'),
(18,'2026-08-10','Andrii Shevchenko','Post-sortie Inspection','Routine','All OK',NULL,0.5,'2026-09-10','Completed'),
( 6,'2026-08-01','Andrii Shevchenko','Scheduled Inspection','Routine 180h inspection','All OK',NULL,2.0,'2026-11-01','Completed'),
( 7,'2026-07-25','Andrii Shevchenko','Scheduled Inspection','Routine 165h inspection','All OK',NULL,2.0,'2026-10-25','Completed'),
(25,'2026-04-10','Olena Pryshchepa','Scheduled Inspection','Routine 189h inspection','All OK; firmware v2.4.0 — update planned',NULL,2.0,'2026-07-10','Completed'),
(10,'2026-06-10','Olena Pryshchepa','Scheduled Inspection','Routine','All OK; standby drone',NULL,1.0,'2026-09-10','Completed'),
(17,'2026-08-20','Andrii Shevchenko','Fault Investigation','Motor overcurrent','Under investigation; drone grounded','None yet',1.0,'TBD','In Progress');


-- ============================================================
-- TABLE 12: mission_reports
-- ============================================================
CREATE TABLE mission_reports (
    id SERIAL PRIMARY KEY,
    flight_log_id INT REFERENCES flight_logs(id),
    report_date DATE,
    prepared_by VARCHAR(100),
    mission_type VARCHAR(50),
    summary TEXT,
    outcome VARCHAR(20) DEFAULT 'Success',
    imagery_collected BOOLEAN DEFAULT FALSE,
    intel_value VARCHAR(20) DEFAULT 'Low',
    classification VARCHAR(20) DEFAULT 'SECRET'
);

INSERT INTO mission_reports (flight_log_id, report_date, prepared_by, mission_type, summary, outcome, imagery_collected, intel_value, classification) VALUES
(1, '2026-08-02','Mykola Bondar',     'Reconnaissance', 'Standard recon sortie. No contacts. Area clear.',           'Success',TRUE, 'Medium','SECRET'),
(2, '2026-08-06','Yaroslav Kravchuk', 'Reconnaissance', 'Sortie completed with wind delay. Imagery collected.',      'Success',TRUE, 'Medium','SECRET'),
(3, '2026-08-13','Mykola Bondar',     'ISR Night',      'Night ISR. Gimbal fault noted. Partial imagery.',           'Partial',TRUE,'Low',   'SECRET'),
(4, '2026-08-15','Yaroslav Kravchuk', 'Reconnaissance', 'Mission aborted — GPS failure at takeoff. No data.',        'Aborted',FALSE,'None','CONFIDENTIAL'),
(5, '2026-08-03','Ihor Savchenko',    'Training',       'Training sortie DRONE011. Trainee performed well.',         'Success',FALSE,'None','UNCLASSIFIED'),
(6, '2026-08-03','Ihor Savchenko',    'Training',       'Training sortie DRONE012. Trainee — acceptable.',           'Success',FALSE,'None','UNCLASSIFIED'),
(7, '2026-08-09','Olena Holub',       'ISR Night',      'Night ISR. No incidents. High-value imagery captured.',     'Success',TRUE, 'High','TOP SECRET'),
(8, '2026-08-11','Olena Holub',       'ISR Night',      'Night ISR. No incidents. Imagery captured.',                'Success',TRUE, 'High','TOP SECRET'),
(9, '2026-08-19','Mykola Bondar',     'Reconnaissance', 'Recon sortie DRONE055. Good results. Low battery flagged.', 'Success',TRUE, 'Medium','SECRET'),
(10,'2026-08-23','Mykola Bondar',     'Reconnaissance', 'Standard sortie. All systems nominal.',                     'Success',TRUE, 'Medium','SECRET'),
(11,'2026-08-31','Yaroslav Kravchuk', 'ISR Night',      'Night ISR DRONE055 — planned. Low battery warning noted.',  'Warning',TRUE,'Low',   'SECRET'),
(12,'2026-08-31','Dmytro Petrenko',   'Rapid Deploy',   'Rapid deployment sortie DRONE060. New airframe check.',     'Success',FALSE,'None','CONFIDENTIAL'),
(NULL,'2026-07-21','Mykola Bondar',   'Reconnaissance', 'DRONE001 standard recon. Area secure.',                     'Success',TRUE, 'Medium','SECRET'),
(NULL,'2026-07-23','Yaroslav Kravchuk','Reconnaissance', 'DRONE002 recon. No contacts.',                              'Success',TRUE, 'Low',  'SECRET'),
(NULL,'2026-07-19','Kateryna Melnyk', 'Strike',         'Strike sortie DRONE004. Target acquired and engaged.',      'Success',TRUE, 'High','TOP SECRET'),
(NULL,'2026-07-26','Oleksii Petrenko','Strike',         'Strike sortie DRONE006. Mission accomplished.',             'Success',TRUE, 'High','TOP SECRET'),
(NULL,'2026-07-29','Oleksii Petrenko','Strike',         'Strike sortie DRONE007. Partial success — target damaged.', 'Partial',TRUE,'Medium','TOP SECRET'),
(NULL,'2026-07-16','Oksana Yarova',   'Logistics',      'Logistics support DRONE009. Delivery completed.',           'Success',FALSE,'None','CONFIDENTIAL'),
(NULL,'2026-07-31','Kateryna Melnyk', 'ISR',            'ISR sortie DRONE013. Good imagery.',                        'Success',TRUE, 'High','TOP SECRET'),
(NULL,'2026-07-11','Natalia Bondar',  'Reconnaissance', 'Scout DRONE014. Training recon, no contacts.',              'Success',TRUE, 'Low','CONFIDENTIAL'),
(NULL,'2026-08-06','Yulia Shvets',    'Strike',         'Strike sortie DRONE018. Target engaged.',                   'Success',TRUE, 'High','TOP SECRET'),
(NULL,'2026-08-02','Olena Holub',     'ISR Night',      'Night ISR DRONE019. High value imagery.',                   'Success',TRUE, 'High','TOP SECRET'),
(NULL,'2026-08-04','Serhii Dovhal',   'ISR Night',      'Night ISR DRONE020. Good sortie.',                          'Success',TRUE, 'Medium','SECRET'),
(NULL,'2026-07-16','Mykola Bondar',   'Reconnaissance', 'DRONE042 early July recon. Area secure.',                   'Success',TRUE, 'Medium','SECRET'),
(NULL,'2026-08-11','Yaroslav Kravchuk','Reconnaissance', 'DRONE055 pre-month-end sortie. All nominal.',               'Success',TRUE, 'Medium','SECRET');


-- ============================================================
-- TABLE 13: suppliers
-- ============================================================
CREATE TABLE suppliers (
    id SERIAL PRIMARY KEY,
    company_name VARCHAR(150) UNIQUE NOT NULL,
    contact_person VARCHAR(100),
    contact_email VARCHAR(150),
    contact_phone VARCHAR(30),
    product_category VARCHAR(100),
    contract_number VARCHAR(50),
    contract_value_usd DECIMAL(12,2),
    contract_start DATE,
    contract_end DATE,
    status VARCHAR(20) DEFAULT 'Active',
    notes TEXT
);

INSERT INTO suppliers (company_name, contact_person, contact_email, contact_phone, product_category, contract_number, contract_value_usd, contract_start, contract_end, status, notes) VALUES
('DronePartsUA',         'Ivan Karpenko',     'ivan@dronepartsua.example',   '+380441234567','Airframe & Mechanical',  'CTR-2024-001',450000.00,'2024-01-15','2027-01-14','Active',NULL),
('AvionicsPro Ltd',      'Sofia Marchenko',   'sofia@avionicspro.example',   '+380442345678','Avionics & Sensors',     'CTR-2024-002',320000.00,'2024-02-01','2027-01-31','Active',NULL),
('PowerCellUA',          'Taras Holub',       'taras@powercellua.example',   '+380443456789','Batteries & Power',      'CTR-2024-003',180000.00,'2024-03-10','2026-12-31','Active','Renewal in progress'),
('FirmwareSoft LLC',     'Roman Petrenko',    'roman@firmwaresoft.example',  '+380444567890','Software & Firmware',    'CTR-2023-011',250000.00,'2023-06-01','2026-05-31','Expired','Replaced by DroneCorp internal team'),
('SkyRadio Systems',     'Olha Bondar',       'olha@skyradio.example',       '+380445678901','Communications',         'CTR-2024-004',210000.00,'2024-04-01','2027-03-31','Active',NULL),
('OpticsUA',             'Pavlo Koval',       'pavlo@opticsua.example',      '+380446789012','Cameras & Optics',       'CTR-2024-005',390000.00,'2024-05-15','2027-05-14','Active',NULL),
('PropellerWorks',       'Natalia Lys',       'natalia@propellerworks.example','+380447890123','Propulsion',           'CTR-2024-006',120000.00,'2024-06-01','2026-11-30','Active',NULL),
('MagneticSensors EU',   'Klaus Müller',      'k.muller@mse.example',        '+49301234567', 'IMU & Magnetometers',   'CTR-2024-007',280000.00,'2024-07-01','2027-06-30','Active',NULL),
('UkrElectronics',       'Andrii Savchenko',  'a.savchenko@ukrael.example',  '+380448901234','Electronics & PCBs',     'CTR-2024-008',195000.00,'2024-08-01','2027-07-31','Active',NULL),
('GimbalTech',           'Lars Eriksson',     'lars@gimbaltech.example',     '+46812345678', 'Gimbals & Mounts',      'CTR-2024-009',310000.00,'2024-09-01','2027-08-31','Active','Awaiting gimbal for DRONE031'),
('CarbonFrame Co',       'Yevhen Pylypenko',  'yevhen@carbonframe.example',  '+380449012345','Structural Materials',   'CTR-2024-010',145000.00,'2024-10-01','2027-09-30','Active',NULL),
('LiDAR Systems Int',    'Aisha Okafor',      'aisha@lidarint.example',      '+44201234567', 'Sensors & LiDAR',       'CTR-2025-001',520000.00,'2025-01-15','2028-01-14','Active',NULL),
('GPSModule Ltd',        'Chen Wei',          'chen.wei@gpsmodule.example',  '+86101234567', 'GPS & GNSS Modules',    'CTR-2025-002',160000.00,'2025-02-01','2028-01-31','Active','Supplied GPS module for DRONE008'),
('HeavyLiftUA',          'Viktor Marchenko',  'viktor@heavyliftua.example',  '+380441112233','X-8 Airframe Supply',   'CTR-2025-003',600000.00,'2025-03-01','2028-02-28','Active',NULL),
('SecureComm Defense',   'Serhii Kovalenko',  'serhii@seccomdef.example',    '+380442223344','Encrypted Comms',        'CTR-2025-004',430000.00,'2025-04-01','2028-03-31','Active',NULL),
('BatteryPlus EU',       'Marie Dupont',      'marie@batteryplus.example',   '+33112345678', 'High-cap Batteries',    'CTR-2025-005',275000.00,'2025-05-01','2028-04-30','Active',NULL),
('SensorHub Ukraine',    'Oleksandra Tymchuk','alex@sensorhub.example',      '+380443334455','Environmental Sensors',  'CTR-2025-006',155000.00,'2025-06-01','2028-05-31','Active',NULL),
('Antennas & More',      'David Lee',         'david@antennasmore.example',  '+1-202-555-0101','Antennas & RF',        'CTR-2025-007',190000.00,'2025-07-01','2028-06-30','Active','Supplied antenna for DRONE015'),
('DroneTestEquip',       'Maksym Rudenko',    'maksym@dronetestequip.example','+380444445566','Test Equipment',        'CTR-2025-008',230000.00,'2025-08-01','2028-07-31','Active',NULL),
('NightVision Systems',  'Hiroshi Tanaka',    'h.tanaka@nvs.example',        '+81312345678', 'Night Vision / IR',     'CTR-2025-009',480000.00,'2025-09-01','2028-08-31','Active',NULL),
('LogiDrone UA',         'Iryna Savchuk',     'iryna@logidrone.example',     '+380445556677','Logistics Support',      'CTR-2025-010',110000.00,'2025-10-01','2028-09-30','Active',NULL),
('RFJammer Defense',     'Oleksii Boyko',     'oleksii@rfjammer.example',    '+380446667788','EW / SIGINT',           'CTR-2025-011',620000.00,'2025-11-01','2028-10-31','Active','Classified contract — restricted access'),
('StructuralUAV',        'Bohdan Melnyk',     'bohdan@structuraluav.example', '+380447778899','Structural Repair Parts','CTR-2025-012',175000.00,'2025-12-01','2028-11-30','Active',NULL),
('CloudData Systems',    'Oksana Petrenko',   'oksana@clouddata.example',    '+380448889900','Data Storage & Backup',  'CTR-2026-001',340000.00,'2026-01-15','2029-01-14','Active','Manages offsite backup infra'),
('ThermalOptics Ltd',    'Artem Rudenko',     'artem@thermaloptics.example',  '+380449990011','Thermal Cameras',       'CTR-2026-002',510000.00,'2026-02-01','2029-01-31','Active',NULL);


-- ============================================================
-- TABLE 14: spare_parts_inventory
-- ============================================================
CREATE TABLE spare_parts_inventory (
    id SERIAL PRIMARY KEY,
    part_name VARCHAR(150) NOT NULL,
    part_number VARCHAR(50) UNIQUE,
    compatible_drone_models TEXT,
    quantity_on_hand INT DEFAULT 0,
    unit_price_usd DECIMAL(10,2),
    supplier_id INT REFERENCES suppliers(id),
    location VARCHAR(100),
    last_restocked DATE,
    reorder_threshold INT DEFAULT 2,
    notes TEXT
);

INSERT INTO spare_parts_inventory (part_name, part_number, compatible_drone_models, quantity_on_hand, unit_price_usd, supplier_id, location, last_restocked, reorder_threshold, notes) VALUES
('Rotor Blade Set (X-6)',       'ROT-X6-SET-001',  'X-6',       8, 45.00,  1, 'BASE-G Shelf A1', '2026-07-01', 4, NULL),
('Rotor Blade Set (X-4)',       'ROT-X4-SET-001',  'X-4',       6, 35.00,  1, 'BASE-G Shelf A2', '2026-07-01', 4, NULL),
('Rotor Blade Set (X-8)',       'ROT-X8-SET-001',  'X-8',       4, 75.00,  1, 'BASE-G Shelf A3', '2026-07-01', 2, NULL),
('Motor Unit (X-6, CW)',        'MOT-X6-CW-001',   'X-6',       3, 120.00, 1, 'BASE-G Shelf B1', '2026-06-15', 2, NULL),
('Motor Unit (X-6, CCW)',       'MOT-X6-CCW-001',  'X-6',       3, 120.00, 1, 'BASE-G Shelf B2', '2026-06-15', 2, NULL),
('ESC Unit (30A)',              'ESC-30A-001',      'X-4,X-6',   2, 85.00,  9, 'BASE-G Shelf B3', '2026-05-20', 2, 'Critical — DRONE016 repair pending'),
('ESC Unit (50A)',              'ESC-50A-001',      'X-8',       1, 145.00, 9, 'BASE-G Shelf B4', '2026-04-10', 2, 'Low stock — reorder needed'),
('GPS Module u-blox M8N',       'GPS-M8N-001',      'X-4,X-6,X-8',3,65.00,13, 'BASE-G Shelf C1', '2026-08-16', 2, 'Last restock: emergency order for DRONE008'),
('Flight Controller (Pixhawk)', 'FC-PH4-001',       'X-4,X-6,X-8',2,280.00,2, 'BASE-G Safe',     '2026-03-01', 1, 'High value — secured storage'),
('Battery Pack 6S 10000mAh',    'BAT-6S-10K-001',   'X-6,X-8',  5, 220.00, 3, 'BASE-G Shelf D1', '2026-08-01', 3, NULL),
('Battery Pack 6S 8000mAh',     'BAT-6S-8K-001',    'X-4,X-6',  7, 185.00, 3, 'BASE-G Shelf D2', '2026-08-01', 4, NULL),
('Gimbal Assembly (X-6)',       'GIMBAL-X6-001',    'X-6',       0, 450.00,10, 'BASE-G',          '2025-11-01', 1, 'Out of stock — ordered for DRONE031. ETA 10 days.'),
('Gimbal Pitch Bearing',        'GIMBAL-BEAR-001',  'X-6',       2, 25.00, 10, 'BASE-G Shelf E1', '2026-07-15', 2, NULL),
('2.4GHz Antenna (Tx)',         'ANT-2.4G-TX-001',  'X-4,X-6',  4, 18.00, 18, 'BASE-G Shelf F1', '2026-06-01', 2, NULL),
('5.8GHz Video Tx Module',      'VTX-5.8G-001',     'X-6',       3, 55.00,  5, 'BASE-G Shelf F2', '2026-05-15', 2, NULL),
('LiDAR Unit (lightweight)',    'LIDAR-LW-001',     'X-6',       1, 890.00,12, 'BASE-G Safe',     '2026-04-01', 1, 'High value'),
('Thermal Camera Module',       'THCAM-001',        'X-6,X-8',   2, 1200.00,25,'BASE-G Safe',     '2026-02-15', 1, 'Night ops essential'),
('IR Camera (standard)',        'IRCAM-STD-001',    'X-4,X-6',   3, 380.00,20, 'BASE-G Shelf G1', '2026-03-20', 1, NULL),
('Arming Switch (safety)',      'SWITCH-ARM-001',   'X-4,X-6,X-8',10,8.00, 9, 'BASE-G Shelf H1', '2026-08-10', 5, NULL),
('Carbon Fiber Frame (X-6)',    'FRAME-X6-001',     'X-6',       1, 320.00, 11,'BASE-G Large',    '2026-01-10', 1, 'Heavy item'),
('O-ring Kit (weather sealing)','ORING-KIT-001',    'X-4,X-6,X-8',15,5.00, 23,'BASE-G Shelf H2', '2026-08-01', 5, NULL),
('LED Arm Light Set',           'LED-ARM-001',      'X-4,X-6,X-8',8, 12.00, 9, 'BASE-G Shelf H3', '2026-07-01', 3, NULL),
('SD Card 64GB (logging)',      'SD-64G-LOG-001',   'X-4,X-6,X-8',12, 9.00, 9, 'BASE-G Shelf H4', '2026-08-01', 5, NULL),
('Telemetry Radio 915MHz',      'TELEM-915-001',    'X-4,X-6',   4, 75.00,  5, 'BASE-G Shelf F3', '2026-05-01', 2, NULL),
('PDB (Power Distribution Board)','PDB-X6-001',    'X-6',       2, 45.00,  9, 'BASE-G Shelf B5', '2026-06-15', 1, NULL);


-- ============================================================
-- TABLE 15: software_licenses
-- ============================================================
CREATE TABLE software_licenses (
    id SERIAL PRIMARY KEY,
    product_name VARCHAR(150) NOT NULL,
    vendor VARCHAR(100),
    license_key VARCHAR(100),
    license_type VARCHAR(50),
    seats INT DEFAULT 1,
    assigned_to VARCHAR(100),
    issue_date DATE,
    expiry_date DATE,
    managed_by VARCHAR(100),
    status VARCHAR(20) DEFAULT 'Active',
    notes TEXT
);

INSERT INTO software_licenses (product_name, vendor, license_key, license_type, seats, assigned_to, issue_date, expiry_date, managed_by, status, notes) VALUES
('QGroundControl Enterprise', 'QGroundControl',  'QGC-ENT-2024-7F3A-K9P2-M8Q1','Enterprise',   5, '1st UAV Squadron',     '2024-09-15','2026-09-15','DroneCorp IT (10.10.50.150)','Active',   'Renewal due Sep 15 2026'),
('QGroundControl Enterprise', 'QGroundControl',  'QGC-ENT-2024-3B8C-R1T4-W7V6','Enterprise',   3, '2nd ISR Squadron',     '2024-09-15','2026-09-15','DroneCorp IT (10.10.50.150)','Active',   'Renewal due Sep 15 2026'),
('MAVProxy Professional',     'ArduPilot Org',   'MAVP-PRO-2025-A1B2-C3D4-E5F6','Professional', 2, 'DroneCorp Eng',        '2025-01-01','2027-01-01','DroneCorp IT (10.10.50.150)','Active',   NULL),
('Mission Planner Enterprise','ArduPilot Org',   'MPE-2025-9Z8Y-7X6W-5V4U',     'Enterprise',   4, 'HQ Engineering',       '2025-03-01','2027-03-01','DroneCorp IT (10.10.50.150)','Active',   NULL),
('APM Planner 2.0 Pro',       'ArduPilot Org',   'APMP-PRO-2024-L3M4-N5O6-P7Q8','Professional', 2, 'Training Cell',        '2024-06-01','2026-06-01','DroneCorp IT (10.10.50.150)','Expired',  'Not renewed — superseded by QGC'),
('PX4 Pro License',           'Dronecode',       'PX4-PRO-2025-R1S2-T3U4-V5W6', 'Professional', 10,'DroneCorp Fleet',      '2025-02-15','2028-02-15','DroneCorp IT (10.10.50.150)','Active',   'Covers all PX4 deployments'),
('FPV Suite Pro',             'FPVSystems Ltd',  'FPV-PRO-2025-X7Y8-Z9A0-B1C2', 'Site',         5, '7th Night ISR Sqn',    '2025-05-01','2027-05-01','DroneCorp IT (10.10.50.150)','Active',   'Night ISR visual tools'),
('Auterion Mission Control',  'Auterion AG',     'AMC-2025-D3E4-F5G6-H7I8',     'Enterprise',   3, '3rd Strike Squadron',  '2025-07-01','2028-07-01','DroneCorp IT (10.10.50.150)','Active',   NULL),
('Skybrush Studio',           'CollMot Robotics','SBS-2025-J9K0-L1M2-N3O4',     'Studio',       1, 'HQ R&D',               '2025-09-01','2026-09-01','DroneCorp IT (10.10.50.150)','Active',   'Swarm simulation tool'),
('UGCS Professional',         'SPH Engineering', 'UGCS-PRO-2025-P5Q6-R7S8-T9U0','Professional', 2, 'DroneCorp Eng',        '2025-04-01','2027-04-01','DroneCorp IT (10.10.50.150)','Active',   NULL),
('DroneDeploy Fleet',         'DroneDeploy',     'DD-FLEET-2026-V1W2-X3Y4-Z5A6','Fleet',        8, 'Logistics Squadron',   '2026-01-15','2029-01-15','DroneCorp IT (10.10.50.150)','Active',   NULL),
('Pix4D Mapper Pro',          'Pix4D SA',        'P4D-PRO-2025-B7C8-D9E0-F1G2', 'Professional', 2, '2nd ISR Squadron',     '2025-08-01','2027-08-01','DroneCorp IT (10.10.50.150)','Active',   'Photogrammetry license'),
('Litchi for DJI (legacy)',   'VC Technology',   'LITCHI-LEG-2022-H3I4-J5K6',   'Perpetual',    1, 'Training (retired)',   '2022-01-01',NULL,        'N/A',                        'Inactive', 'Legacy — DJI fleet decommissioned'),
('Windows Server 2019 Std',   'Microsoft',       'WINSVR2019-STD-M7N8-O9P0-Q1', 'Volume',       1, 'IT Dept (10.10.50.150)','2024-11-01','2027-11-01','DroneCorp IT (10.10.50.150)','Active',   'Managed from Windows Server'),
('Microsoft Office 365',      'Microsoft',       'O365-BP-2025-R2S3-T4U5-V6W7', 'Business',    20, 'All Squadron Staff',   '2025-01-01','2026-12-31','DroneCorp IT (10.10.50.150)','Active',   'Annual subscription — auto-renew'),
('Kaspersky Endpoint Security','Kaspersky Lab',  'KES-2025-X8Y9-Z0A1-B2C3',     'Endpoint',    25, 'All Stations',         '2025-03-01','2027-02-28','DroneCorp IT (10.10.50.150)','Active',   NULL),
('OpenVPN Access Server',     'OpenVPN Inc',     'OVPN-AS-2024-D4E5-F6G7-H8I9', 'Site',         5, 'Secure Comms Team',    '2024-08-01','2026-07-31','DroneCorp IT (10.10.50.150)','Expired',  'Renewal in process'),
('Metashape Professional',    'Agisoft',         'META-PRO-2026-J0K1-L2M3-N4O5','Professional', 1, 'HQ ISR Analysis',      '2026-02-01','2028-02-01','DroneCorp IT (10.10.50.150)','Active',   NULL),
('Garuda Plex (Airspace)',    'GA-ASI',          'GPLEX-2025-P6Q7-R8S9-T0U1',   'Enterprise',   1, 'Air Traffic Coord',    '2025-06-01','2028-06-01','DroneCorp IT (10.10.50.150)','Active',   NULL),
('Zabbix Enterprise Monitoring','Zabbix LLC',   'ZBX-ENT-2025-V2W3-X4Y5-Z6A7', 'Enterprise',   1, 'IT Infrastructure',    '2025-10-01','2027-10-01','DroneCorp IT (10.10.50.150)','Active',   'Network monitoring'),
('Grafana Enterprise',        'Grafana Labs',    'GRF-ENT-2026-B8C9-D0E1-F2G3', 'Enterprise',   1, 'IT Infrastructure',    '2026-01-01','2029-01-01','DroneCorp IT (10.10.50.150)','Active',   'Telemetry dashboards'),
('ELK Stack License',         'Elastic NV',      'ELK-2025-H4I5-J6K7-L8M9',     'Enterprise',   1, 'IT Security',          '2025-07-01','2027-07-01','DroneCorp IT (10.10.50.150)','Active',   'Log management'),
('Tenable Nessus Pro',        'Tenable Inc',     'NES-PRO-2026-N0O1-P2Q3-R4S5', 'Professional', 1, 'IT Security',          '2026-03-01','2027-03-01','DroneCorp IT (10.10.50.150)','Active',   'Vulnerability scanner'),
('Ansible Tower',             'Red Hat',         'ANS-TWR-2025-T6U7-V8W9-X0Y1', 'Enterprise',   1, 'IT DevOps',            '2025-11-01','2027-11-01','DroneCorp IT (10.10.50.150)','Active',   NULL),
('Nagios XI',                 'Nagios Ent LLC',  'NAGXI-2025-Z2A3-B4C5-D6E7',   'Enterprise',   1, 'IT Infrastructure',    '2025-02-01','2027-02-01','DroneCorp IT (10.10.50.150)','Active',   'Server monitoring');


-- ============================================================
-- Grant privileges to tech2 on all tables
-- ============================================================
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO tech2;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO tech2;

SQLEOF

echo "[+] Database schema and data created successfully."

# =============================================================================
# 4. CONFIGURE POSTGRESQL FOR REMOTE ACCESS
# =============================================================================
echo "[*] Configuring PostgreSQL for remote access..."

PG_CONF_DIR="/etc/postgresql/${PG_VERSION}/main"
if [ ! -d "$PG_CONF_DIR" ]; then
    PG_CONF_DIR=$(find /etc/postgresql -name "postgresql.conf" -exec dirname {} \; | head -1)
fi

# Allow connections from 10.10.50.0/24
sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/" "${PG_CONF_DIR}/postgresql.conf" 2>/dev/null || \
    sed -i "s/listen_addresses = 'localhost'/listen_addresses = '*'/" "${PG_CONF_DIR}/postgresql.conf" 2>/dev/null || true

# Add pg_hba.conf entry
echo "host    dronecorp_db    tech2    10.10.50.0/24    md5" >> "${PG_CONF_DIR}/pg_hba.conf"

# Restart PostgreSQL
systemctl restart postgresql

# =============================================================================
# 5. FLAG_7 — placed in postgres home directory
# =============================================================================
echo "[*] Placing Flag_7..."

PG_HOME=$(getent passwd postgres | cut -d: -f6)
cat > "${PG_HOME}/flag.txt" << 'EOF'
flag{0mg_RC3}
EOF
chmod 644 "${PG_HOME}/flag.txt"
chown postgres:postgres "${PG_HOME}/flag.txt"

# Also place it in /var/lib/postgresql/ for visibility after reverse shell
if [ -d /var/lib/postgresql ]; then
    cp "${PG_HOME}/flag.txt" /var/lib/postgresql/flag.txt 2>/dev/null || true
fi

# =============================================================================
# 6. LEGACY/ABANDONED ENVIRONMENT SETUP
# =============================================================================
echo "[*] Creating legacy environment..."

# Old backups from years ago
mkdir -p /var/backups/dronecorp

# Fake old SQL dumps with old dates
touch -t 202301010300 /var/backups/dronecorp/db_backup_2023-01-01.sql.gz
touch -t 202312010300 /var/backups/dronecorp/db_backup_2023-12-01.sql.gz
touch -t 202406010300 /var/backups/dronecorp/db_backup_2024-06-01.sql.gz
echo "-- DroneCorp DB backup 2023-01-01 (legacy)" | gzip > /var/backups/dronecorp/db_backup_2023-01-01.sql.gz
echo "-- DroneCorp DB backup 2023-12-01" | gzip > /var/backups/dronecorp/db_backup_2023-12-01.sql.gz
echo "-- DroneCorp DB backup 2024-06-01" | gzip > /var/backups/dronecorp/db_backup_2024-06-01.sql.gz

# Legacy postgres configs with "temporary" comments
cat >> /etc/postgresql/${PG_VERSION}/main/postgresql.conf << 'EOF'

# === LEGACY SETTINGS — temporary until migration to v14 ===
# TODO: migrate to PostgreSQL 14 cluster (ticket IT-2024-0187, open since 2024)
# DO NOT DECOMMISSION until migration complete
# Last reviewed: 2025-03-10 — still needed

log_min_duration_statement = 5000
log_connections = on
EOF

# Cron backup script with failures
mkdir -p /var/log/dronecorp
cat > /var/log/dronecorp/backup_cron.log << 'EOF'
2026-07-01 03:00:01 [CRON] pg_dump: BACKUP OK — /var/backups/dronecorp/db_backup_2026-07-01.sql.gz
2026-07-08 03:00:02 [CRON] pg_dump: BACKUP OK
2026-07-15 03:00:01 [CRON] pg_dump: ERROR — could not connect: Connection refused
2026-07-22 03:00:01 [CRON] pg_dump: ERROR — could not connect: Connection refused
2026-07-29 03:00:01 [CRON] pg_dump: BACKUP OK
2026-08-05 03:00:02 [CRON] pg_dump: BACKUP OK
2026-08-12 03:00:01 [CRON] pg_dump: ERROR — FATAL: password authentication failed for user "backup_svc"
2026-08-19 03:00:01 [CRON] pg_dump: ERROR — FATAL: password authentication failed for user "backup_svc"
2026-08-26 03:00:01 [CRON] pg_dump: ERROR — FATAL: password authentication failed for user "backup_svc"
EOF

# MOTD
cat > /etc/motd << 'EOF'

  *** DroneCorp — DB Server (Legacy PostgreSQL) ***

  WARNING: This is a legacy database server.
  Migration to PostgreSQL 14 is planned (IT-2024-0187).
  Do NOT decommission until migration is complete.

  Contact: tech2 team | IT ticket system: 10.10.50.150

EOF

# =============================================================================
# 7. HOSTNAME & SSH
# =============================================================================
hostnamectl set-hostname db-station 2>/dev/null || hostname db-station

systemctl enable ssh 2>/dev/null || true
systemctl start ssh 2>/dev/null || true

echo ""
echo "============================================================"
echo "[+] DB_station setup COMPLETE."
echo ""
echo "    PostgreSQL DB:  dronecorp_db"
echo "    DB User:        tech2 / adfGt54DCf  (SUPERUSER)"
echo "    Flag_6:         flag{adfGt54DCf}  (= tech2 password)"
echo "    Flag_7:         ${PG_HOME}/flag.txt"
echo ""
echo "    RCE via PostgreSQL:"
echo "      psql -h 10.10.50.100 -U tech2 -d dronecorp_db"
echo "      > CREATE TABLE cmd_exec (output text);"
echo "      > COPY cmd_exec FROM PROGRAM 'id';"
echo "      > SELECT * FROM cmd_exec;"
echo "============================================================"
