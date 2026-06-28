# BAHA Student Learning Content Strategy

## 1. Purpose

This document defines how the existing BAHA corpus should be turned into
student-facing learning material that is usable inside the Flutter app.

The goal is not to expose raw PDFs or scraped pages directly in the mobile app.
The goal is to transform the corpus into:

- focused learning lanes
- short guided modules
- quick guides
- checklists
- reflection prompts
- scenario and choice content

All of that should stay evidence-linked, age-appropriate, and easy to review.

## 2. Current Reality

The repo currently has two very different content layers:

- a large raw source corpus in `Baha_Data/storage/raw/`
- a much smaller curated product-content layer in PostgreSQL

From the current inventory and reports:

- raw storage is about `3.5 GB`
- accepted public resources are about `8,026`
- the raw corpus is source-organized and hash-bucketed, which is good for
  retention and reprocessing
- the live mobile backend is only serving the curated product-content layer, not
  the full raw corpus

That distinction is correct and should remain.

The app should never try to function by reading raw corpus files directly.

## 3. What The Corpus Is Strong At

The current corpus is already strong enough to support richer student learning
in some areas:

- `digital wellness`
  - especially from Common Sense Media and Internet Matters
- `communication skills`
- `decision making`
- `emotional intelligence`
- `problem solving`
- broader SEL and school-support content

These are the best themes to lean on for deeper and more confident course
experiences early.

## 4. What The Corpus Is Still Weak At

The inventory and campaign reports still flag important gaps for student-facing
themes:

- `peer pressure`
- `exam stress`
- `friendship issues`
- `self awareness`
- `performance anxiety`
- `sleep`

That does not mean these app themes should be removed. It means they should be
treated more carefully:

- start with curated and reviewed manual content
- keep the learning slices shorter
- expand them later as direct source coverage improves

## 5. Recommended Product Structure

The best structure for student learning is:

1. `Theme`
2. `Learning lane`
3. `Module`
4. `Section`
5. `Step or content atom`
6. `Evidence citations`

In practical BAHA terms:

- `Theme`
  - Sleep
  - Digital Wellness
  - Peer Pressure
  - Exam Stress
- `Learning lane`
  - the filtered in-app experience for one theme
- `Module`
  - a guided 5 to 10 minute learning experience
- `Section`
  - one small sub-goal within that module
- `Step or content atom`
  - a paragraph, checklist, reflection prompt, quick card, or scenario

This is a better fit than a flat list of articles because mobile learning needs
clear entry points and short completion loops.

## 6. Recommended Content Atom Types

The current schema already supports the right direction. The main atom types to
keep using are:

- `learning_module`
- `learning_card`
- `checklist`
- `reflection_prompt`

The best student experience will mix them like this:

- 1 guided module as the main lane anchor
- 1 to 3 quick cards for immediate wins
- 1 checklist for action
- 1 reflection prompt for internal processing

That produces a more engaging learning pattern than long-form text alone.

## 7. Recommended Presentation Pattern In The App

For each student theme, the app should present:

- a focused theme entry
- one main module
- one quick reset card
- one checklist
- one reflection or scenario

This matches good mobile learning practice better than dumping many articles
into one feed.

The learning experience should feel like:

- start here
- do one small thing
- reflect
- save progress
- come back later

Not:

- open long text
- scroll
- leave

## 8. Recommended Preprocessing Workflow

The raw corpus should be processed into app material through a publishing
workflow, not a direct retrieval workflow.

### 8.1 Evidence preparation

- keep the raw files unchanged
- normalize extracted text
- extract metadata:
  - source
  - audience
  - topic
  - subtopic
  - age hints
  - keywords
- retain provenance and quality metadata

### 8.2 Curation buckets

Group evidence into product buckets:

- strong-source themes
- gap themes
- student-safe quick wins
- parent/teacher/counselor supporting material

### 8.3 Microlearning packaging

Convert curated evidence into app-ready atoms:

- one concept per block
- one clear action per checklist
- one reflection per prompt
- one behavior change target per module

### 8.4 Review and publish

- clinical or editorial review
- publish to `content_items` and `content_versions`
- activate through `content_publish_targets`
- map into `learning_modules`, `learning_module_sections`, and
  `learning_module_steps`

## 9. Where A Knowledge Graph Fits

A knowledge graph is still useful, but not as the mobile serving layer.

It is best used for:

- mapping source evidence to themes
- linking student themes to parent/teacher/counselor support content
- tracking relationships between topic, subtopic, module, and citations
- future recommendations and explainability

It should not replace the curated product-content layer.

## 10. Current Student Theme Strategy

| Theme | Current corpus posture | Recommended product approach |
| --- | --- | --- |
| Sleep | Useful but still underdeveloped | foundational module + checklist |
| Digital Wellness | Strongest coverage area | deeper lane with more cards and variations |
| Peer Pressure | Direct evidence coverage still thin | short reviewed manual starter + later expansion |
| Exam Stress | Gap area | short reviewed manual starter + later expansion |

## 11. Changes Implemented In This Repo

This repo now moves closer to the right structure:

- student Learn cards can be routed into theme-specific learning lanes instead
  of one generic feed
- the mobile API now supports filtering published content by:
  - `theme`
  - `topic`
  - `subtopic`
- the student modules endpoint now supports theme filtering
- student module summaries now expose structure-aware progress fields:
  - `current_section_ordinal`
  - `current_step_ordinal`
  - `total_sections`
  - `total_steps`
- new curated student seed content now exists for:
  - Peer Pressure
  - Exam Stress
- richer text rendering is now tuned for reading comfort on device

## 12. What Should Happen Next

The next content-focused steps should be:

1. expand `Digital Wellness` into the deepest student lane first
2. expand `Sleep` next
3. keep `Peer Pressure` and `Exam Stress` as concise reviewed starter lanes
4. later add:
   - section read endpoints
   - richer scenario content
   - citation surfaces for counselor/admin review
   - stronger age-band adaptation

## 13. External Pattern References

These recommendations are aligned with a few useful external references:

- Microsoft Learn on advanced RAG, especially metadata-rich chunking,
  hierarchical retrieval, and alignment layers:
  <https://learn.microsoft.com/en-us/azure/developer/ai/advanced-retrieval-augmented-generation>
- Microsoft Azure architecture guidance on retrieval pipelines, metadata, and
  versioning:
  <https://learn.microsoft.com/en-us/azure/architecture/ai-ml/guide/rag/rag-information-retrieval>
- research on adaptive microlearning and guided pathing:
  <https://arxiv.org/abs/2205.06337>
- research on integrating microlearning into broader learning systems:
  <https://arxiv.org/abs/2312.06500>
- research on interactive multimedia exercises as a stronger engagement model
  than passive content alone:
  <https://arxiv.org/abs/1507.01318>

The BAHA product should use those patterns selectively and stay simpler than a
full adaptive-learning platform.
