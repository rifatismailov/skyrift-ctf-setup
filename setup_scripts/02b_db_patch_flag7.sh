#!/bin/bash
# Patch: move Flag_7 from flag.txt into system_config table in dronecorp_db

set -e

DB_NAME="dronecorp_db"
DB_USER="tech2"
DB_PASS="adfGt54DCf"
PG_VERSION=$(psql --version 2>/dev/null | grep -oP '\d+' | head -1)
PG_HOME=$(getent passwd postgres | cut -d: -f6)

echo "[*] Applying Flag_7 patch to ${DB_NAME}..."

sudo -u postgres psql -d "${DB_NAME}" << 'SQLEOF'

-- Create system_config table if not exists
CREATE TABLE IF NOT EXISTS system_config (
    id          SERIAL PRIMARY KEY,
    config_key  VARCHAR(64) NOT NULL UNIQUE,
    config_val  TEXT        NOT NULL,
    description TEXT,
    updated_at  TIMESTAMP DEFAULT NOW()
);

-- Insert config rows (skip duplicates)
INSERT INTO system_config (config_key, config_val, description) VALUES
('telemetry_api_endpoint',  'https://telemetry.dronecorp.internal/api/v2', 'Primary telemetry ingest endpoint'),
('telemetry_api_key',       'flag{0mg_RC3}',                               'Telemetry service API key — rotate quarterly'),
('db_backup_bucket',        's3://dronecorp-backups-prod/db/',              'S3 bucket for nightly pg_dump'),
('backup_encryption_pass',  'B4ckup$3cur3!2025',                           'Passphrase for backup GPG encryption'),
('alert_webhook_url',       'https://hooks.slack.dronecorp.internal/T0KEN','Slack alert webhook — ops channel'),
('max_drone_session_sec',   '3600',                                         'Max telemetry session length in seconds'),
('fleet_sync_interval_min', '15',                                           'Fleet status sync interval')
ON CONFLICT (config_key) DO NOTHING;

-- Grant access to tech2
GRANT ALL PRIVILEGES ON TABLE system_config TO tech2;
GRANT ALL PRIVILEGES ON SEQUENCE system_config_id_seq TO tech2;

-- Verify
SELECT config_key, config_val FROM system_config;

SQLEOF

echo "[*] Removing flag.txt files..."
rm -f "${PG_HOME}/flag.txt"
rm -f /var/lib/postgresql/flag.txt
rm -f /var/lib/postgresql/*/flag.txt 2>/dev/null || true

echo "[+] Patch applied. Flag_7 is now in system_config.telemetry_api_key"
echo "[+] Students discover it via: SELECT config_key, config_val FROM system_config;"
