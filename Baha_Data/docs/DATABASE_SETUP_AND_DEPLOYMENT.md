# BAHA Database Setup and Deployment

## 1. Purpose

This document explains how to run and validate the BAHA PostgreSQL database locally and how to prepare a production-grade database deployment later.

It covers:

- local database setup
- migration behavior
- validation steps
- production deployment recommendations
- current blocker status in this workspace

## 2. Current State

The repository already includes:

- a Docker Compose setup with a local PostgreSQL image built from `migrations/`
- automatic migration initialization baked into that image
- a lightweight default API runtime in `Dockerfile`
- a heavier full runtime in `Dockerfile.full` for acquisition and richer retrieval work
- Kubernetes manifests for API deployment
- production-oriented environment placeholders

Relevant files:

- [docker-compose.yml](/Users/sudharshan/Desktop/PES/RF%20Internship/Baha_Data/docker-compose.yml)
- [.env.example](/Users/sudharshan/Desktop/PES/RF%20Internship/Baha_Data/.env.example)
- [migrations/Dockerfile](/Users/sudharshan/Desktop/PES/RF%20Internship/Baha_Data/migrations/Dockerfile)
- [configmap.yaml](/Users/sudharshan/Desktop/PES/RF%20Internship/Baha_Data/deploy/k8s/configmap.yaml)
- [secret.example.yaml](/Users/sudharshan/Desktop/PES/RF%20Internship/Baha_Data/deploy/k8s/secret.example.yaml)

## 3. Local Database Setup

### 3.1 Prerequisites

You need:

- Docker Desktop or another running Docker daemon
- Docker Compose

### 3.2 Start the local database

From `Baha_Data/`:

```bash
docker compose up -d --build postgres
```

This starts:

- PostgreSQL 16 with pgvector
- a local DB image that already contains the SQL migrations
- database name: `baha_rag`
- user: `baha`
- password: `baha`
- host port: `5433`

### 3.3 Start the API after the database is healthy

```bash
docker compose up -d api
```

Default local API behavior:

- installs only the mobile/API dependency set
- uses `EMBEDDING_BACKEND=hash`
- does not include acquisition-heavy runtime dependencies by default

If you need the full acquisition or retrieval runtime locally, build:

```bash
docker build -f Dockerfile.full -t baha_data-api:full .
```

### 3.4 What happens automatically

The Postgres image copies every ordered SQL file from `migrations/` into `/docker-entrypoint-initdb.d` at build time.

On first database initialization, Postgres executes the SQL migrations in file order.

That means the following should be created automatically on first boot:

- the knowledge schema
- the acquisition schema
- the graph and embeddings schema
- the new product content schema
- the new identity and consent schema
- the new student wellness schema
- the learning and chat runtime schema
- the support and safeguarding schema
- the app read-model schema
- the demo seed dataset used for backend handoff

## 4. Local Validation Checklist

After starting the database:

1. Check container health:

```bash
docker compose ps
```

2. Inspect logs:

```bash
docker compose logs postgres
```

3. Confirm the API can start:

```bash
docker compose up -d api
docker compose logs api
```

4. Confirm health endpoint:

```bash
curl http://localhost:8000/health
```

Optional readiness check:

```bash
curl http://localhost:8000/health/ready
```

5. Validate tables exist by connecting to Postgres and checking:

- `content_items`
- `content_versions`
- `safe_questions`
- `learning_modules`
- `users`
- `student_profiles`
- `consent_records`
- `privacy_tier_settings`
- `quizzes`
- `module_progress`
- `chat_sessions`
- `help_requests`
- `monitoring_signals`
- `escalation_cases`
- `student_weekly_summaries`
- `parent_weekly_summaries`
- `teacher_cohort_summaries`

6. Validate counselor demo seed coverage:

- one open help request
- two monitoring signals
- one escalation case
- one active case assignment
- one seeded case note

## 5. Local Docker Notes for This Workspace

The earlier version of this setup mounted `./migrations` directly from the host path. In this workspace that created Docker Desktop mount failures from the Desktop-based repo path.

That issue has been reduced by changing the database service to build a local Postgres image with the migrations baked in. This is a better default for local backend development because:

- it removes the fragile bind mount
- it keeps schema startup reproducible
- it stays aligned with how the backend will actually be deployed later

The API side now also uses runtime profiles:

- default `Dockerfile`: lightweight Flutter-facing API runtime
- `Dockerfile.full`: acquisition and full retrieval runtime

There are still two important operational realities:

- Docker Desktop still needs to be running
- first boot still only applies init SQL to a fresh Postgres data volume

If you need a clean rebuild of the local database after changing migrations:

```bash
docker compose down -v
docker compose up -d --build postgres
```

If your local Docker environment still has path-sharing issues for some other reason, the temp-path workaround remains acceptable:

```bash
cp -R "/Users/sudharshan/Desktop/PES/RF Internship/Baha_Data" /private/tmp/baha_data_local
cd /private/tmp/baha_data_local
docker compose up -d --build postgres
```

## 6. Production Database Recommendation

### 6.1 Use managed PostgreSQL

Recommended production choice:

- managed PostgreSQL 16+
- pgvector enabled
- automated backups
- point-in-time recovery
- private network access

Do not use:

- in-cluster PostgreSQL for production child-data workloads
- a local node volume as the primary production data store

### 6.2 Production storage split

Use:

- PostgreSQL for structured product data
- object storage for raw files and large assets

Do not store large binary source files in PostgreSQL.

### 6.3 Production environment variables

At minimum:

- `DATABASE_URL`
- `ENVIRONMENT=production`
- `STORAGE_ROOT`
- embedding and retrieval configuration

### 6.4 Security requirements

For production:

- use strong DB credentials
- restrict DB access to API and trusted jobs only
- require TLS where supported
- keep secrets out of committed YAML
- separate application roles if possible:
  - app read/write role
  - migration/admin role
  - analytics read role

## 7. Mobile App Clarification

Using Docker for the database is the right choice for the backend and local development workflow, but not because the mobile apps will carry the database themselves.

The intended runtime model is:

- Flutter mobile apps run on Android or iOS
- the apps call backend APIs
- the backend talks to PostgreSQL
- Docker is used to package and run the backend services locally or on servers

The mobile apps should not try to run PostgreSQL or Docker on-device.

For local Flutter development:

- Android emulator should call `http://10.0.2.2:8000`
- a physical device should call `http://<your-lan-ip>:8000`
- the backend database remains behind the API
- current mobile endpoints can use:
  - `Authorization: Bearer ...` when JWT verification env vars are configured
  - `X-BAHA-User-Id` or `X-BAHA-External-Auth-Id` during local development while hosted auth remains deferred

## 8. Production Deployment Path

### Option A: Managed Postgres plus current API deployment

Recommended.

Current preferred target stack:

- Supabase for managed PostgreSQL
- Render for the FastAPI container deployment
- optional Cloudflare R2 for raw corpus storage

Current sequencing decision:

- keep cloud credential setup and external provisioning deferred until the remaining backend implementation work is complete
- continue using local Docker for backend development until then

Steps:

1. Provision managed PostgreSQL with pgvector.
2. Create production database and application user.
3. Run all migrations in order.
4. Store `DATABASE_URL` in secret management.
5. Update Kubernetes secret with the production connection string.
6. Deploy API using the existing manifests after adjusting image, secrets, and storage paths.

### Option B: Cloud VM plus containerized Postgres

Acceptable only for early internal testing, not ideal for long-term regulated use.

### Option C: In-cluster database

Not recommended for production here.

## 9. Migration Execution Strategy in Production

Do not rely on container first-boot initialization for long-term production migration management.

Recommended production approach:

1. Maintain migrations in ordered SQL files.
2. Run migrations through a controlled deployment step before API rollout.
3. Record migration execution status.
4. Treat schema changes as release-managed infrastructure changes.

## 10. Immediate Next Operational Steps

### If you want a local running database now

1. Start Docker Desktop.
2. Run:

```bash
cd Baha_Data
docker compose up -d --build postgres
docker compose up -d api
```

3. Validate the health endpoint and logs.

### If you want a real hosted database next

1. Choose the target host:
   - Supabase
   - Azure Database for PostgreSQL
   - AWS RDS/Aurora PostgreSQL
   - GCP Cloud SQL for PostgreSQL
2. Ensure pgvector support.
3. Provision the instance.
4. Provide the connection string and secret strategy.
5. Run migrations against it.

## 10. Final Recommendation

The data platform is ready for database execution in principle.

What is missing is not schema work. It is:

- a running Docker daemon for local validation
- or cloud/database credentials for hosted deployment

The correct next operational move is:

- start Docker locally and validate the schema stack
- then decide whether the next environment is still local or a managed hosted PostgreSQL instance
