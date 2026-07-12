# Trimly admin — multi-stage production image using Next.js standalone output.

# Stage 1: workspace dependency graph (package.json files only, for layer caching)
FROM node:22-alpine AS deps
WORKDIR /app
RUN npm install -g pnpm
COPY pnpm-workspace.yaml pnpm-lock.yaml package.json ./
COPY packages/config/package.json ./packages/config/
COPY packages/database/package.json ./packages/database/
COPY packages/types/package.json ./packages/types/
COPY apps/admin/package.json ./apps/admin/
COPY apps/backend/package.json ./apps/backend/
RUN pnpm install --frozen-lockfile

# Stage 2: build
FROM deps AS builder
WORKDIR /app
COPY . .
RUN pnpm --filter @trimly/admin build

# Stage 3: runner — only the traced standalone output, non-root user
FROM node:22-alpine AS runner
WORKDIR /app
ENV NODE_ENV=production
RUN addgroup -S trimly && adduser -S trimly -G trimly

COPY --from=builder /app/apps/admin/public ./apps/admin/public
COPY --from=builder --chown=trimly:trimly /app/apps/admin/.next/standalone ./
COPY --from=builder --chown=trimly:trimly /app/apps/admin/.next/static ./apps/admin/.next/static

USER trimly
EXPOSE 3000
ENV PORT=3000
ENV HOSTNAME=0.0.0.0

HEALTHCHECK --interval=30s --timeout=5s --start-period=15s --retries=3 \
  CMD node -e "fetch('http://127.0.0.1:'+(process.env.PORT||3000)+'/login').then(r=>process.exit(r.status<500?0:1)).catch(()=>process.exit(1))"

CMD ["node", "apps/admin/server.js"]
