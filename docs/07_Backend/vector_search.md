# Vector Search and Grounded Chatbot Retrieval

## Objective

Support BAHA Buddy with citations and reviewable answers while preventing open-ended clinical generation.

## Content Units

- Safe Questions Q&A pairs
- BAHA learning modules
- approved supportive scripts
- escalation policy copy

## Retrieval Pipeline

1. user prompt classified by topic and safety sensitivity
2. allowed corpus subset selected by role, age band, and review status
3. lexical and vector retrieval runs
4. ranked passages converted into cited answer candidates
5. safety layer blocks non-approved or expired content
6. response assembler returns answer, citation, and help-seeking affordance

## Guardrails

- expired review date excludes content
- sensitive topics must return citation
- unsupported topics return safe refusal plus route to library or human help
