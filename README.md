# Video Game Market Entry Analysis

> End-to-end SQL project analysing global video game sales data (2006–2016) to identify the optimal genre, publisher strategy, and platform for a new market entrant. Covers data ingestion, normalisation, cleaning, exploration, and multi-angle market analysis.

---

## Project Overview

This project takes a flat CSV of video game sales rankings and transforms it into a normalised relational database, then uses that database to answer a single business question:

**Where is the best opportunity to enter the video game market as a new publisher?**

The analysis is structured across three dimensions — genre dynamics, publisher competition, and market opportunities (regional and platform) — each building toward a final recommendation.

The findings from this analysis are visualised in a set of [Tableau dashboards](https://github.com/sjk100/video_game_sales_viz) — recommended as an entry point before reading the SQL.

---

## Repository Structure

```
├── 01_structure/
│   ├── schema.sql              # Normalised table definitions
│   ├── staging.sql             # Flat staging tables for raw ingestion
│   ├── load.sql                # COPY commands to load CSV into staging
│   └── transform.sql           # ETL: staging → normalised tables
│
├── 02_queries/
│   ├── analysis_queries/
│   │   ├── genre_analysis.sql          # Genre wealth distribution and market trends
│   │   ├── publisher_analysis.sql      # Publisher dominance and new entrant performance
│   │   └── market_opportunities.sql    # Regional skew, correlations, and platform selection
│   ├── clean_queries.sql       # Data cleaning applied to staging table
│   └── explore_queries.sql     # Exploratory queries run pre-cleaning
│
├── 03_results_csv/
│   ├── export_results.sql      # Run after analysis to generate CSVs
│   └── *.csv                   # Query outputs, one file per analysis
│
├── .gitignore
├── entity_relationship_diagram.png
├── FINDINGS.md                 # Full analysis findings and recommendation
├── README.md
└── vgsales.csv                 # Source data (Kaggle: Video Game Sales)
```

---

## Data Pipeline

The pipeline follows a linear flow: ingest → stage → clean → transform → analyse.

```
vgsales.csv
    │
    ▼
[ staging_games ]  ← raw_staging_games (untouched backup)
    │
    ├── explore_queries.sql   (understand shape, nulls, duplicates)
    ├── clean_queries.sql     (fix issues found in exploration)
    │
    ▼
[ Normalised Tables ]
    publishers / platforms / games / game_releases / sales
    │
    ▼
[ Analysis Views ]
    game_sales_view / market_share_view / active_platform_view / new_entrant_performance_view
    │
    ▼
[ Analysis Queries ]
    genre_analysis.sql / publisher_analysis.sql / market_opportunities.sql
```

### `01_structure/schema.sql`
Defines the normalised schema across five tables. The flat CSV has one row per game-platform combination with all attributes inlined; the schema separates concerns into reusable dimension tables.

| Table | Purpose |
|---|---|
| `publishers` | Unique publisher identities |
| `platforms` | Unique platform identities |
| `games` | Unique game titles with genre and publisher FK |
| `game_releases` | One row per game-platform-year combination |
| `sales` | Regional and global sales figures keyed to a release |

See [entity_relationship_diagram.png](./entity_relationship_diagram.png) for the full schema diagram.

### `01_structure/staging.sql`
Creates two flat tables that mirror the CSV structure exactly:
- `staging_games` — the working staging table, modified during cleaning
- `raw_staging_games` — an untouched backup of the original load, preserved for reference and re-runs

### `01_structure/load.sql`
Uses PostgreSQL's `\copy` command to load the CSV into both staging tables. The CSV uses `N/A` for missing values, so the `NULL 'N/A'` option is specified explicitly to avoid type errors on the integer `year` column.

### `01_structure/transform.sql`
Wrapped in a single transaction, inserts from the cleaned `staging_games` into the five normalised tables in dependency order: publishers → platforms → games → game_releases → sales. Uses `DISTINCT ON` to handle any residual duplicates safely.

---

## Data Exploration & Cleaning

### `02_queries/explore_queries.sql`
Run against `staging_games` before any cleaning. Key findings that drove cleaning decisions:

- **16,598 total rows** across 31 platforms, 12 genres, and 578 publishers
- **271 null years (1.63%)** and **58 null publishers (0.35%)** — the only columns with missing values
- **5 duplicate game-platform combinations** requiring individual investigation
- **10 global vs. regional sales mismatches** — all within a 0.02 rounding tolerance, no action needed
- **Platform `2600`** had 12.78% null years — investigated by publisher; resolved by filling Atari titles manually
- **Publisher `unknown`** had a 47.69% null year rate — left null and excluded from time-series analysis
- Entries for `2017–2020` were too sparse (≤3 per year) to be analytically useful — analysis scoped to 2006–2016
- Levenshtein distance check identified `Milestone S.r.l` vs `Milestone S.r.l.` as the same publisher

### `02_queries/clean_queries.sql`
Applied sequentially to `staging_games`. Actions taken:

| Issue | Resolution |
|---|---|
| Mixed case and whitespace | `TRIM(LOWER(...))` applied to all text columns |
| Null publishers | Standardised to `'unknown'` |
| *Need for Speed: Most Wanted* — same name on same platform but different years (two distinct games) | Name amended to include release year to satisfy unique constraint |
| *Wii de Asobu: Metroid Prime* exact duplicate row | Second row deleted |
| *Madden NFL 13* PS3 — duplicate with suspicious partial data | Likely erroneous row removed |
| *Sonic the Hedgehog* PS3 — sales split across two rows | Regional sales merged into one row; second row deleted |
| `Milestone S.r.l` publisher variant | Standardised to `Milestone S.r.l.` |
| Null years for large publishers (Atari, Warner Bros.) | Manually researched and backfilled |
| Null years for small publishers with >5% null rate | Manually researched and filled where verifiable |
| GBA video entries from unknown publisher | Deleted as not relevant to game sales analysis |

---

## Analysis

All analysis queries operate on `game_sales_view`, a flat view joining all five normalised tables to simplify downstream queries. Analysis is scoped to **2006–2016** to capture the modern console era with sufficient data density.

---

### `genre_analysis.sql` — Genre Wealth Distribution & Market Trends

**Question:** Which genres offer fair wealth distribution, and which are dominated by a few blockbusters?

**Key techniques:**

| Technique | Why |
|---|---|
| Herfindahl-Hirschman Index (HHI) | Measures title-level concentration within a genre — higher = fewer titles capture most revenue |
| Top-10 share | Fraction of genre revenue held by the top 10 titles |
| Min-max normalised HHI | Scales HHI 0–1 across genres so they can be combined in a composite score |
| Variance-weighted attractiveness score | Weights median sales by how evenly revenue is distributed; weights are derived from the data's own variance rather than set arbitrarily |
| `market_share_view` | Expresses genre sales as % of total market per year, removing the effect of overall market growth to allow valid cross-year comparison |
| Z-score analysis | Compares each genre's annual market share against its own historical average — z=0 is a normal year, z>1 is above average |
| OLS trend slope | Manual linear regression on market share over time — positive slope means a growing share of the market |

**Key findings:**
- **Shooter** has the highest attractiveness score: strong median sales and moderate concentration
- **Platform** has high median sales but severe HHI — a few titles dominate, poor entry conditions
- **Action** is volume-heavy but wealth is most evenly distributed — viable with a differentiated title
- **Role-playing** offers moderate sales and low concentration — relatively safe entry conditions
- **Adventure** should be avoided: weakest sales despite moderate HHI
- Only **shooter, action, and role-playing** have positive market share trend slopes over 2006–2016 (slopes of ~1.6, ~1.8, and ~0.4 respectively)

---

### `publisher_analysis.sql` — Publisher Dominance & New Entrant Performance

**Question:** Are genres controlled by major publishers, and how do first-time publishers historically perform?

**Key techniques:**

| Technique | Why |
|---|---|
| Publisher HHI | Same concentration measure applied at publisher level rather than title level |
| Top-5 publisher share | What fraction of a genre's total revenue the five largest publishers hold |
| Successful publisher strategy query | Examines genre breadth and average sales of the top 20 publishers to infer strategic patterns |
| Regex-based sequel detection | Flags titles that are likely sequels or series continuations to keep the new entrant dataset interpretable |
| Genre-year median baseline | Uses median rather than mean to avoid blockbuster distortion when benchmarking new entrants |
| `vs_median_ratio` | Each new entrant's sales ÷ their genre-year median — a normalised performance score independent of era |
| Entry performance bands | Categorises entrants as `strong breakout` / `above median` / `below median` / `weak entry` for easy aggregation |

**Key findings:**
- **Action, adventure, and strategy** are the least publisher-dominated genres (top-5 share < 50%)
- **Platform, sports, and shooter** are the most dominated (top-5 share > 75%)
- The most successful publishers span **6+ genres** — breadth appears to enable risk-taking and a diverse release slate
- **50.78%** of new entrants record a weak first title; only **28.52%** beat their genre median
- **Shooter** has an 11.11% breakout rate for new entrants — unforgiving despite strong market metrics
- **Puzzle** has a 50% breakout rate — genuinely open to new titles despite modest overall sales
- **Strategy, simulation, racing, and platform** should be avoided for a first entry

---

### `market_opportunities.sql` — Regional Analysis & Platform Selection

**Question:** Are there regional niches worth targeting, and which platform should be the primary release target?

**Key techniques:**

| Technique | Why |
|---|---|
| Regional skew | (Region's genre share) − (Global genre share) — positive value means the region over-indexes on that genre relative to the global average |
| Pearson correlation matrix | Quantifies how independently each region behaves; low correlation = distinct market worth treating separately |
| `active_platform_view` | Filters to platforms that still received releases in 2016, removing legacy hardware from the comparison |
| Sales-per-release | Total platform sales ÷ release count — measures how much revenue each new title can reasonably expect |
| Platform HHI | Whether one or two titles dominate a platform's total sales |
| Release share over time | Each platform's share of annual releases — reveals where in the lifecycle a platform sits |
| Genre × platform average sales | Identifies which genres perform best on each current platform; filtered to `n > 20` for statistical reliability |

**Key findings:**
- **Japan is an independent market**: JP–NA correlation 0.45, JP–EU 0.44 — far below the 0.63–0.77 range seen between other regions
- **Role-playing** is over-indexed in Japan by **+16.82%** — a meaningful niche for a JP-targeted title
- NA and EU track the global market closely (0.94 and 0.90) — a globally successful title will naturally perform well there
- **PS4** is the recommended primary platform: highest sales-per-release among current-generation hardware and lower HHI than Xbox One
- PS4 captured **31.1%** of all releases in 2016 with the highest revenue efficiency — clear platform leadership
- **Shooter, sports, and action** are the three top-performing genres on both PS4 and Xbox One, joint platform release recommended if focusing on these genres
- **Role-playing** is a top-3 genre on 3DS, PC, and PSV — relevant for a Japan-led or PC-first strategy

---

## Synthesis & Recommendation

| Signal | Shooter | Action | Role-Playing |
|---|---|---|---|
| Attractiveness score | ✅✅ Highest | ✅ High | ✅ Moderate |
| Market share trend | ✅ Positive | ✅ Positive | ✅ Positive |
| New entrant breakout rate | ❌ 11.11% (Low) | ✅ 38.71% (High) | ✴️ 18.18% (Moderate) |
| Publisher concentration | ❌ High (>75%) | ✅ Low (<50%) | ✴️ 67% |
| Regional niche | — | — | ✅ Japan +16.82% |
| Top genre on PS4 & XONE | ✅ Yes | ✅ Yes | — |

**Two viable paths emerge:**

**Option A — Action on PS4 & XONE (global strategy)**
Growing market share, lowest publisher concentration of the three shortlisted genres, and a moderate new entrant success rate. The genre's high game count means differentiation is essential — a generic action title is unlikely to succeed, but a distinctive one has a more level playing field than shooter.

**Option B — Role-playing on PC & 3DS (Japan-led strategy)**
More forgiving competitive conditions and a significant regional tailwind in Japan. Lower total revenue ceiling than action but a more clearly defined audience. A successful Japanese launch could serve as a beachhead for broader expansion, with PC & 3DS as a primary platforms given role-playing's strong performance. Expand to PS4 later if successful enough to capture global interest.

**Avoid:** Shooter (punishing for new entrants despite strong headline metrics), Platform, Strategy, Simulation, Racing, and Adventure.

---

## Methodology Notes

- **Scope:** 2006–2016. Pre-2006 data is sparse and reflects a different hardware generation; post-2016 entries are too few to be reliable.
- **HHI throughout:** Values near 0 indicate a fragmented market; near 1 indicates monopolistic conditions. Applied consistently at both title level (genre analysis) and publisher level (publisher analysis).
- **Median over mean:** Used as the performance baseline wherever blockbuster distortion is a concern, particularly for new entrant benchmarking.
- **Attractiveness score weights:** Derived from the standard deviation of each component across genres rather than set manually — the data determines how much HHI vs. top-10 share matters.
- **Sequel detection:** Regex-based and acknowledged as imperfect. Results are flagged rather than removed; the performance distribution shifts by less than 1% either way.
- **Active platform filter:** Defined as any platform with at least one release recorded in 2016, excluding platforms that were still technically on sale but no longer receiving meaningful new titles.

---

## Data Source

1. Download the dataset from Kaggle:
   [Video Game Sales — Kaggle](https://www.kaggle.com/datasets/gregorut/videogamesales)
2. Place `vgsales.csv` inside the root folder

Data is from user Gregory Smith, scraped from VGChartz. ~16,500 games with regional and global sales figures by platform, genre, and publisher.

I do not own this dataset. It is used for educational and non-commercial purposes only.

If you intend to use this data, please refer to the original source.

---

## Setup & Reproduction

**Prerequisites:** PostgreSQL 13+, psql command-line client

```bash
# 1. Create a database
createdb vgsales

# 2. Run the pipeline in order
psql -d vgsales -f 01_structure/staging.sql
psql -d vgsales -f 01_structure/schema.sql
psql -d vgsales -f 01_structure/load.sql
psql -d vgsales -f 02_queries/clean_queries.sql
psql -d vgsales -f 01_structure/transform.sql

# 3. Run analysis
psql -d vgsales -f 02_queries/analysis_queries/genre_analysis.sql
psql -d vgsales -f 02_queries/analysis_queries/publisher_analysis.sql
psql -d vgsales -f 02_queries/analysis_queries/market_opportunities.sql
```

> **Note:** Update the file path in `load.sql` to match your local path to `vgsales.csv` before running.

`explore_queries.sql` is informational — it documents the investigation that shaped the cleaning decisions and does not need to be re-run to reproduce the analysis.

---

## Limitations

**Data source methodology**
This project uses the VGChartz dataset sourced from Kaggle. VGChartz produces software sales estimates based on retail sampling  — figures are not sourced directly from publishers or platform holders and should be treated as approximations rather than audited sales data.
VGChartz has itself noted that growing digital market share made retail estimates increasingly difficult to produce and increasingly unrepresentative of true game performance, which is why the site stopped producing software estimates after 2018.
Regional figures are extrapolated from a subset of tracked markets (e.g. Europe is estimated from UK, France, Germany, Spain, Italy, Benelux, and the Nordic countries) and may not fully represent smaller markets within each region.

**Physical sales only**
The dataset captures physical retail sales only. Digital sales — which grew substantially across the 2006–2016 window, particularly on PC — are not reflected.
This means PC performance is likely understated relative to console, and genres with a stronger digital presence (such as strategy and simulation) may appear weaker than they actually were.
Conclusions about platform and genre attractiveness should be read with this in mind.

**Temporal scope**
Analysis is scoped to 2006–2016. Post-2016 entries in the dataset number fewer than five per year and were excluded as statistically unreliable.
The recommendations reflect the market as it stood at the end of 2016 — market dynamics, platform lifecycles, and genre trends will have shifted in the years since, particularly with the release of the Nintendo Switch and the continued growth of digital distribution.

**Sequel detection**
The regex-based sequel flagging in `publisher_analysis.sql` is pattern-matched and will produce both false positives (flagging originals with numeric suffixes in their title) and false negatives (missing sequels with distinct names).
It is used for flagging and transparency rather than exclusion — the new entrant performance distribution shifts by less than 1% whether suspected sequels are included or removed.

**Year null values**
Approximately 1.63% of entries had no release year recorded. Null years for identifiable titles were manually backfilled through external research.
The remainder were excluded from time-series analysis but retained for sales aggregations where year was not required.
