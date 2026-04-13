#!/bin/bash

set -e

echo "==> Cleanup..."
docker rm -f postgres redis backend 2>/dev/null || true
docker volume rm postgres_data 2>/dev/null || true

echo "==> Creating network..."
docker network create product-network || true

echo "==> Creating volumes..."
docker volume create postgres_data

echo "==> Starting PostgresSQL..."
docker run -d \
  --name postgres \
  --network product-network \
  -e POSTGRES_USER=app \
  -e POSTGRES_PASSWORD=app \
  -e POSTGRES_DB=products \
  -v postgres_data:/var/lib/postgresql/data \
  postgres:16

echo "==> Starting Redis (tmpfs)..."
docker run -d \
  --name redis \
  --network product-network \
  --tmpfs /data \
  redis:7

echo "==> Starting backend (bind mount + tmpfs)..."
docker run -d \
  --name backend \
  --network product-network \
  -p 4000:4000 \
  --restart unless-stopped \
  -e POSTGRES_HOST=postgres \
  -e POSTGRES_USER=app \
  -e POSTGRES_PASSWORD=app \
  -e POSTGRES_DB=products \
  -e REDIS_HOST=redis \
  -v $(pwd)/config:/app/config \
  --tmpfs /tmp \
  msynowiecki/cloud-technologies-project-backend:v5