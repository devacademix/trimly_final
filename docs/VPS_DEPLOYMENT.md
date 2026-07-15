# Trimly Business OS — VPS Production Deployment Guide

This guide details the step-by-step production deployment workflow for **Trimly Business OS** on an Ubuntu VPS (such as Hostinger VPS) using a unified **Docker Compose** stack, Nginx, and Certbot for SSL.

---

## 1. Prerequisites & Host OS Configuration

Ensure your Ubuntu VPS has at least:
- **2 vCPUs**
- **4 GB RAM**
- **Docker & Docker Compose installed**
- **Nginx & Certbot**

### Install Essential Packages
```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl git nginx certbot python3-certbot-nginx
```

---

## 2. Docker Installation

If Docker is not yet installed on your Ubuntu VPS, run the following commands to configure repositories and install it:

```bash
# Clean conflicting keys/repositories
sudo rm -f /etc/apt/sources.list.d/docker.list

# Setup GPG keys
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

---

## 3. Project Configuration

### 1. Clone Codebase
```bash
cd /var/www
git clone <YOUR_GITHUB_REPOSITORY_URL> trimly
cd trimly
```

### 2. Configure Environment Variables
Create a `.env` file in the root directory:
```bash
nano .env
```
Paste and configure the following:
```env
DATABASE_URL="postgresql://trimly:secure_postgres_password@postgres:5432/trimly?schema=public"
REDIS_URL="redis://:secure_redis_password@redis:6379"

JWT_ACCESS_SECRET="generate_at_least_32_characters_random_secret_string"
JWT_REFRESH_SECRET="generate_another_random_secret_string"
OTP_HMAC_SECRET="generate_a_third_random_secret_string"

RAZORPAY_KEY_ID="rzp_live_..."
RAZORPAY_KEY_SECRET="..."

PORT=4000
NODE_ENV=production
CORS_ORIGINS="https://admin.yourdomain.com,https://api.yourdomain.com"
```

---

## 4. Docker Compose Setup (Includes Automatic Migrations & Seeds)

The production stack is defined in `docker-compose.prod.yml`. It uses a dedicated `migration` container that automatically runs Prisma database migrations and seeds on startup before releasing the backend API container.

Create `docker-compose.prod.yml`:
```bash
nano docker-compose.prod.yml
```

Paste the following configuration:
```yaml
version: '3.8'

services:
  postgres:
    image: postgres:16-alpine
    container_name: trimly-postgres
    restart: always
    environment:
      POSTGRES_USER: trimly
      POSTGRES_PASSWORD: secure_postgres_password
      POSTGRES_DB: trimly
    ports:
      - "5434:5432"
    volumes:
      - pg_prod_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U trimly -d trimly"]
      interval: 5s
      timeout: 5s
      retries: 5
    networks:
      - trimly-net

  redis:
    image: redis:7-alpine
    container_name: trimly-redis
    restart: always
    command: ["redis-server", "--requirepass", "secure_redis_password", "--appendonly", "yes"]
    ports:
      - "6379:6379"
    volumes:
      - redis_prod_data:/data
    healthcheck:
      test: ["CMD", "redis-cli", "-a", "secure_redis_password", "ping"]
      interval: 5s
      timeout: 3s
      retries: 5
    networks:
      - trimly-net

  migration:
    build:
      context: .
      dockerfile: apps/backend/Dockerfile
      target: builder
    container_name: trimly-migration
    environment:
      DATABASE_URL: "postgresql://trimly:secure_postgres_password@postgres:5432/trimly?schema=public"
      DIRECT_DATABASE_URL: "postgresql://trimly:secure_postgres_password@postgres:5432/trimly?schema=public"
    command: >
      sh -c "pnpm --filter @trimly/database db:generate && pnpm --filter @trimly/database exec prisma db push --accept-data-loss && pnpm --filter @trimly/database db:seed"
    depends_on:
      postgres:
        condition: service_healthy
    networks:
      - trimly-net

  backend:
    build:
      context: .
      dockerfile: apps/backend/Dockerfile
    container_name: trimly-backend
    restart: always
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
      migration:
        condition: service_completed_successfully
    ports:
      - "4000:4000"
    env_file:
      - .env
    networks:
      - trimly-net

  admin:
    build:
      context: .
      dockerfile: apps/admin/Dockerfile
      args:
        - NEXT_PUBLIC_API_URL=https://api.yourdomain.com/api/v1
    container_name: trimly-admin
    restart: always
    ports:
      - "3000:3000"
    depends_on:
      backend:
        condition: service_healthy
    networks:
      - trimly-net

volumes:
  pg_prod_data:
  redis_prod_data:

networks:
  trimly-net:
    driver: bridge
```

Run the build and start command:
```bash
docker compose -f docker-compose.prod.yml up -d --build
```
*Docker will automatically launch databases, build both backend/admin, run all migrations & seeds, and finally release the live servers.*

---

## 5. Nginx Reverse Proxy & SSL Setup

Configure Nginx to reverse-proxy traffic from port 80/443 to the NestJS app (port 4000) and Next.js admin (port 3000).

Create `/etc/nginx/sites-available/trimly` configuration file:
```nginx
server {
    listen 80;
    server_name api.yourdomain.com;

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

server {
    listen 80;
    server_name admin.yourdomain.com;

    location / {
        proxy_pass http://127.0.0.1:3000;
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
sudo certbot --nginx -d api.yourdomain.com -d admin.yourdomain.com
```
