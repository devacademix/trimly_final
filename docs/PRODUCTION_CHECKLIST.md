# Trimly — Production Readiness Checklist

Working checklist for taking Trimly from "builds and passes CI" to "actually
live." Update this file as items get done — it's the single source of truth
for what's left before launch.

## 1. Secrets — what needs a real value before go-live

None of these should live in a committed `.env`. Use your platform's secrets
manager (Railway/Render/Fly secrets, AWS Secrets Manager, GitHub Actions
encrypted secrets for CI/CD, etc.) — never the checked-in `.env.example`
pattern, which is a template only.

| Variable | Status | Notes |
|---|---|---|
| `DATABASE_URL` / `DIRECT_DATABASE_URL` | ⬜ Needs prod value | Managed Postgres (RDS/Neon/Supabase/Railway). Enable automated backups + point-in-time recovery. |
| `REDIS_URL` | ⬜ Needs prod value | Managed Redis (ElastiCache/Upstash/Railway). |
| `JWT_ACCESS_SECRET` / `JWT_REFRESH_SECRET` | ⬜ Needs prod value | Generate fresh, ≥32 random chars each, e.g. `openssl rand -base64 48`. Never reuse the dev value. |
| `OTP_HMAC_SECRET` | ⬜ Needs prod value | Same — fresh random secret, not the dev placeholder. |
| `SUPERADMIN_*` | ⬜ Needs prod value | Rotate the seeded password immediately after first login in prod. |
| `GOOGLE_CLIENT_ID` / `GOOGLE_CLIENT_SECRET` | ⬜ Needs prod value | From Google Cloud Console OAuth client (production redirect URI, not localhost). |
| `APPLE_*` | ⬜ Needs prod value (if shipping iOS) | Apple Developer account, Sign in with Apple key. |
| `RAZORPAY_KEY_ID` / `RAZORPAY_KEY_SECRET` / `RAZORPAY_WEBHOOK_SECRET` | ⬜ Needs LIVE keys | Currently test-mode keys only. Switch to live keys and re-register the webhook URL against the production domain before accepting real payments. |
| `S3_ACCESS_KEY_ID` / `S3_SECRET_ACCESS_KEY` / `S3_BUCKET` | ⬜ Needs prod value | S3 or R2 bucket for uploads (salon photos, etc.). |
| `FIREBASE_CREDENTIALS_PATH` | ✅ Done | Points at `C:\Users\Dell\.trimly-secrets\firebase-admin-sdk.json` locally. **For deployment**: upload this JSON to your host's secret file storage (not an env var — it's a whole file) and point the path there instead. |
| `SMTP_*` | ⬜ Needs prod value | Transactional email provider (SES/Postmark/SendGrid). |
| `SMS_PROVIDER` + `TWILIO_*` / `MSG91_*` | ⬜ Needs prod value | OTP delivery won't work in prod until one of these is configured. |
| `WHATSAPP_*` | ⬜ Optional | Only needed if WhatsApp notifications are in scope for launch. |
| `POSTHOG_API_KEY` | ⬜ Optional | Product analytics — recommended but not launch-blocking. |
| `GOOGLE_MAPS_API_KEY` | ⬜ Needs prod value | Used by both Flutter apps for places/geocoding — restrict the key by Android package name + SHA-1 fingerprint (see §4) and iOS bundle ID in Google Cloud Console. |
| `CORS_ORIGINS` / `SOCKET_IO_CORS_ORIGINS` | ⬜ Needs prod value | Must be the real admin panel + app domains, not `localhost`. |
| `NEXT_PUBLIC_API_URL` (admin) | ⬜ Needs prod value | Production backend URL, set at Docker build time (Next.js inlines `NEXT_PUBLIC_*` at build, not runtime). |

**Android release keystores** (already generated, see
`C:\Users\Dell\.trimly-secrets\RELEASE_SIGNING_README.txt`):
- Back up `customer-app-release.jks` and `salon-app-release.jks` somewhere
  durable outside this machine (password manager attachment + one offline
  copy). **If these are lost, you cannot ship updates to an app already live
  under the same package name on the Play Store.**
- Move the passwords out of the plaintext README into a password manager,
  then delete the plaintext file.

## 2. Monitoring — current state

- **Metrics**: `prom-client` is wired at `GET /api/v1/metrics` (see
  `apps/backend/src/metrics/`), exposing default Node process metrics plus
  any custom counters/histograms registered there. ⬜ **Not yet scraped by
  anything** — point a Prometheus instance (self-hosted, Grafana Cloud, or
  your host's built-in scraper) at this endpoint, or swap in a
  hosted-APM push exporter if you'd rather not run Prometheus.
- **Logs**: Winston (`apps/backend/src/common/logger/winston.logger.ts`) is
  registered via `app.useLogger()` and writing structured JSON logs to
  stdout. ⬜ **Not yet shipped anywhere durable** — stdout is fine for
  `docker logs`/`kubectl logs` locally, but for production wire your host's
  log drain (Railway/Render built-in logs, or ship to Datadog/Better
  Stack/Grafana Loki via a sidecar or the platform's native log forwarding).
- **Uptime/error alerting**: ⬜ **Not configured.** Minimum viable setup:
  - An uptime check (UptimeRobot, Better Stack, or your host's health-check
    alerting) against `GET /api/v1/metrics` or a dedicated `/health` route,
    alerting to email/Slack/WhatsApp on downtime.
  - An error-tracking SDK (Sentry is the standard choice for both NestJS and
    Flutter) — not currently integrated in the backend, admin, or either
    Flutter app. Recommended before launch so crashes/exceptions in
    production surface somewhere instead of only living in logs.

## 3. Docker / deploy

- `apps/backend/Dockerfile` and `apps/admin/Dockerfile` are both multi-stage,
  non-root, with `HEALTHCHECK`s — validated in CI (`docker build`).
- A VPS deployment path (Ubuntu + Docker Compose + Nginx + Certbot) is
  documented in `docs/VPS_DEPLOYMENT.md`, including the `docker-compose.prod.yml`
  layout. ⬜ Not yet exercised against a real server — walk through it end to
  end before launch, and note it uses `pnpm db:migrate:deploy` as the release
  migration step (not `db:migrate`, which prompts interactively).

## 4. Store submission prep

**Both apps, before either store listing:**
- Custom app icon + splash screen — tooling is wired
  (`flutter_launcher_icons` / `flutter_native_splash` in both `pubspec.yaml`
  files) but still needs real logo artwork. See
  `apps/customer-app/assets/icon/README.txt` and
  `apps/salon-app/assets/icon/README.txt` for the exact files/commands.
- Privacy policy — ✅ scaffolded at `apps/admin/app/privacy/page.tsx`,
  publicly reachable at `<admin-domain>/privacy` (no login required, indexable
  — see `apps/admin/proxy.ts` and `apps/admin/app/robots.ts`). ⬜ Still needs:
  every `[bracketed]` placeholder filled in (legal entity name, address,
  support email, data retention period) and a lawyer's review before this is
  the real policy you submit to the stores.
- Terms of service — ✅ scaffolded at `apps/admin/app/terms/page.tsx`, same
  public/indexable treatment as `/privacy`. ⬜ Same caveat: placeholders +
  legal review needed before it's launch-ready.

**Android (Play Store):**
- ⬜ Play Console developer account (one-time $25 fee) if not already set up.
- Store listing draft copy (short/long description, category, content
  rating pointers, data-safety pointers) — ✅ scaffolded at
  `docs/store-listing/customer-app.md` and `docs/store-listing/salon-app.md`.
  ⬜ Still needs: screenshots (phone + tablet if supporting tablets) and a
  feature graphic, both blocked on real app icon/branding (§4 above).
- ⬜ **Permissions review** — audit both apps'
  `android/app/src/main/AndroidManifest.xml` for requested permissions
  (location, camera, notifications, etc.) and ensure each has a legitimate,
  explainable use — Play Console's review flags unexplained sensitive
  permissions (especially background location).
- ⬜ Target API level — confirm `flutter.targetSdkVersion` (from the Flutter
  SDK's `local.properties`) meets Play Store's current minimum target API
  requirement at submission time (it moves yearly; check before submitting).
- ⬜ Get the release SHA-1 fingerprint of each keystore
  (`keytool -list -v -keystore <path>`) and register it wherever needed:
  Google Maps API key restriction (§1), Firebase Android app config, Google
  Sign-In OAuth client.
- ⬜ App bundle: submit `.aab` (`flutter build appbundle --release`), not
  `.apk` — Play Store requires App Bundle format for new apps.

**iOS (App Store) — not yet scoped:**
- No iOS signing/provisioning has been set up in this pass (Windows dev
  machine can't build iOS locally). If iOS launch is in scope, that's a
  separate piece of work requiring a Mac (or a CI service like Codemagic/
  Fastlane match) for signing, an Apple Developer account, and App Store
  Connect listing setup.

## 5. Still-open items from earlier phases worth re-checking before launch

- Backend test coverage — confirm `pnpm --filter @trimly/backend test` and
  `test:e2e` still cover the Phase 0 security regressions (cross-tenant IDOR,
  webhook signature, chat auth) as new features get added.
- Rate limiting thresholds (`RATE_LIMIT_TTL` / `RATE_LIMIT_LIMIT`,
  `@nestjs/throttler` per-route overrides on auth/OTP) — tune for real
  traffic patterns once you have any.
