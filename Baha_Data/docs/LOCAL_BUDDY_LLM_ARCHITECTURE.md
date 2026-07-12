# BAHA Buddy Local LLM Architecture

## 1. Purpose

This document defines how `BAHA Buddy` now works in the backend.

The goal is:

- keep the existing Flutter Buddy UI unchanged
- answer through a local model runtime
- stay strictly grounded in the approved BAHA corpus
- avoid therapy, diagnosis, and unsupported advice

## 2. Model Choice

Current default:

- runtime: `Ollama`
- model: `qwen3:4b`

Why this is the current default:

- it is light enough for local development on modest Apple Silicon hardware
- it is materially stronger than tiny 1B to 2B class models for instruction following
- it is still much easier to run locally than 8B and above

As of the official Qwen3 release on April 29, 2025, Qwen lists `Qwen3-4B` as an Apache 2.0 open-weight dense model with `32K` context and explicitly recommends local use through tools such as `Ollama`.

Sources:

- <https://qwenlm.github.io/blog/qwen3/>
- <https://docs.ollama.com/api/chat>

## 3. High-Level Runtime

Buddy generation now follows this flow:

1. student sends a message from the existing Buddy screen
2. backend persists the user message in `chat_messages`
3. backend retrieves relevant approved evidence from the BAHA corpus
4. backend decides whether retrieval is strong enough to answer safely
5. if retrieval is strong enough:
   - backend sends a constrained prompt plus retrieved evidence to local `Ollama`
   - model returns structured JSON only
6. if retrieval is weak or missing:
   - backend does **not** let the model guess
   - backend returns an explicit scope-limited response
7. backend stores the assistant answer and any citations
8. emergency language still creates safeguarding signal/case server-side

## 4. Scope Guard

The most important design rule is:

- the model is not the source of truth
- retrieval is the source of truth

The local model is used only to rewrite retrieved evidence into a friendlier answer shape.

The backend blocks unsupported answering in three ways:

- if retrieval returns no evidence, Buddy responds that the question is outside the approved material
- if top retrieval confidence is below the configured threshold, Buddy responds that it cannot answer from the current corpus
- if the model itself says the evidence is insufficient, backend converts that into the same bounded out-of-scope answer

This is intentionally stricter than a general chatbot.

## 5. Prompt Contract

The Buddy prompt tells the model to:

- use only the evidence snippets included in the request
- avoid inventing facts or external resources
- avoid diagnosis
- avoid therapy framing
- avoid medication/legal advice
- return only JSON matching the required schema

The model returns a draft with:

- `what_it_is`
- `how_to_identify_it`
- `what_to_do`
- `when_to_seek_help`
- `answerable_from_corpus`

The backend then wraps that into the existing `EvidenceAnswer` contract already used by the mobile API.

## 6. Why This Is Safer Than A Free-Form Local Chatbot

This design is safer because:

- it does not let the model answer without evidence
- it preserves retrieval citations
- it keeps emergency escalation outside the model
- it does not turn the model into a diagnostic or therapeutic actor

Product framing should remain:

- supportive wellbeing guide
- retrieval-grounded educational helper

Not:

- therapist
- diagnosis engine
- crisis counselor replacement

## 7. Current Config

Relevant environment variables:

- `BUDDY_GENERATION_BACKEND`
- `BUDDY_OLLAMA_BASE_URL`
- `BUDDY_OLLAMA_MODEL`
- `BUDDY_OLLAMA_TIMEOUT_SECONDS`
- `BUDDY_OLLAMA_KEEP_ALIVE`
- `BUDDY_OLLAMA_THINK`
- `BUDDY_HISTORY_WINDOW`
- `BUDDY_MIN_RETRIEVAL_CONFIDENCE`

Current intended local values:

```bash
BUDDY_GENERATION_BACKEND=ollama
BUDDY_OLLAMA_BASE_URL=http://localhost:11434
BUDDY_OLLAMA_MODEL=qwen3:4b
BUDDY_OLLAMA_TIMEOUT_SECONDS=60
BUDDY_OLLAMA_KEEP_ALIVE=10m
BUDDY_OLLAMA_THINK=false
BUDDY_HISTORY_WINDOW=6
BUDDY_MIN_RETRIEVAL_CONFIDENCE=0.45
```

Runtime note:

- host-native backend process: use `http://localhost:11434`
- Dockerized backend process: use `http://host.docker.internal:11434`
- this repository's `docker-compose.yml` now injects the Docker-safe value so the API container can reach a host-installed `Ollama`

## 8. Fallback Behavior

If `Ollama` is unavailable or returns invalid output:

- the backend falls back to the existing deterministic evidence composer
- the chat still works
- the stored assistant payload records that fallback occurred

This means:

- the app does not break if the local model is down
- but the real local-LLM experience only exists when `Ollama` is installed, running, and has `qwen3:4b` pulled

## 9. Current Local Repo Status

As of July 5, 2026 local verification:

- `Ollama` is installed locally
- `qwen3:4b` is pulled locally
- the Dockerized backend is configured to reach host `Ollama`
- the mobile Buddy endpoint is live

Current remaining data gap:

- the retrieval index tables are still empty in the local database:
  - `acquired_resources = 0`
  - `resource_chunks = 0`
  - `knowledge_embeddings = 0`

So right now Buddy behaves correctly but conservatively:

- it returns the bounded out-of-scope response
- it does **not** yet give evidence-backed wellbeing guidance from the larger corpus

To move from "safe local chatbot runtime" to "actually informed chatbot", the next backend data step is:

1. import or map approved BAHA corpus material into the retrieval-backed acquisition/knowledge tables
2. run embedding activation so `resource_chunks`, `resource_embeddings`, `condition_embeddings`, and `knowledge_embeddings` are populated
3. retest Buddy with in-scope wellbeing prompts

## 10. First Demo Retrieval Strategy

The correct next move is **not** to index the entire raw corpus immediately.

The first demo retrieval pass should use a small curated subset:

- see [BUDDY_DEMO_CORPUS_SHORTLIST.md](./BUDDY_DEMO_CORPUS_SHORTLIST.md)
- see [BUDDY_DEMO_QUESTION_BANK.md](./BUDDY_DEMO_QUESTION_BANK.md)

Why this is the right order:

- retrieval quality is easier to inspect
- the selected documents are closer to student-language app themes
- failures become debuggable theme by theme instead of corpus-wide

Current practical runtime note:

- default local `docker compose` still uses `EMBEDDING_BACKEND=hash`
- that is acceptable for an end-to-end Buddy demo activation pass
- true `BGE` retrieval validation still requires the full retrieval runtime from `Dockerfile.full` or a repaired host Python retrieval environment

So the practical near-term activation sequence is:

1. import the curated Buddy demo shortlist only
2. activate embeddings in the current local runtime
3. validate answers against the Buddy demo question bank
4. move to full `BGE` activation only after the shortlist itself behaves cleanly

Current local verification result:

- the curated shortlist can now be imported and indexed in the lightweight runtime
- but hash-backed retrieval ranking is still too weak for a high-quality Buddy demo
- the local smoke test still scope-guarded the sample student prompts because top confidences remained below the Buddy threshold or ranked the wrong chunk first

So the data pipeline work is now unblocked, but the next real quality step is still:

- run the same shortlist in a full retrieval runtime with true `BGE` embeddings
