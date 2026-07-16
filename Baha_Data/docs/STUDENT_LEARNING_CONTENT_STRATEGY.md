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

For the concrete `9-12` lesson-packaging blueprint based on the current sample
content, see:

- [AGE_9_12_CONTENT_DELIVERY_BLUEPRINT.md](./AGE_9_12_CONTENT_DELIVERY_BLUEPRINT.md)

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

## 3. Current Product Theme Set

The active student learning model in the unified app now uses the same five
topics across cohorts:

- `Sleep`
- `Stress`
- `Bullying`
- `Healthy Gaming`
- `Alcohol Safety`

That five-topic set is now the source of truth for product-facing student
learning.

The larger raw corpus is still useful in adjacent areas such as digital
wellness, communication, emotional intelligence, and decision making, but those
ideas should now be absorbed into the five active topics instead of surfacing
as separate theme labels in the app.

## 4. What That Means For Content Packaging

The practical consequence is:

- `Healthy Gaming`
  becomes the place where digital-balance and screen-habit material lives
- `Stress`
  absorbs school pressure, performance strain, and self-management material
- `Bullying`
  becomes the main home for friendship harm, exclusion, and social safety
- `Sleep`
  remains a foundational regulation lane
- `Alcohol Safety`
  stays a governed safety-and-boundaries lane

Where the raw corpus is thin for a topic, we should keep using reviewed,
product-written starter content and expand the lane over time.

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
  - Stress
  - Bullying
  - Healthy Gaming
  - Alcohol Safety
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

For `9-12` specifically, this should be implemented as:

- one topic hub
- one learning lane per topic
- `3 to 5` micro-modules
- one practice interaction
- topic-level completion and a soft reward

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

| Theme | Current product posture | Recommended product approach |
| --- | --- | --- |
| Sleep | Foundational regulation lane | deeper multi-module lane + routines + reflection |
| Stress | Broadest daily-life relevance | strongest narrative lane across age bands |
| Bullying | High safeguarding relevance | clear boundaries, help-seeking, and bystander content |
| Healthy Gaming | Strong evidence-adjacent coverage | practical balance tools and routines |
| Alcohol Safety | Safety-critical starter lane | concise, reviewed, age-sensitive scenario guidance |

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
- richer text rendering is now tuned for reading comfort on device
- the first `9_12` learning-lane implementation now exists in the repo:
  - Sleep
  - Stress
  - Bullying
  - Healthy Gaming
  - Alcohol Safety
- the same five-topic structure is now also seeded for:
  - `13_14`
  - `15_18`
  - `18_plus`
- those lanes currently include:
  - three backend-published modules per topic
  - one backend-published quick support item per topic
  - child-facing lane titles
  - topic-level progress presentation in the Flutter UI
  - a small saved-practice interaction in the Flutter UI

Important current limitation:

- this first `9_12` implementation now reaches the lower bound of the intended
  lane depth, but it is still not the final polished curriculum
- the biggest remaining need is richer variation within modules:
  - more scenario content
  - more age-tuned interactivity
  - less dependence on repeated explanation patterns across topics

## 12. What Should Happen Next

The next content-focused steps should be:

1. deepen `Sleep` and `Stress` first because they connect most clearly to daily check-in trends
2. expand `Bullying`, `Healthy Gaming`, and `Alcohol Safety` with more scenario variation
3. later add:
   - section read endpoints
   - richer scenario content
   - citation surfaces for counselor/admin review
   - stronger age-band adaptation
4. package the new `9-12` content sample into guided topic lanes rather than
   long lessons
5. roll module progress up into topic completion so the student sees real
   momentum
6. add gentle topic-completion rewards instead of heavy gamification

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
