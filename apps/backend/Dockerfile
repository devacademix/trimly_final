# Trimly backend — multi-stage production image.
#
# Node 24 is required (not just "hardening"): @trimly/database and parts of
# this workspace ship raw TypeScript with no transpiled `dist` and rely on
# Node's native TypeScript type-stripping (stable from Node 22.6+). Building
# this image against node:20-alpine will fail at runtime with a syntax error
# the moment `@trimly/database` is required.

# Stage 1: workspace dependency graph (package.json files only, for layer caching)
FROM node:24-alpine AS deps
WORKDIR /app
RUN npm install -g pnpm
COPY pnpm-workspace.yaml pnpm-lock.yaml package.json ./
COPY packages/config/package.json ./packages/config/
COPY packages/database/package.json ./packages/database/
COPY packages/types/package.json ./packages/types/
COPY apps/admin/package.json ./apps/admin/
COPY apps/backend/package.json ./apps/backend/
RUN pnpm install --frozen-lockfile

# Stage 2: build (full source, full deps incl. devDependencies)
FROM deps AS builder
WORKDIR /app
COPY . .
RUN pnpm --filter @trimly/database db:generate
RUN pnpm --filter @trimly/types build
RUN pnpm --filter @trimly/backend build

# Stage 3: production-only dependency graph (no devDependencies, e.g. no @nestjs/cli, no ts-jest)
FROM node:24-alpine AS prod-deps
WORKDIR /app
RUN npm install -g pnpm
COPY pnpm-workspace.yaml pnpm-lock.yaml package.json ./
COPY packages/config/package.json ./packages/config/
COPY packages/database/package.json ./packages/database/
COPY packages/types/package.json ./packages/types/
COPY apps/admin/package.json ./apps/admin/
COPY apps/backend/package.json ./apps/backend/
RUN pnpm install --filter @trimly/backend... --prod --frozen-lockfile

# Stage 4: runner — only compiled output + pruned prod node_modules, non-root user
FROM node:24-alpine AS runner
WORKDIR /app
ENV NODE_ENV=production
RUN addgroup -S trimly && adduser -S trimly -G trimly

COPY --from=prod-deps /app/node_modules ./node_modules
COPY --from=prod-deps /app/package.json ./package.json

COPY --from=builder /app/packages/database/package.json ./packages/database/package.json
COPY --from=builder /app/packages/database/src/index.ts ./packages/database/src/index.ts
COPY --from=builder /app/packages/database/src/generated ./packages/database/src/generated
COPY --from=builder /app/packages/types/package.json ./packages/types/package.json
COPY --from=builder /app/packages/types/dist ./packages/types/dist
COPY --from=builder /app/apps/backend/package.json ./apps/backend/package.json
COPY --from=builder /app/apps/backend/dist ./apps/backend/dist

USER trimly
EXPOSE 4000

HEALTHCHECK --interval=30s --timeout=5s --start-period=15s --retries=3 \
  CMD node -e "fetch('http://127.0.0.1:'+(process.env.PORT||4000)+'/api/v1/metrics').then(r=>process.exit(r.ok?0:1)).catch(()=>process.exit(1))"

CMD ["node", "apps/backend/dist/main.js"]
