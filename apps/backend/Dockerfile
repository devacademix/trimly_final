# Stage 1: Build environment
FROM node:20-alpine AS builder
WORKDIR /app
RUN npm install -g pnpm
COPY pnpm-workspace.yaml pnpm-lock.yaml package.json ./
COPY packages/database/package.json ./packages/database/
COPY packages/types/package.json ./packages/types/
COPY apps/backend/package.json ./apps/backend/
RUN pnpm install --frozen-lockfile
COPY . .
RUN pnpm --filter @trimly/database build
RUN pnpm --filter @trimly/backend build

# Stage 2: Runner
FROM node:20-alpine AS runner
WORKDIR /app
RUN npm install -g pnpm
COPY --from=builder /app /app
EXPOSE 4000
CMD ["pnpm", "--filter", "@trimly/backend", "start:prod"]
