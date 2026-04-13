#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -z "${1:-}" ]; then
  echo "Usage: ./restore.sh backup_file.sql"
  exit 1
fi

BACKUP_FILE=$1

if [[ ! -f "$BACKUP_FILE" && -f "$SCRIPT_DIR/$BACKUP_FILE" ]]; then
  BACKUP_FILE="$SCRIPT_DIR/$BACKUP_FILE"
fi

echo "==> Stopping services for restore..."
docker rm -f backend postgres 2>/dev/null || true

echo "==> Re-creating database volume..."
docker volume rm postgres_data 2>/dev/null || true
docker volume create postgres_data

echo "==> Starting fresh Postgres..."
docker run -d \
  --name postgres \
  --network product-network \
  -e POSTGRES_USER=app \
  -e POSTGRES_PASSWORD=app \
  -e POSTGRES_DB=products \
  -v postgres_data:/var/lib/postgresql/data \
  postgres:16

echo "==> Waiting for Postgres to be ready..."
until docker exec postgres pg_isready -U app -d products >/dev/null 2>&1; do
  sleep 1
done

echo "==> Restoring database from SQL dump..."
cat "$BACKUP_FILE" | docker exec -i postgres psql -U app -d products

echo "==> Verifying DB..."
docker exec postgres psql -U app -d products -c "SELECT COUNT(*) FROM items;"