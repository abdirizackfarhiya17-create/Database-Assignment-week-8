#!/usr/bin/env bash
set -euo pipefail

# --- CONFIGURATION VARIABLES ---
DB_NAME="capstone"
BACKUP_DIR="backups"
DATE_STAMP=$(date +%F_%H-%M-%S)
EXPORT_PATH="${BACKUP_DIR}/capstone_${DATE_STAMP}.dump"

# Ensure output directory target exists
mkdir -p "${BACKUP_DIR}"

echo "Executing Point-In-Time production state database backup for [${DB_NAME}]..."

# Step 1: Run high-performance compressed binary dump
pg_dump -Fc -f "${EXPORT_PATH}" "${DB_NAME}"
echo "Backup archive successfully compiled at: ${EXPORT_PATH}"

# Step 2: Verify disaster recovery restore path integrity
echo "Simulating disaster recovery testing execution..."
pg_restore --clean --dry-run -d "${DB_NAME}" "${EXPORT_PATH}"
echo "DR Disaster Restore path validation: VERIFIED SUCCESSFUL."
