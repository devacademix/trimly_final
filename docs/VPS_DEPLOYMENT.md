# Trimly Business OS — VPS Production Deployment Guide

This guide details the step-by-step production deployment workflow for **Trimly Business OS** on an Ubuntu VPS.

---

## 1. Prerequisites & Host OS Configuration

Ensure your Ubuntu VPS has at least:
- **2 vCPUs**
- **4 GB RAM**
- **Docker & Docker Compose v2 installed**
- **Nginx & Certbot**

### Install Essential Packages
```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl git nginx certbot python3-certbot-nginx
```

---

## 2. Docker Infrastructure Setup

For production, we will run PostgreSQL and Redis inside isolated Docker containers. Create `docker-compose.prod.yml`:

```yaml
version: '3.8'

services:
  postgres:
    image: postgres:16-alpine
    container_name: trimly-postgres-prod
    restart: always
    environment:
      POSTGRES_USER: trimly_admin
      POSTGRES_PASSWORD: production_secure_db_password
      POSTGRES_DB: trimly_prod
    ports:
      - "5432:5432"
    volumes:
      - pg_prod_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U trimly_admin -d trimly_prod"]
      interval: 10s
      timeout: 5s
      retries: 5

  redis:
    image: redis:7-alpine
    container_name: trimly-redis-prod
    restart: always
    command: ["redis-server", "--requirepass", "production_secure_redis_password", "--appendonly", "yes"]
    ports:
      - "6379:6379"
    volumes:
      - redis_prod_data:/data

volumes:
  pg_prod_data:
  redis_prod_data:
```

Launch the databases:
```bash
docker compose -f docker-compose.prod.yml up -d
```

---

## 3. NestJS Backend Deployment

Build and run the NestJS API server inside the VPS using Docker or PM2.

### Option A: Using Docker (Recommended)
Build the NestJS backend Docker image:
```bash
docker build -t trimly-backend:latest -f apps/backend/Dockerfile .
```

Run the backend container:
```bash
docker run -d \
  --name trimly-api \
  --restart always \
  -p 4000:4000 \
  -e DATABASE_URL="postgresql://trimly_admin:production_secure_db_password@localhost:5432/trimly_prod?schema=public" \
  -e REDIS_URL="redis://:production_secure_redis_password@localhost:6379" \
  -e JWT_SECRET="production_secure_jwt_secret_key" \
  -e RAZORPAY_KEY_ID="rzp_live_..." \
  -e RAZORPAY_KEY_SECRET="..." \
  trimly-backend:latest
```

---

## 4. Nginx Reverse Proxy & SSL Setup

Configure Nginx to reverse-proxy traffic from port 80/443 to the NestJS app (port 4000) and Next.js admin/salon-app.

Create `/etc/nginx/sites-available/trimly` configuration file:

```nginx
server {
    listen 80;
    server_name api.trimly.com;

    location / {
        proxy_pass http://127.0.0.1:4000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
```

Enable configuration and setup SSL certificates:
```bash
sudo ln -s /etc/nginx/sites-available/trimly /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx

# Obtain SSL Certificate
sudo certbot --nginx -d api.trimly.com
```

---

## 5. Database Migrations

Deploy the latest Prisma schema changes and run seed files:
```bash
pnpm prisma migrate deploy
pnpm prisma db seed
```
