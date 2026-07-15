# BAHA Environment And Secrets Contract

## 1. Purpose

This document defines the environment variables and secrets expected by the backend.

It is intended for:

- local development
- hosted deployment setup
- Flutter/backend integration handoff

## 2. Database

- `DATABASE_URL`

Local example:

```bash
postgresql+asyncpg://baha:baha@localhost:5433/baha_rag
```

## 3. Auth

Bearer-token verification can use one of two paths.

### JWKS-based verification

- `AUTH_JWKS_URL`
- `AUTH_ISSUER`
- `AUTH_AUDIENCE`

Recommended for Supabase-style hosted auth.

### Secret-based verification

- `AUTH_JWT_SECRET`
- `AUTH_ISSUER`
- `AUTH_AUDIENCE`

### Development fallback

- `ALLOW_DEV_IDENTITY_HEADERS=true|false`

If `true`, the backend can still accept development identity headers when bearer-token verification is not configured.

## 4. Object Storage

- `OBJECT_STORAGE_PROVIDER`
- `OBJECT_STORAGE_BUCKET`
- `OBJECT_STORAGE_REGION`
- `OBJECT_STORAGE_ENDPOINT`
- `OBJECT_STORAGE_PUBLIC_BASE_URL`
- `OBJECT_STORAGE_PREFIX`

Current expected meaning:

- `local`: local filesystem-backed development mode
- `r2`: Cloudflare R2
- `s3`: S3-compatible object storage
- `supabase`: Supabase Storage-compatible integration path

## 5. API And Runtime

- `APP_NAME`
- `ENVIRONMENT`
- `ALLOWED_CORS_ORIGINS`
- `STORAGE_ROOT`

## 6. Retrieval And Embeddings

- `EMBEDDING_BACKEND`
- `EMBEDDING_MODEL`
- `EMBEDDING_DIMENSIONS`
- `EMBEDDING_CHUNK_TOKENS`
- `EMBEDDING_CHUNK_OVERLAP_TOKENS`
- `EMBEDDING_BATCH_SIZE`
- `EMBEDDING_AUTO_INDEX`
- `RETRIEVAL_TOP_K`
- `MIN_CONFIDENCE`

## 7. Crawling

- `CRAWL_CONCURRENT_REQUESTS`
- `CRAWL_DOWNLOAD_DELAY_SECONDS`
- `CRAWL_DEPTH_LIMIT`

## 8. Buddy OpenAI Generation

- `BUDDY_GENERATION_BACKEND`
- `BUDDY_OPENAI_API_KEY`
- `BUDDY_OPENAI_BASE_URL`
- `BUDDY_OPENAI_MODEL`
- `BUDDY_OPENAI_TIMEOUT_SECONDS`
- `BUDDY_HISTORY_WINDOW`
- `BUDDY_MIN_RETRIEVAL_CONFIDENCE`

Buddy now uses a single answer-generation path on top of the same local retrieval stack:

- `openai`: OpenAI Responses API generation with retrieved BAHA evidence

Current OpenAI example:

```bash
BUDDY_GENERATION_BACKEND=openai
BUDDY_OPENAI_API_KEY=...
BUDDY_OPENAI_BASE_URL=https://api.openai.com/v1
BUDDY_OPENAI_MODEL=gpt-5-nano
BUDDY_OPENAI_TIMEOUT_SECONDS=60
BUDDY_HISTORY_WINDOW=6
BUDDY_MIN_RETRIEVAL_CONFIDENCE=0.35
```

Model note:

- the repository default is now `gpt-5-nano`
- actual availability still depends on the OpenAI account and model access enabled for that environment

Operational note:

- retrieval stays local to BAHA's Postgres/pgvector stack
- `openai` changes only the final answer-generation step, not the retrieval layer
- if OpenAI is unavailable or misconfigured, Buddy should fail loudly at the API layer rather than silently falling back to a different model path

## 9. Hosted Deployment Guidance

For hosted dev or pilot deployment:

- `DATABASE_URL` should be injected as a secret
- auth-related values should be injected as secrets
- object-storage bucket and endpoint values should be injected as secrets where appropriate
- `ALLOW_DEV_IDENTITY_HEADERS` should be `false`

## 10. Current Status

The repository includes placeholders in:

- [.env.example](/Users/sudharshan/Desktop/PES/RF Internship/Baha_Data/.env.example)
- [render.yaml](/Users/sudharshan/Desktop/PES/RF Internship/render.yaml)
