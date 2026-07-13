# BAHA Interactive Prototype

This workspace now includes a complete local-first Next.js stakeholder prototype scaffold powered by the BAHA architecture documentation.

## Key Folders

- [app](/Users/solomonkaruppiah/Desktop/Baha_Data/app)
- [apps](/Users/solomonkaruppiah/Desktop/Baha_Data/apps)
- [components](/Users/solomonkaruppiah/Desktop/Baha_Data/components)
- [design-system](/Users/solomonkaruppiah/Desktop/Baha_Data/design-system)
- [mock-data](/Users/solomonkaruppiah/Desktop/Baha_Data/mock-data)
- [hooks](/Users/solomonkaruppiah/Desktop/Baha_Data/hooks)
- [lib](/Users/solomonkaruppiah/Desktop/Baha_Data/lib)
- [styles](/Users/solomonkaruppiah/Desktop/Baha_Data/styles)

## Commands

1. `npm install`
2. `npm run dev`

## Backend Foundation

The repo now also includes a production-oriented FastAPI backend foundation for the BAHA Wellness Companion chatbot in [src/baha_companion](/Users/solomonkaruppiah/Desktop/Baha_Data/src/baha_companion).

Core capabilities included in this backend:

- JWT authentication with register, login, refresh, and logout
- PostgreSQL with SQLAlchemy and Alembic migrations
- user, conversation, message, and refresh-token persistence
- health probes, request-id middleware, and environment-driven configuration
- Docker and `docker-compose` support

Useful commands:

1. `docker compose up --build`
2. `alembic upgrade head`
3. `uvicorn baha_companion.main:app --reload`

### Local Backend Run

1. `cp .env.example .env`
2. Edit `.env` and set at least:
   `OPENAI_API_KEY=your_key_here`
   `AUTH_SECRET_KEY=replace-with-a-long-random-secret`
3. Start fresh if you previously had a broken local Postgres volume:
   `docker compose down -v --remove-orphans`
4. Build and start the backend:
   `docker compose up --build`
5. Open:
   `http://localhost:8000/docs`
   `http://localhost:8000/health/ready`

If you want to use a custom LLM model entry, keep `LLM_MODEL_CATALOG_JSON` on a single line in valid JSON format inside `.env`.

## Source of Truth

The prototype is generated from:

- [docs/13_UX_Specification](/Users/solomonkaruppiah/Desktop/Baha_Data/docs/13_UX_Specification)
- [docs/14_Navigation](/Users/solomonkaruppiah/Desktop/Baha_Data/docs/14_Navigation)
- [docs/15_Design_System](/Users/solomonkaruppiah/Desktop/Baha_Data/docs/15_Design_System)
- [docs/16_Visual_Language](/Users/solomonkaruppiah/Desktop/Baha_Data/docs/16_Visual_Language)

## Generator

The scaffold is produced by [scripts/generate_baha_interactive_prototype_phase6.py](/Users/solomonkaruppiah/Desktop/Baha_Data/scripts/generate_baha_interactive_prototype_phase6.py).
