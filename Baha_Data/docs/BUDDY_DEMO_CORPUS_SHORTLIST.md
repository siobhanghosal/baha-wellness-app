# BAHA Buddy Demo Corpus Shortlist

## 1. Purpose

This document defines the small, intentional corpus subset that should be used first for `BAHA Buddy` retrieval testing.

This shortlist exists because the raw corpus is large, mixed in quality, and not yet uniformly prepared for student-facing retrieval. For the Buddy demo, retrieval quality matters more than corpus size.

The goal is:

- maximize answer reliability for common student questions
- keep the evidence set easy to inspect manually
- stay close to the student app themes already implemented
- avoid research-heavy or adult-only material in the first Buddy demo

## 2. Selection Rules

The shortlist was chosen using these rules:

- student-relevant first
- plain-language or education-oriented pages first
- authoritative organizations only
- direct overlap with student app themes
- enough thematic breadth for a demo, but not enough noise to dilute retrieval

The first shortlist intentionally favors:

- `Common Sense Education`
- `Internet Matters`
- `IAP Adolescent Health Academy`
- `NHS`

The shortlist intentionally avoids using the full `PubMed`, `Europe PMC`, or broad research dump for the first live Buddy demo.

## 3. Final Shortlist

The machine-readable version of this shortlist is:

- `storage/reports/buddy-demo-corpus-shortlist.json`

Final selected files:

| ID | Theme | Source | Title | Path |
| --- | --- | --- | --- | --- |
| `my_social_media_life_uk` | digital wellness | Common Sense Education | `My Social Media Life (UK) \| Common Sense Education` | `storage/raw/common-sense-media/25/255e73480be43179f4b0355558017fb4960dc769433fcc9fd57a06b6adf0988d.html` |
| `oversharing_digital_footprint` | digital wellness | Common Sense Education | `Teen Voices: Oversharing and Your Digital Footprint (Quick Activity) \| Common Sense Education` | `storage/raw/common-sense-media/25/256469e93c169a79085906ccdf3b2cf2cc9812e3d8b8275d70705d33159261dc.html` |
| `friendships_social_media` | friendships and social wellbeing | Common Sense Education | `Teen Voices: Friendships and Social Media (Quick Activity) \| Common Sense Education` | `storage/raw/common-sense-media/7f/7f60e33224b384f21f824d9064a62a62d24a798dfc5ac3390d31542cb2f21ce5.html` |
| `social_media_rules_middle_school` | digital wellness | Common Sense Media | `What Are Some Basic Social Media Rules for Middle Schoolers? \| Common Sense Media` | `storage/raw/common-sense-media/7f/7fc694222bc929620f24da41b5e86b2ebbfd6187f56f629a9a5d71fcff17fc9c.html` |
| `react_to_cyberbullying` | cyberbullying | Common Sense Education | `How to Re-A.C.T. to Cyberbullying \| Common Sense Education` | `storage/raw/common-sense-media/14/141c37322e06c083af9681725abe49adeb1d7f50a8b5f39922117865f2d3a973.html` |
| `screen_time_tips_11_14` | digital wellness | Internet Matters | `Screen time tips for 11-14 yrs - KS3 \| Resources - Internet Matters` | `storage/raw/internet-matters/8b/8b9027c60fa676735a3d7f4790d98844a1cfeafaaaf5e4ca78aff00bb8c7a213.html` |
| `teens_balance_screen_time` | digital wellness | Internet Matters | `How to help teens balance screen time \| Internet Matters` | `storage/raw/internet-matters/be/be2cd1a00d605e0956936ffeb985462f15278bcf82133a353de8d11f66ed6b7e.html` |
| `screen_time_balance_lesson` | digital wellness | Digital Matters / Internet Matters | `Screen Time Balance online safety lesson \| Digital Matters` | `storage/raw/internet-matters/c0/c0b085cb1bbe82f368f2d2b8c91d6aba578936bec4ef37d3c37b13c2e986f706.html` |
| `game_safe_guide` | online safety and gaming | Internet Matters | `Game safe guide to help young people game safely online` | `storage/raw/internet-matters/da/daa28d55449c284ccbace0f2bd6ec3ab34e7357a1ef48cef91e50dc64648c53b.html` |
| `live_streaming_vlogging_tips` | online safety and self-expression | Internet Matters | `10 tips for live streaming and vlogging \| Internet Matters` | `storage/raw/internet-matters/14/143a64e999d94ffe9ac9d2829733d0e6a37ce043a60d3bdb3ad74a0bc8e1a444.html` |
| `adolescent_handouts` | adolescent wellbeing | IAP Adolescent Health Academy | `Adolescent Health Academy - IAP \| Adolescent Handouts` | `storage/raw/iap-adolescent-health-academy/e0/e00f22974c26d14feb72a4a695691c8955e9810fbcbb296516dc8662b8fe1b47.html` |
| `knowledge_bank` | adolescent wellbeing | IAP Adolescent Health Academy | `Adolescent Health Academy - IAP \| Knowledge Bank` | `storage/raw/iap-adolescent-health-academy/15/15c7178b50ff0a8ecf5f256e36ce6dc792b51f229258eed5afc6f5aa24f4b877.html` |
| `anxiety_disorders_children` | anxiety and emotional wellbeing | NHS | `Anxiety disorders in children - NHS` | `storage/raw/nhs/1e/1e19abb6e068f1f7638851ca2bc5d7bc68583f24b92c52b7108e777bb4d96055.html` |
| `get_help_with_stress` | stress | NHS | `Get help with stress - NHS` | `storage/raw/nhs/8d/8d2e106e3b35f89fbdcb3ca9273aafad60ee3ad4ea88139598d43230e3f1dfb1.html` |
| `sleeping_problems` | sleep | NHS / CNTW | `Sleeping Problems :: Cumbria, Northumberland, Tyne and Wear NHS Foundation Trust` | `storage/raw/nhs/49/4960685d87f73b985b35a0ee30aa2033b730a87864d47283ef0268e8f970f354.html` |

## 4. Why This Is Better Than Using The Whole Corpus Immediately

If Buddy is pointed at the full raw corpus right now, these problems appear immediately:

- too many low-signal matches
- too many pages written for adults, clinicians, or institutions
- inconsistent chunk quality across raw HTML and research documents
- harder manual QA when the model gives a weak answer

This shortlist solves that by making the first retrieval environment:

- smaller
- more inspectable
- more student-oriented
- easier to tune theme by theme

## 5. Recommended Import Order

Import this shortlist in the same order the student app surfaces likely needs:

1. digital wellness and online relationships
2. cyberbullying and online safety
3. general adolescent wellbeing
4. anxiety and stress
5. sleep

That order keeps the first demo most aligned with the current student learning and Buddy flows.

## 6. Runtime Note

As of the current local repository setup:

- the default `docker compose` backend uses `EMBEDDING_BACKEND=hash`
- the lightweight API runtime is appropriate for a working end-to-end Buddy demo
- true `BGE` embedding activation still requires the full retrieval runtime

So the practical sequence is:

1. import this shortlist
2. activate embeddings in the current local runtime
3. validate retrieval behavior with the demo question bank
4. only then move to `Dockerfile.full` or a repaired host retrieval environment for true `BGE` embeddings

This keeps the demo path moving without pretending the full retrieval stack is already production-grade.
