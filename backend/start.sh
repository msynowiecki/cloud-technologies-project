#!/bin/bash
set -e

echo "==> Removing old containers..."
docker rm -f nginx backend_1 backend_2 worker postgres redis 2>/dev/null || true

echo "==> Removing old networks..."
docker network rm proxy-net app-net db-net 2>/dev/null || true

echo "==> Creating networks..."

docker network create \
  --subnet 172.20.0.0/24 \
  --gateway 172.20.0.1 \
  proxy-net

docker network create \
  --subnet 172.21.0.0/24 \
  --gateway 172.21.0.1 \
  app-net

docker network create \
  --subnet 172.22.0.0/24 \
  --gateway 172.22.0.1 \
  db-net

echo "==> Starting PostgreSQL..."
docker run -d \
  --name postgres \
  --network db-net \
  --ip 172.22.0.10 \
  -e POSTGRES_USER=app \
  -e POSTGRES_PASSWORD=app \
  -e POSTGRES_DB=products \
  -v postgres_data:/var/lib/postgresql/data \
  postgres:16

echo "==> Starting Redis..."
docker run -d \
  --name redis \
  --network app-net \
  --ip 172.21.0.10 \
  redis:7

echo "==> Starting backend_1..."
docker run -d \
  --name backend_1 \
  --network proxy-net \
  --ip 172.20.0.10 \
  --mac-address 02:42:ac:14:00:0a \
  -e INSTANCE_ID=backend_1 \
  -e POSTGRES_HOST=postgres \
  -e POSTGRES_USER=app \
  -e POSTGRES_PASSWORD=app \
  -e POSTGRES_DB=products \
  -e REDIS_HOST=redis \
  msynowiecki/cloud-technologies-project-backend:v5

docker network connect app-net backend_1 --ip 172.21.0.11
docker network connect db-net backend_1 --ip 172.22.0.11

echo "==> Starting backend_2..."
docker run -d \
  --name backend_2 \
  --network proxy-net \
  --ip 172.20.0.11 \
  --mac-address 02:42:ac:14:00:0b \
  -e INSTANCE_ID=backend_2 \
  -e POSTGRES_HOST=postgres \
  -e POSTGRES_USER=app \
  -e POSTGRES_PASSWORD=app \
  -e POSTGRES_DB=products \
  -e REDIS_HOST=redis \
  msynowiecki/cloud-technologies-project-backend:v5

docker network connect app-net backend_2 --ip 172.21.0.12
docker network connect db-net backend_2 --ip 172.22.0.12

echo "==> Starting worker..."
docker run -d \
  --name worker \
  --network app-net \
  -e WORKER=true \
  -e POSTGRES_HOST=postgres \
  -e REDIS_HOST=redis \
  msynowiecki/cloud-technologies-project-backend:v6

docker network connect db-net worker

echo "==> Starting nginx..."
docker run -d \
  --name nginx \
  --network proxy-net \
  -p 8080:80 \
  -v $(pwd)/../frontend/nginx/default.conf:/etc/nginx/conf.d/default.conf \
  nginx

echo "==> DONE"