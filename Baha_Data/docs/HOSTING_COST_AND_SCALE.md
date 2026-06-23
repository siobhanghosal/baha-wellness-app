# BAHA Hosting Cost And Scale Notes

## 1. Snapshot Date

This note reflects:

- local repository size measured on June 23, 2026
- cloud pricing and quota references checked on June 23, 2026

Pricing can change, so verify again before spending money.

## 2. Current Local Data Footprint

Measured in this workspace:

- full `Baha_Data/`: about `4.5 GB`
- `Baha_Data/storage/`: about `3.5 GB`
- `Baha_Data/storage/raw/`: about `3.5 GB`
- `Baha_Data/storage/reports/`: about `100 KB`
- files under `storage/raw/`: `8,671`

Implication:

- the raw corpus is already too large for most free storage tiers
- this raw corpus should live in object storage, not in PostgreSQL tables

## 3. What Fits On Free Tiers

### Supabase

Official billing docs currently list:

- Free plan database size: `500 MB` per project
- Free plan storage size: `1 GB`
- Free plan egress: `5 GB`
- Pro/Team database size included: `8 GB` disk per project
- Pro/Team storage size included: `100 GB`
- Pro/Team egress included: `250 GB`

Source:

- <https://supabase.com/docs/guides/platform/billing-on-supabase>

Official compute docs currently list:

- `Micro` compute: about `$10/month` per project
- `Small` compute: about `$15/month` per project

Source:

- <https://supabase.com/docs/guides/platform/compute-and-disk>

Conclusion:

- no, the current BAHA raw corpus will not fit comfortably on Supabase Free
- yes, it fits comfortably inside the included storage quota of a paid Supabase plan

### Cloudflare R2

Official Cloudflare R2 pricing currently lists:

- free tier storage: `10 GB-month / month`
- standard storage beyond free tier: `$0.015 / GB-month`
- egress directly from R2: free

Source:

- <https://developers.cloudflare.com/r2/pricing/>

Conclusion:

- yes, the current `3.5 GB` raw corpus would fit inside Cloudflare R2's current free storage tier

### Render

Official Render pricing currently lists:

- web service `Starter`: `$7/month`
- web service `Standard`: `$25/month`
- Postgres storage expansion: `$0.30/GB`
- persistent disks for services: `$0.25/GB/month`
- Hobby workspace bandwidth: `5 GB/month`, then `$0.15/GB`

Source:

- <https://render.com/pricing>

## 4. Best Storage Split For BAHA

Do this:

- PostgreSQL for structured product data, app state, consent, progress, and retrieval metadata
- object storage for raw source files and media

Do not do this:

- store the full 3.5 GB raw corpus inside Postgres tables

For the current BAHA stack, the cleanest near-term option is:

- Supabase Postgres for database
- Supabase Storage or another object store for raw files
- Render for the FastAPI backend

If cost minimization matters more than keeping everything in one vendor:

- Supabase Postgres for database
- Cloudflare R2 for raw corpus storage
- Render for the FastAPI backend

## 5. Practical Monthly Cost Range

### Lowest realistic pilot cost

If you keep one hosted API and one managed database for a real pilot:

- one small Render web service: about `$7/month`
- one paid Supabase organization: required because Free is too small for current storage and DB growth
- one Supabase `Micro` project: about `$10/month` compute

Important note:

- Supabase's docs confirm quotas and overage rates, but the exact fixed plan fee should be rechecked on the pricing page at provisioning time:
  <https://supabase.com/pricing>

Working estimate:

- expect the first real monthly bill to be meaningfully above `$17/month`, because that is before the fixed Supabase paid-plan fee
- as a practical engineering budget, assume roughly `tens of USD per month`, not zero

### More realistic early pilot

For a cleaner pilot with room for growth:

- Render web service on `Starter` or `Standard`
- Supabase paid plan
- Supabase `Micro` or `Small` compute depending on load

Working estimate:

- roughly `tens of USD per month` for the first external pilot
- still well under typical enterprise hosting costs

### If raw storage grows

If raw storage rises above included quota, Supabase docs currently list storage overage at:

- `$0.021/GB`

That means even an additional `20 GB` of raw files is not the main cost risk.
API compute and usage spikes are more likely to matter first.

## 6. What Will Bottleneck First

The first bottleneck is unlikely to be raw storage.

The more likely early bottlenecks are:

- backend API compute
- chat request volume
- retrieval latency
- poorly optimized query paths
- missing caching

In other words:

- storage is manageable
- application compute and request concurrency will determine user scale first
- if raw files are moved to R2, raw storage cost can stay near zero for a while

## 7. Rough Device Scale Guidance

This section is an engineering estimate, not a provider guarantee.

### On the currently recommended shape

With:

- one small Render API instance
- one paid Supabase project
- the current backend architecture

You should think in stages:

1. Internal testing:
   - `10-30` devices is trivial
2. Controlled pilot:
   - `100-300` devices is realistic if simultaneous usage is modest
3. Larger school pilot:
   - `500-1500` devices is possible with more backend tuning and at least one API size upgrade

Important nuance:

- installed devices are not the same as concurrent active users
- chat-heavy usage stresses the backend much more than passive content viewing
- the database quotas shown by Supabase are not the same thing as practical application throughput

## 8. Recommendation

Best current path:

- keep local Docker for development
- move the backend to hosted API plus managed Postgres before Flutter work gets deep
- keep raw files in object storage, not relational tables
- budget for a paid pilot stack from the start

For BAHA, zero-cost hosting is not the right assumption anymore.
