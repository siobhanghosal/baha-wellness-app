# BAHA Wellness Companion Data Collection Inventory

**Snapshot date:** June 13, 2026  
**Scope:** Approved public adolescent health, wellbeing, education, digital
wellbeing, school support, and research sources  
**Corpus status:** Download campaign complete at the current bounded crawl
depth; embeddings deferred

## 1. Corpus Summary

| Measure | Count |
|---|---:a|
| Total acquired records | 8,869 |
| Accepted resources | 8,026 |
| Rejected resources | 843 |
| Accepted PDFs | 1,533 |
| Accepted research-paper resources | 1,066 |
| Research repository records | 1,432 |
| Raw files retained | 8,670 |
| Total storage used | 3.5 GB |
| Condition profiles | 28 |
| Knowledge graph nodes | 124,959 |
| Knowledge graph edges | 620,009 |
| Failed acquisition candidates | 621 |
| Blocked NIOS candidates retained for later | 2,217 |

All accepted and rejected files, source URLs, source organizations, hashes,
metadata, quality decisions, and extraction results remain stored. No corpus
files were deleted during this campaign.

The 2,217 discovered candidates are all from the National Institute of Open
Schooling. They were not downloaded because the public site presented an
invalid TLS certificate chain. Certificate verification was not disabled.

## 2. Embedding Status

No embeddings were created or updated during this campaign.

| Measure | Count |
|---|---:|
| Resource vectors retained from earlier work | 3,626 |
| Condition vectors retained from earlier work | 2 |
| Knowledge-node vectors retained from earlier work | 10 |
| Configured model | `BAAI/bge-large-en-v1.5` |
| Automatic embedding | Disabled |
| Campaign embedding status | Deferred |

The existing partial vectors were left unchanged. Future embedding can resume
incrementally without rebuilding already indexed content.

## 3. Collected Sources

### 3.1 Complete Source Totals

| Organization | Accepted | Rejected | PDFs |
|---|---:|---:|---:|
| Attendance Works | 1,096 | 181 | 279 |
| CASEL | 923 | 194 | 112 |
| Europe PMC | 701 | 29 | 4 |
| Internet Matters | 680 | 40 | 114 |
| Common Sense Media | 673 | 1 | 140 |
| PubMed | 646 | 2 | 0 |
| American School Counselor Association | 557 | 343 | 118 |
| American Academy of Pediatrics | 545 | 0 | 0 |
| NIMHANS | 422 | 0 | 419 |
| CDC | 338 | 1 | 23 |
| National Association of School Psychologists | 313 | 14 | 31 |
| NIMH | 249 | 0 | 15 |
| NICE | 228 | 0 | 31 |
| WHO | 210 | 0 | 101 |
| NHS | 179 | 0 | 0 |
| National Center for School Mental Health | 126 | 0 | 89 |
| IAP Adolescent Health Academy | 63 | 0 | 33 |
| UNICEF | 42 | 0 | 0 |
| Semantic Scholar | 22 | 32 | 16 |
| NCERT | 8 | 0 | 8 |
| UNESCO | 4 | 1 | 0 |
| NCPCR | 1 | 0 | 0 |
| National Institute of Open Schooling | 0 | 5 | 0 |
| **Total** | **8,026** | **843** | **1,533** |

### 3.2 India Priority Sources

#### IAP Adolescent Health Academy

- 63 accepted resources
- 33 PDFs, 16 HTML pages, and 14 PowerPoint files
- Includes AHA publications, consensus guidance, Awesome AYA, Mission
  Kishore Uday, T-Teach, parent handouts, adolescent handouts, school
  resources, life skills, sleep, screen-time, learning, and substance material
- Official source: <https://aha.iapindia.org/>

#### NIMHANS

- 422 accepted resources
- 419 PDFs and 3 documents
- Includes mental-health manuals, training resources, school mental-health
  material, parent and teacher education, guidelines, reports, toolkits,
  research publications, substance-use material, and suicide-prevention
  resources
- Official source: <https://www.nimhans.ac.in/>

#### NCERT

- 8 accepted public PDFs
- Includes guidance and counseling resources
- Official source: <https://ncert.nic.in/>

#### NCPCR

- 1 accepted public HTML resource
- Several linked school-safety and bullying resources were unavailable at
  their source URLs
- Official source: <https://ncpcr.gov.in/>

#### National Institute of Open Schooling

- 2,217 candidates discovered and retained
- 5 downloaded responses rejected during quality validation
- Remaining downloads blocked by invalid public TLS certificate verification
- No certificate or transport-security bypass was attempted
- Official source: <https://www.nios.ac.in/>

### 3.3 Life Skills and Digital Wellbeing Sources

#### Attendance Works

- 1,096 accepted resources
- 279 PDFs
- Strong coverage for attendance, chronic absenteeism, school avoidance,
  student engagement, parent support, and teacher support
- Audience distribution includes 686 teacher and 285 parent resources
- Official source: <https://www.attendanceworks.org/>

#### CASEL

- 923 accepted resources
- 112 PDFs
- Covers SEL frameworks, self-awareness, self-management, social awareness,
  relationship skills, responsible decision making, classroom SEL, family
  SEL, teacher practices, implementation guidance, and research
- Audience distribution includes 451 teacher and 375 parent resources
- Official source: <https://casel.org/>

#### Common Sense Media and Common Sense Education

- 673 accepted resources
- 140 PDFs
- Covers digital citizenship, digital wellness, screen time, online safety,
  social media, cyberbullying, gaming, parent guides, teacher curriculum, and
  student resources
- Audience distribution includes 401 teacher and 232 parent resources
- Official sources: <https://www.commonsensemedia.org/> and
  <https://www.commonsense.org/education/>

#### Internet Matters

- 680 accepted resources
- 114 PDFs
- Covers parental controls, online safety, digital wellbeing, screen time,
  social media, cyberbullying, gaming, and family guidance
- Includes 617 parent resources
- Official source: <https://www.internetmatters.org/>

#### National Center for School Mental Health

- 126 accepted resources
- 89 PDFs
- Covers comprehensive school mental-health systems, referral pathways,
  school supports, implementation frameworks, and educator resources
- Official source: <https://www.schoolmentalhealth.org/>

#### American School Counselor Association

- 557 accepted resources
- 118 PDFs
- Covers school counseling frameworks, student support plans, counselor
  practice, school mental health, referrals, and professional resources
- Includes 539 counselor-classified resources
- Official source: <https://www.schoolcounselor.org/>

#### National Association of School Psychologists

- 313 accepted resources
- 31 PDFs
- Covers bullying, behavior management, crisis response, school psychology,
  intervention frameworks, parent guidance, and educator support
- Includes 288 counselor-classified resources
- Official source: <https://www.nasponline.org/>

### 3.4 Global Public and Clinical Sources

#### WHO

- 210 accepted resources: 101 PDFs and 109 HTML pages
- Covers adolescent mental health, school health, mhGAP, Mental Health Atlas,
  suicide prevention, substance use, nutrition, and physical activity
- Official source: <https://www.who.int/>

#### UNICEF

- 42 accepted HTML resources
- Covers adolescent development, parenting, MHPSS, education, nutrition, and
  social wellbeing
- Official source: <https://www.unicef.org/>

#### UNESCO

- 4 accepted public resources
- Additional entry points were limited by source access and connection
  behavior
- Official source: <https://www.unesco.org/>

#### CDC

- 338 accepted resources: 23 PDFs and 315 HTML pages
- Covers youth mental health, ADHD, school health, bullying, physical
  activity, nutrition, substance awareness, and digital media
- Official source: <https://www.cdc.gov/>

#### NIMH

- 249 accepted resources: 15 PDFs and 234 HTML pages
- Covers child and adolescent mental health, anxiety, depression, ADHD,
  autism, suicide prevention, and public education
- Official source: <https://www.nimh.nih.gov/>

#### NICE

- 228 accepted resources: 31 PDFs and 197 HTML pages
- Covers evidence-based guidance for depression, anxiety, ADHD, autism,
  self-harm, referrals, and support
- Official source: <https://www.nice.org.uk/>

#### NHS

- 179 accepted public HTML resources
- Covers anxiety, depression, sleep, self-harm, parent information,
  help-seeking, and referral guidance
- Official source: <https://www.nhs.uk/>

#### American Academy of Pediatrics

- 545 accepted public resources
- Covers mental health, sleep, ADHD, autism, life skills, substance use,
  nutrition, physical activity, and digital wellness
- 150 protected, forbidden, or missing pages were not bypassed
- Official sources: <https://www.aap.org/> and
  <https://www.healthychildren.org/>

### 3.5 Research Repositories

| Repository | Repository Records | Accepted Research Resources |
|---|---:|---:|
| Europe PMC | 730 | 417 |
| PubMed | 648 | 646 |
| Semantic Scholar | 54 | 3 |
| **Total** | **1,432** | **1,066** |

Stored research metadata includes title, authors, abstract, journal,
publication year/date, DOI, keywords, canonical URL, open-access status,
license when available, source query, and retraction status when supplied.
Full text is downloaded only when it is legally and publicly available.

## 4. Collected Resource Categories

| Resource Type | Accepted |
|---|---:|
| HTML | 5,292 |
| PDF | 1,533 |
| Research paper | 1,066 |
| Dataset | 51 |
| Document | 50 |
| PowerPoint | 22 |
| ZIP archive | 12 |

Downloaded categories include:

- Clinical and public-health guidelines
- Government and organizational reports
- School mental-health frameworks
- SEL frameworks and implementation guides
- Teacher manuals and classroom resources
- Parent guides and family resources
- Counselor frameworks and referral material
- Adolescent-facing guidance
- Digital citizenship and online-safety curricula
- Bullying and cyberbullying resources
- Attendance and student-engagement resources
- Toolkits, white papers, research reports, datasets, and archives

## 5. Collected Audience Categories

| Primary Audience | Accepted |
|---|---:|
| Parent | 2,991 |
| Teacher | 1,730 |
| Adolescent | 1,676 |
| Counselor | 845 |
| General | 717 |
| Clinical | 45 |
| Research | 22 |

Audience classification assigns one primary audience automatically. Clinical
review should confirm multi-audience and high-risk resources before production
retrieval.

## 6. Topic Coverage

| Topic | Documents | PDFs | Research | Target | Gap |
|---|---:|---:|---:|---:|---:|
| ADHD | 152 | 28 | 19 | 100 | 0 |
| Aggression | 32 | 11 | 13 | 75 | 43 |
| Alcohol abuse | 4 | 1 | 0 | 75 | 71 |
| Anger | 38 | 11 | 0 | 75 | 37 |
| Anxiety | 161 | 32 | 50 | 200 | 39 |
| Autism | 246 | 17 | 112 | 100 | 0 |
| Bullying | 116 | 16 | 73 | 200 | 84 |
| Burnout | 26 | 4 | 0 | 75 | 49 |
| Communication skills | 76 | 51 | 0 | 50 | 0 |
| Cyberbullying | 137 | 24 | 66 | 150 | 13 |
| Decision making | 188 | 74 | 0 | 50 | 0 |
| Depression | 241 | 29 | 112 | 200 | 0 |
| Digital wellness | 1,158 | 119 | 66 | 200 | 0 |
| Emotional intelligence | 80 | 24 | 0 | 50 | 0 |
| Emotional regulation | 39 | 8 | 17 | 75 | 36 |
| Exam stress | 10 | 2 | 7 | 75 | 65 |
| Friendship issues | 10 | 2 | 5 | 75 | 65 |
| Gaming addiction | 7 | 0 | 6 | 75 | 68 |
| Grief | 157 | 11 | 4 | 75 | 0 |
| Internet addiction | 18 | 4 | 13 | 75 | 57 |
| Learning difficulties | 28 | 10 | 4 | 75 | 47 |
| Loneliness | 12 | 3 | 5 | 75 | 63 |
| Nutrition | 194 | 12 | 16 | 150 | 0 |
| Peer pressure | 8 | 3 | 1 | 75 | 67 |
| Performance anxiety | 2 | 1 | 1 | 75 | 73 |
| Physical activity | 940 | 48 | 189 | 150 | 0 |
| Problem solving | 53 | 17 | 0 | 50 | 0 |
| Resilience | 53 | 15 | 0 | 50 | 0 |
| Risk taking | 7 | 3 | 2 | 75 | 68 |
| School avoidance | 533 | 187 | 3 | 75 | 0 |
| School refusal | 0 | 0 | 0 | 75 | 75 |
| Screen time | 80 | 44 | 0 | 75 | 0 |
| Self awareness | 14 | 3 | 0 | 50 | 36 |
| Self harm | 102 | 5 | 59 | 100 | 0 |
| Sleep | 159 | 7 | 66 | 200 | 41 |
| Social isolation | 25 | 9 | 11 | 75 | 50 |
| Stress | 196 | 35 | 77 | 200 | 4 |
| Substance abuse | 279 | 55 | 46 | 100 | 0 |
| Suicide prevention | 594 | 37 | 53 | 100 | 0 |
| Vaping | 22 | 0 | 7 | 75 | 53 |

### 6.1 Life Skills Campaign Targets Met

- Communication skills: 76 / 50
- Decision making: 188 / 50
- Digital wellness: 1,158 / 200
- Emotional intelligence: 80 / 50
- Problem solving: 53 / 50
- Resilience: 53 / 50
- School avoidance: 533 / 75
- Screen time: 80 / 75
- Cyberbullying: 137 / 150, within 10% of target

### 6.2 Life Skills Campaign Gaps Above 10%

| Topic | Current | Target | Gap |
|---|---:|---:|---:|
| Bullying | 116 | 200 | 84 |
| School refusal | 0 | 75 | 75 |
| Performance anxiety | 2 | 75 | 73 |
| Risk taking | 7 | 75 | 68 |
| Peer pressure | 8 | 75 | 67 |
| Self awareness | 14 | 50 | 36 |

## 7. Clinical Knowledge

All 28 condition profiles remain in draft clinical-review status:

- ADHD
- Anger
- Anxiety
- Autism
- Bullying
- Burnout
- Cyberbullying
- Depression
- Emotional Regulation
- Exam Stress
- Gaming Addiction
- Grief
- Internet Addiction
- Learning Difficulties
- Loneliness
- Peer Pressure
- Performance Anxiety
- Physical Inactivity
- Risk Taking
- School Avoidance
- School Refusal
- Self Harm
- Sleep Disorders
- Social Isolation
- Stress
- Substance Abuse
- Suicide Prevention
- Suicide Risk

These profiles are evidence-linked but are not diagnostic or treatment
guidance. They require clinical approval before production use.

## 8. Knowledge Graph

### 8.1 Nodes

| Node Type | Count |
|---|---:|
| Intervention | 40,257 |
| Teacher Sign | 14,441 |
| Parent Sign | 13,115 |
| Symptom | 12,173 |
| Skill Intervention | 9,279 |
| Escalation Indicator | 9,079 |
| Risk Factor | 8,897 |
| Parent Support | 8,015 |
| Teacher Support | 5,121 |
| School Support | 4,539 |
| Condition | 28 |
| Skill | 15 |
| **Total** | **124,959** |

### 8.2 Edges

| Relationship | Count |
|---|---:|
| `HAS_INTERVENTION` | 209,353 |
| `HAS_TEACHER_SIGN` | 80,600 |
| `HAS_PARENT_SIGN` | 74,392 |
| `HAS_SYMPTOM` | 57,516 |
| `HAS_ESCALATION_INDICATOR` | 50,072 |
| `HAS_RISK_FACTOR` | 42,931 |
| `HAS_PARENT_SUPPORT` | 34,963 |
| `HAS_SKILL_INTERVENTION` | 31,724 |
| `HAS_TEACHER_SUPPORT` | 23,630 |
| `HAS_SCHOOL_SUPPORT` | 14,828 |
| **Total** | **620,009** |

## 9. Blocked and Failed Sources

Failures remain stored with exact URLs and error reasons.

| Organization | Failed Candidates | Status |
|---|---:|---|
| National Institute of Open Schooling | 202 | Invalid TLS certificate; 2,217 more retained as discovered |
| American Academy of Pediatrics | 150 | Protected, forbidden, or missing pages |
| Education Endowment Foundation | 92 | Download endpoints returned HTTP 403 |
| WHO | 42 | Missing, expired, or failed public links |
| Europe PMC | 31 | Full-text or source failures |
| UNICEF | 28 | Missing, timed-out, or unavailable pages |
| NIMHANS | 27 | Missing or unavailable public files |
| UNESCO | 21 | Access or connection failures |
| CASEL | 17 | Missing, invalid, or failed public links |
| CDC | 5 | Unsupported or failed resources |
| Semantic Scholar | 4 | Public full-text failures |
| American School Counselor Association | 1 | Failed public link |
| IAP Adolescent Health Academy | 1 | Failed public link |
| **Total** | **621** | |

Additional organizations attempted but not acquired:

- eSafety Commissioner: public site and `robots.txt` timed out after bounded
  retries
- OECD: public entry points returned HTTP 403
- World Economic Forum: public entry points and `robots.txt` returned HTTP 403
- SCERT Karnataka: configured public hostname did not resolve
- Education Endowment Foundation: discovery succeeded, but all 92 download
  endpoints returned HTTP 403

No authentication, login, paywall, access-control, robots, TLS, or session
bypass was attempted.

## 10. Sources Still To Be Collected

### 10.1 India

#### Bangalore Adolescent Health Academy

No resources are currently stored under a standalone BAHA organization.
Collect approved public or manually supplied:

- BAHA manuals and publications
- Parent, teacher, counselor, and adolescent resources
- Workshop presentations and handouts
- Clinical review material cleared for ingestion

#### Indian Academy of Pediatrics

The AHA corpus is collected, but standalone IAP coverage remains limited:

- IAP consensus statements
- Pediatric and adolescent mental-health guidance
- Parent and school-health guidance
- Nutrition, physical activity, substance-use, and digital-media resources

#### CBSE

- Counseling and wellness resources
- Exam-stress resources
- School safety and bullying guidance
- Parent and teacher guides

#### Ministry of Health and Family Welfare

- Adolescent-health policy and programme documents
- National mental-health and suicide-prevention material
- Substance-use prevention resources
- National statistics and datasets

#### National Mental Health Programme

- Programme guidelines
- School and adolescent mental-health manuals
- Referral and escalation guidance
- State and national programme reports

#### SCERT Karnataka

- Life-skills curriculum
- School wellbeing and counselor resources
- Teacher training material
- Kannada and English adolescent resources

### 10.2 Global

#### NIH

NIMH was collected separately. Still required:

- NIH adolescent-health evidence reports
- Cross-institute child and adolescent resources
- Public datasets

#### SAMHSA

- Youth mental-health toolkits
- School mental-health resources
- Substance-use and suicide-prevention guides
- Parent and teacher prevention resources

#### UNESCO

- Digital wellbeing
- School violence and bullying
- SEL and life-skills resources
- Teacher resources
- Education and attendance datasets

#### eSafety Commissioner

- Online safety
- Cyberbullying
- Digital wellbeing
- Parent, teacher, and adolescent guidance

Retry only when the official public site and `robots.txt` are reachable.

#### OECD and World Economic Forum

Use official APIs, feeds, or manually approved public document URLs if the
current 403 entry points remain unavailable.

## 11. Categories Still To Be Collected

Highest-priority topic gaps:

- Bullying
- School refusal
- Performance anxiety
- Peer pressure
- Risk-taking behavior
- Self-awareness
- Alcohol abuse
- Gaming addiction
- Exam stress
- Friendship issues
- Loneliness
- Internet addiction
- Vaping
- Social isolation
- Learning difficulties
- Burnout
- Aggression
- Sleep
- Anxiety
- Emotional regulation

Highest-priority resource gaps:

- India-specific parent guides
- India-specific teacher intervention manuals
- Counselor assessment, escalation, and referral guides
- Adolescent-facing handouts and infographics
- School-refusal-specific guidance
- Multilingual Indian-language resources
- Structured adolescent-health datasets
- Legally public video transcripts
- Current licenses for reusable curriculum and datasets

## 12. Quality and Clinical Review Remaining

- Clinically review all 28 condition profiles.
- Review high-risk self-harm and suicide-prevention statements.
- Validate automated audience and topic classifications.
- Confirm licenses for public full text, curriculum, and datasets.
- Resolve duplicate and superseded-version clusters.
- Review rejected files and preserve rejection reasons.
- Recheck failed URLs only during periodic update campaigns.
- Separate school avoidance from school refusal more precisely.
- Improve topic assignment for performance anxiety, peer pressure,
  self-awareness, and risk-taking resources.

## 13. Collection Rules

All future acquisition must:

- Use only approved organizations and research repositories.
- Respect `robots.txt` and source rate limits.
- Prefer official APIs and publication feeds.
- Collect only publicly accessible resources.
- Never scrape authenticated, member-only, or password-protected content.
- Never bypass access controls or TLS verification.
- Never collect personal data.
- Preserve source organization, canonical URL, title, publication date,
  license, content hash, topic, audience, and version history.
- Download full research text only when legally and publicly available.
- Route clinical and high-risk content through human review.

## 14. Generated Reports

- `storage/reports/life-skills-campaign-report.json`
- `storage/reports/life-skills-coverage-report.json`
- `storage/reports/life-skills-gap-closure-report.json`

These reports show source totals, audience coverage, topic targets, remaining
gaps, skill-support graph counts, and `embedding_status: deferred`.
