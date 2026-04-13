# Environment Documentation

This document covers how to run the NZ Tech Events app in development, test,
and production environments, including all required and optional configuration.

---

## Development

### Running Locally (Native Ruby)

```bash
bundle install
bin/rails db:prepare
bin/rails db:seed
bin/rails server
# Visit http://localhost:3000
```

### Running Locally (Docker Compose)

```bash
docker compose up
# Visit http://localhost:3000
```

The Docker Compose setup mounts the project directory as a volume so file
changes are reflected immediately (live reload via Rails reloading).

### Environment Variables

Copy `.env.example` to `.env` and fill in values as needed. The `dotenv-rails`
gem loads this file automatically in development.

```bash
cp .env.example .env
```

Most variables are optional for local development. The app runs with sensible
defaults out of the box.

### Database

- **Primary:** `storage/development.sqlite3`
- **Cache (Solid Cache):** `storage/development_cache.sqlite3`
- **Queue (Solid Queue):** `storage/development_queue.sqlite3`

All three are SQLite files stored in the `storage/` directory. No external
database server is needed.

### Email

By default, development uses the `letter_opener` gem, which opens sent emails
in a new browser tab instead of delivering them.

To test real SMTP delivery in development, set in your `.env`:

```
EMAIL_DELIVERY_METHOD=smtp
SMTP_USERNAME=your-username
SMTP_PASSWORD=your-password
```

### Google OAuth

Optional. To enable Google sign-in locally:

1. Create OAuth credentials in the Google Cloud Console
2. Set `GOOGLE_CLIENT_ID` and `GOOGLE_CLIENT_SECRET` in `.env`
3. Add `http://localhost:3000/auth/google_oauth2/callback` as an authorized
   redirect URI

The app works fine without Google OAuth -- users can sign up with
email/password instead.

### reCAPTCHA

Disabled by default. Only enabled when `ENABLE_RECAPTCHA=true` is set in
`.env`. When disabled, the signup and event creation forms work without
any CAPTCHA challenge.

---

## Test

### Running Tests

```bash
# Native Ruby
bin/rails test

# Docker Compose
docker compose run --rm test
```

Tests run in parallel and typically complete in about 3 seconds.

### Database

- **Primary:** `storage/test.sqlite3`
- **Cache:** `storage/test_cache.sqlite3`
- **Queue:** `storage/test_queue.sqlite3`

The test database is wiped and recreated between test runs. Do not rely on
data persisting across runs.

### Email

Uses `ActionMailer::Base.delivery_method = :test`, which accumulates sent
emails in `ActionMailer::Base.deliveries` for assertion in tests.

### reCAPTCHA

The `recaptcha` gem automatically skips verification in the test environment.
No configuration needed.

### Fixtures

Test fixtures are loaded automatically before each test run. See
`test/fixtures/` for the fixture files and `docs/testing.md` for full
guidance on test patterns.

### Eager Loading

Eager loading is disabled by default in test but enabled when the `CI`
environment variable is present, ensuring production-like loading is validated
in CI pipelines.

---

## Production

### Deployment

Deployed via Kamal 2 to Hetzner. See the project README and `plan-deployment.md`
for full Kamal setup instructions.

```bash
kamal setup    # First-time server setup
kamal deploy   # Deploy changes
kamal logs     # View logs
```

### Required Environment Variables

| Variable           | Description                              |
|--------------------|------------------------------------------|
| `SECRET_KEY_BASE`  | Rails secret key (generate with `bin/rails secret`) |
| `RAILS_MASTER_KEY` | Contents of `config/master.key`          |
| `SMTP_USERNAME`    | SMTP credentials for email delivery      |
| `SMTP_PASSWORD`    | SMTP credentials for email delivery      |

### SSL

SSL is enforced via `config.force_ssl = true`. The health check endpoint
(`/up`) is excluded from the HTTPS redirect so load balancers can reach it
over HTTP.

### Database

- **Primary:** `storage/production.sqlite3`
- **Cache (Solid Cache):** `storage/production_cache.sqlite3`
- **Queue (Solid Queue):** `storage/production_queue.sqlite3`

The `storage/` directory is mounted as a persistent Docker volume by Kamal.
Back up the SQLite files regularly by copying them.

### Email

Production uses SMTP delivery via ZeptoMail (`smtp.zeptomail.com` on port 587).
`SMTP_USERNAME` and `SMTP_PASSWORD` must be set.

### Google OAuth

Optional. If enabled, create production OAuth credentials in the Google Cloud
Console and set `GOOGLE_CLIENT_ID` and `GOOGLE_CLIENT_SECRET`. The authorized
redirect URI should be `https://techevents.co.nz/auth/google_oauth2/callback`.

### reCAPTCHA

If enabled (`ENABLE_RECAPTCHA=true`), both v2 and v3 site/secret key pairs
must be set.

### Caching and Queuing

- **Cache store:** Solid Cache (SQLite-backed, replaces in-memory store)
- **Job queue:** Solid Queue (SQLite-backed, replaces in-process queue)
- Solid Queue can run inside Puma via the `SOLID_QUEUE_IN_PUMA` env var for
  single-server deployments.

---

## Environment Variable Reference

| Variable                  | Development | Test | Production | Required |
|---------------------------|:-----------:|:----:|:----------:|:--------:|
| `RAILS_ENV`               | Set to `development` (default) | Set to `test` (automatic) | Set to `production` | No (defaults work) |
| `SECRET_KEY_BASE`         | Auto-generated | Auto-generated | Must be set | Production only |
| `RAILS_MASTER_KEY`        | From `config/master.key` | From `config/master.key` | Must be set | Production only |
| `GOOGLE_CLIENT_ID`        | Optional | N/A | Optional | No |
| `GOOGLE_CLIENT_SECRET`    | Optional | N/A | Optional | No |
| `ENABLE_RECAPTCHA`        | Optional (`true` to enable) | Skipped automatically | Optional (`true` to enable) | No |
| `RECAPTCHA_V3_SITE_KEY`   | If reCAPTCHA enabled | N/A | If reCAPTCHA enabled | If reCAPTCHA enabled |
| `RECAPTCHA_V3_SECRET_KEY` | If reCAPTCHA enabled | N/A | If reCAPTCHA enabled | If reCAPTCHA enabled |
| `RECAPTCHA_V2_SITE_KEY`   | If reCAPTCHA enabled | N/A | If reCAPTCHA enabled | If reCAPTCHA enabled |
| `RECAPTCHA_V2_SECRET_KEY` | If reCAPTCHA enabled | N/A | If reCAPTCHA enabled | If reCAPTCHA enabled |
| `EMAIL_DELIVERY_METHOD`   | Optional (`smtp` for real email) | N/A | N/A (always SMTP) | No |
| `SMTP_USERNAME`           | If using SMTP | N/A | Must be set | Production only |
| `SMTP_PASSWORD`           | If using SMTP | N/A | Must be set | Production only |
| `RAILS_MAX_THREADS`       | Optional (default: 5) | Optional (default: 5) | Optional (default: 5) | No |
| `PORT`                    | Optional (default: 3000) | N/A | Optional (default: 3000) | No |
| `SOLID_QUEUE_IN_PUMA`     | Optional | N/A | Optional | No |
| `RAILS_LOG_LEVEL`         | N/A | N/A | Optional (default: `info`) | No |
| `WEB_CONCURRENCY`         | Optional (default: 1) | N/A | Optional | No |
| `CI`                      | N/A | Optional (enables eager loading) | N/A | No |
