#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "==> Stopping existing containers..."
docker rm -f backend postgres redis 2>/dev/null || true

echo "==> Ensuring network exists..."
docker network create product-network 2>/dev/null || true

echo "==> Starting Postgres..."
docker run -d \
  --name postgres \
  --network product-network \
  -e POSTGRES_USER=app \
  -e POSTGRES_PASSWORD=app \
  -e POSTGRES_DB=products \
  -v postgres_data:/var/lib/postgresql/data \
  postgres:16

echo "==> Starting Redis..."
docker run -d \
  --name redis \
  --network product-network \
  --tmpfs /data \
  redis:7

echo "==> Starting backend DEV mode (hot reload)..."
docker run -it \
  --name backend \
  --network product-network \
  -p 4000:4000 \
  -e POSTGRES_HOST=postgres \
  -e POSTGRES_USER=app \
  -e POSTGRES_PASSWORD=app \
  -e POSTGRES_DB=products \
  -e REDIS_HOST=redis \
  -v "$SCRIPT_DIR:/app" \
  -v backend_node_modules:/app/node_modules \
  -w /app \
  node:20-alpine \
  sh -c "npm install && npm run dev"