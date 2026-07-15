# BAHA Buddy Generation Architecture

## 1. Purpose

This document defines how `BAHA Buddy` now works in the backend.

The goal is:

- keep the existing Flutter Buddy UI unchanged
- answer through a single OpenAI generation backend
- keep factual wellbeing advice grounded in the approved BAHA corpus
- avoid therapy, diagnosis, and unsupported advice
- still allow natural conversation for greetings, venting, and simple support

## 2. Model Choice

Current generation backend:

- `openai`

Current default model:

- `gpt-5-nano`

Why this is the current default:

- it keeps the mobile client thin and moves generation entirely to the backend
- it removes the operational overhead of shipping and supervising a local model runtime inside the demo stack
- it is intended as the lower-cost OpenAI path for this project’s grounded-chat use case

## 3. High-Level Runtime

Buddy generation now follows this flow:

1. student sends a message from the existing Buddy screen
2. backend first checks for emergency language
3. if emergency language is present:
   - backend returns the server-owned emergency response
   - backend creates safeguarding signal/case server-side
4. otherwise backend decides whether the message needs retrieval grounding
5. if the message is casual, emotional, or general conversation:
   - backend calls `OpenAI` in conversational mode with no retrieval evidence
6. if the message is an advice-style wellbeing question:
   - backend retrieves relevant approved evidence from the BAHA corpus
   - backend calls `OpenAI` in grounded mode with trimmed evidence
7. if retrieval is weak:
   - backend falls back to conversational OpenAI instead of a cold refusal
8. mobile can use the stream route so Buddy text appears progressively
9. backend synthesizes a short remembered session context from recent turns
10. backend stores the final assistant answer and any citations

## 4. Scope Guard

The most important design rule is:

- the model is not the source of truth
- retrieval is the source of truth

The OpenAI model is now used for all normal Buddy replies.

The scope rule is now:

- grounded factual advice should come only from retrieved BAHA evidence
- supportive conversation may still happen without retrieval
- emergency handling stays outside the model

That means the hard gate is softer than before:

- outside-scope or weak-retrieval messages no longer get a cold system refusal by default
- instead, Buddy can still respond naturally in conversational mode while avoiding factual claims beyond the corpus
- the model is still not allowed to diagnose or act like a therapist

## 5. Prompt Contract

Buddy now uses two prompt families:

- grounded prompt:
  - use only the supplied approved evidence for factual advice
  - avoid inventing facts or external resources
  - avoid diagnosis
  - stay concise and natural
- conversational prompt:
  - support greetings, venting, and general wellbeing talk naturally
  - gently redirect if the topic is unrelated to BAHA wellbeing support
  - avoid diagnosis and therapy framing

The model returns a draft with:

- `what_it_is`
- `how_to_identify_it`
- `what_to_do`
- `when_to_seek_help`
- `answerable_from_corpus`

The backend then wraps that into the existing `EvidenceAnswer` contract already used by the mobile API.

For the mobile streaming route, the backend also requests a plain text streamed reply from OpenAI so the Flutter UI can render deltas progressively while still persisting the final assistant message at the end.

Implementation note:

- with `gpt-5-nano`, Buddy now explicitly requests `reasoning.effort=minimal` for both structured and streamed reply generation
- this avoids the failure mode where the model spends the whole output budget on hidden reasoning tokens and returns an incomplete response with no visible assistant text
- Buddy also now injects a compact remembered-context block ahead of the visible chat history so the model can carry forward simple session facts such as work, school, friends, family, sleep trouble, stress, or overwhelm across one conversation

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
- `BUDDY_OPENAI_API_KEY`
- `BUDDY_OPENAI_BASE_URL`
- `BUDDY_OPENAI_MODEL`
- `BUDDY_OPENAI_TIMEOUT_SECONDS`
- `BUDDY_HISTORY_WINDOW`
- `BUDDY_MIN_RETRIEVAL_CONFIDENCE`

Relevant route surfaces:

- `POST /mobile/chat/sessions/{session_id}/messages`
- `POST /mobile/chat/sessions/{session_id}/messages/stream`

Example OpenAI configuration:

```bash
BUDDY_GENERATION_BACKEND=openai
BUDDY_OPENAI_API_KEY=...
BUDDY_OPENAI_BASE_URL=https://api.openai.com/v1
BUDDY_OPENAI_MODEL=gpt-5-nano
BUDDY_OPENAI_TIMEOUT_SECONDS=60
BUDDY_HISTORY_WINDOW=10
BUDDY_MIN_RETRIEVAL_CONFIDENCE=0.35
```

Model note:

- the repo default is `gpt-5-nano` because that is the model string currently requested for this project
- actual availability should still be verified in the OpenAI account used for the demo environment

## 8. Failure Behavior

If OpenAI is unavailable, misconfigured, or returns invalid output:

- Buddy should fail clearly at the API layer during development
- grounded generation may fall back to conversational OpenAI when the grounded draft is unusable
- there is no secondary non-OpenAI model path

## 9. Current Local Repo Status

As of July 15, 2026 local verification:

- the mobile Buddy endpoint is live
- retrieval remains local to BAHA's database
- final answer generation is OpenAI-backed for both conversational and grounded Buddy replies
- emergency handling remains server-side
- the Flutter transport layer now supports progressive Buddy message streaming
- Buddy now carries a lightweight rolling session memory into prompts for better within-session continuity
- if the running local backend has not been rebuilt yet, the new stream route will return `404` until the API container/process is restarted

To move from "safe grounded chatbot runtime" to "actually informed chatbot", the next backend data step is:

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
- that is acceptable for the current demo-oriented Buddy behavior
- true `BGE` retrieval validation still requires the full retrieval runtime from `Dockerfile.full` or a repaired host Python retrieval environment

So the practical near-term activation sequence is:

1. import the curated Buddy demo shortlist only
2. activate embeddings in the current local runtime
3. validate answers against the Buddy demo question bank
4. move to full `BGE` activation only after the shortlist itself behaves cleanly

Current local verification result:

- the curated shortlist can now be imported and indexed in the lightweight runtime
- Buddy now feels better for demo use because conversation is no longer split between visibly different local and model-generated tones
- the main remaining quality gap is still deeper retrieval quality for less common or more complex grounded questions

So the next real quality step after the demo is still:

- run the same shortlist in a full retrieval runtime with true `BGE` embeddings
