# Buddy Demo RAG Setup

## Purpose

This document defines the current local workflow for getting `BAHA Buddy` into a stronger demo state without replacing the main mobile/product schema.

The main idea:

- keep the current branch as the product source of truth
- treat the Solomon RAG branch dump as a donor corpus only
- import only retrieval-related data into the current local database
- run Buddy against the full retrieval runtime when you want better chatbot quality

## What Was In The Solomon Dump

The downloaded dump at `backups/baha_rag_20260714-183725.dump` is not just a vector snapshot.

It is a full older RAG database that includes:

- `acquired_resources`
- `resource_chunks`
- `resource_embeddings`
- `knowledge_graph_nodes`
- `knowledge_graph_edges`
- `knowledge_embeddings`
- `condition_profiles`
- `condition_embeddings`
- acquisition and reporting tables

Local inspection on July 14, 2026 found these key counts:

- `acquired_resources`: `7525`
- `resource_chunks`: `25039`
- `resource_embeddings`: `25039`
- `knowledge_graph_nodes`: `31564`
- `knowledge_graph_edges`: `38824`
- `knowledge_embeddings`: `31564`
- `condition_profiles`: `25`
- `condition_embeddings`: `25`

## Why Direct Restore Was The Wrong Move

Restoring the full dump over the current app database would have been the wrong approach because:

- it comes from an older branch with a broader acquisition-first schema
- it includes much more than the mobile app needs
- it would risk overwriting current app/demo state unnecessarily

So the current working rule is:

- use the dump as a donor corpus
- import selected retrieval tables only

## Current Local Import Status

The current local app database was backed up and then the selected retrieval tables were replaced with the Solomon corpus.

Current local post-import counts:

- `acquired_resources`: `7525`
- `resource_chunks`: `25039`
- `resource_embeddings`: `25039`
- `knowledge_graph_nodes`: `31564`
- `knowledge_embeddings`: `31564`
- `chat_answer_citations`: `0`

The backup created before replacement is:

- `/private/tmp/baha_current_retrieval_backup_20260714.dump`

## Critical Technical Constraint

The imported embeddings were generated with:

- `BAAI/bge-large-en-v1.5`

So a good Buddy demo requires the backend query encoder to use the same embedding family.

If the API still runs with:

- `EMBEDDING_BACKEND=hash`

then Buddy retrieval quality will still be weak or inconsistent, even though the database now contains a much larger corpus.

## Recommended Runtime Modes

### Default lightweight app/backend mode

Use:

```bash
docker compose up --build
```

This is still the right default when you are mainly working on:

- mobile API flows
- app screens
- auth/onboarding
- check-ins
- parent linking

### Buddy demo mode

Use:

```bash
docker compose -f docker-compose.yml -f docker-compose.buddy-demo.yml up --build
```

This switches the API build to `Dockerfile.full` and sets:

- `EMBEDDING_BACKEND=bge`
- `BUDDY_CHAT_MODE=grounded`

You still need a valid OpenAI API key in your environment or `.env`.

## Re-import Script

If you need to repeat the corpus load on another machine, use:

```bash
./scripts/import_solomon_rag_demo_corpus.sh
```

That script:

1. downloads the Solomon dump
2. backs up the current retrieval tables
3. truncates the current retrieval corpus tables
4. restores the selected Solomon retrieval tables
5. prints the resulting counts

## Brutally Honest Chatbot Assessment

The current Buddy architecture is directionally correct, but not yet fully polished.

What is good:

- OpenAI is backend-only, not on-device
- retrieval stays local to BAHA storage
- the answer format is bounded and structured
- emergency handling and scope-limiting are server-side
- the mobile UI contract stays stable

What is still weak:

- the imported corpus is noisy in places
- some chunk text clearly contains boilerplate or poor extraction
- audience/theme filtering is still too loose for a polished adolescent UX
- the current Buddy prompt is safe, but still fairly generic
- there is not yet a tight curated “demo gold set” sitting above the imported corpus

What should improve next if the demo needs to look stronger:

1. create a curated Buddy whitelist for the top demo themes only:
   - stress
   - sleep
   - friendships
   - digital wellbeing
   - school pressure
2. suppress obviously noisy sources and boilerplate chunks
3. add topic-first routing before retrieval so Buddy searches the right slice of the corpus first
4. test 15 to 25 demo questions manually and tune thresholds from real outputs
5. keep the OpenAI answerer grounded, but make the response style warmer and more age-appropriate
