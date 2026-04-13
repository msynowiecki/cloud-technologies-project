#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="postgres_backup_$TIMESTAMP.sql"

echo "==> Creating database backup (logical dump)..."

docker exec postgres pg_dump -U app -d products > "$SCRIPT_DIR/$BACKUP_FILE"

echo "==> Backup created: $BACKUP_FILE"