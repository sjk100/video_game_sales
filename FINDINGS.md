# Findings: Video Game Market Entry Analysis
> Analysis scoped to 2006–2016. All sales figures in millions of units. See [README.md](./README.md) for methodology and [README.md#limitations](./README.md#limitations) for data caveats. These findings are visualised in a set of [Tableau dashboards](https://github.com/sjk100/video_game_sales_viz).

---

## 1. Genre Wealth Distribution

The attractiveness score combines median sales with market concentration (HHI) and top-10 title dominance to identify genres where a new entrant has a realistic chance of capturing meaningful revenue.

| Genre | Verdict |
|---|---|
| Shooter | Highest attractiveness score — strong median sales and moderate HHI |
| Action | Heavily saturated by volume but the most evenly distributed wealth of any genre — viable with a genuinely differentiated title |
| Role-playing | Moderate sales and low HHI — relatively safe entry conditions |
| Platform | High median sales but worst HHI in the dataset — market dominated by a handful of titles, poor entry conditions |
| Adventure | Lowest sales despite moderate HHI — avoid |

**Key takeaway:** Shooter leads on raw attractiveness but that score does not account for how hostile the market is to new entrants — that emerges in Section 3. Action and role-playing hold up better once publisher dominance and breakout rates are factored in.

---

## 2. Genre Market Share Trends (2006–2016)

### Trend direction
Only three genres have a positive market share trend slope over the decade:

| Genre | Trend Slope |
|---|---|
| Action | +1.8 |
| Shooter | +1.6 |
| Role-playing | +0.4 |

All other genres are either flat or declining in market share. A positive slope means the genre is capturing a growing proportion of total market revenue each year, independent of whether the overall market is growing or shrinking.

### Stability
- **Action and shooter** have both moved from negative z-scores in 2006 to consistently positive z-scores by 2016, indicating sustained and compounding growth rather than a single spike
- **Fighting** is a volatile genre — z-scores alternate between positive and negative year on year, making performance unpredictable
- **Role-playing** has improved its relative performance over the period but dipped in 2016, which warrants caution

> *Z-score interpretation: z=0 is a normal year for that genre, z>1 is above its historical average, z>2 is exceptional, z<-1 is a weak year. Scores are relative to the 2006–2016 window.*

---

## 3. Publisher Dominance by Genre

Are genres controlled by a few large publishers or open to new entrants?

| Concentration Level | Genres |
|---|---|
| Low — top 5 publishers hold <50% of genre sales | Action, Adventure, Strategy |
| High — top 5 publishers hold >75% of genre sales | Platform, Sports, Shooter |

Shooter's high publisher concentration is the first serious warning sign against it despite its strong attractiveness score. Action's low concentration is one of its strongest arguments in favour.

### What successful publishers have in common
The top 20 publishers by average sales per title almost all span **6 or more genres**. A broad portfolio appears to enable risk-taking and keeps a publisher's catalogue fresh for its existing playerbase. This is less actionable for a first entry but relevant context for long-term strategy.

---

## 4. New Entrant Performance

How do publishers perform on their first title, benchmarked against the genre-year median at the time of release?

### Overall
- **50.78%** of new entrants record a weak first title (below 50% of genre-year median)
- Only **28.52%** of first titles outperform their genre median

Entering the market is genuinely difficult. The majority of new publishers do not reach the typical sales level for their genre on their debut.

### By genre — breakout rate
The breakout rate is the percentage of new entrants in a genre who either matched or exceeded their genre-year median:

| Breakout Rate | Genres |
|---|---|
| High (≥33.34%) | Puzzle (50%), Action, Adventure |
| Moderate (16.67–33.33%) | Role-playing, Fighting, Sports, Misc |
| Low (≤16.66%) | Shooter (11.11%) |
| Avoid | Strategy, Simulation, Racing, Platform |

**Shooter's 11.11% breakout rate is the decisive signal against it.** Despite leading on attractiveness score and trend slope, fewer than 1 in 9 new entrants in the genre manage to match the typical sales level. The market rewards established franchises and punishes newcomers.

**Puzzle** has a 50% breakout rate — the highest of any genre — indicating genuine openness to new titles. However its low overall sales volume means a successful puzzle title generates limited absolute revenue.

### Top performing new entrants
The five highest-performing non-sequel debut titles show no single repeatable pattern, but each had a clear differentiating factor:

| Title | Differentiator |
|---|---|
| No Man's Sky | Revolutionary procedural technology and large-scale marketing |
| Project Cars | Crowdfunded — significant community involvement before launch |
| Winter Sports: The Ultimate Challenge | Timed to Wii motion control craze and the Olympic cycle |

Two of the top eight — *Ben 10: Alien Force* and *The Walking Dead: Season One* — launched on established external IP rather than original concepts, which gave them a built-in audience before release.

---

## 5. Regional Market Analysis

### Japan as an independent market
Japan does not follow global sales patterns and should be treated as a separate market rather than a subset of a global strategy.

| Correlation Pair | Value |
|---|---|
| JP – NA | 0.45 |
| JP – EU | 0.44 |
| JP – Other | 0.29 |
| JP – Global | 0.61 |
| NA – EU (for comparison) | ~0.77 |
| NA – Global | 0.94 |
| EU – Global | 0.90 |

NA and EU track the global market so closely that a title performing well globally will almost certainly perform well in both regions. Japan requires a separate consideration.

### Regional genre skew
Genre share within each region compared to global genre share — a positive skew means that region over-indexes on that genre relative to the global average.

**Role-playing has the largest positive skew in Japan at +16.82%.** This is the strongest regional niche signal in the data and directly supports a Japan-targeted role-playing strategy.

---

## 6. Platform Selection

### Current generation comparison (as of 2016)
Active platforms are defined as those still receiving new releases in 2016.

| Platform | Sales per Release (million usd) | HHI (ranked) | 2016 Release Share |
|---|---|---|---|
| PS4 | 0.83 | 3 | 31.1% |
| XOne | 0.66 | 4 | 15.7% |
| PSV | 0.15 | 1 | 17.4% |
| PC | 0.21 | 2 | 11.0% |
| 3DS | 0.49 | 5 | 10.2% |

**PS4 is the recommended primary platform.** It leads on sales-per-release efficiency, has the largest share of new releases in 2016, and has lower concentration than Xbox One meaning revenue is more evenly spread across titles. PS4 and Xbox One share the same top three genres (shooter, sports, action) so a PS4-targeted title will benefit from a largely shared audience.

Platforms showing end-of-cycle decline: PS3 (9.3% release share), Wii U (2.9%), Xbox 360 (2.3%).

### Genre performance by platform

| Platform | Top Genres |
|---|---|
| PS4 / XOne | Shooter, Sports, Action |
| 3DS | Platform, Simulation, Role-playing |
| PC | Role-playing, Simulation, Misc |
| PSV | Sports, Misc, Role-playing |

Role-playing's strong performance on 3DS, PC, and PSV is relevant for a Japan-first strategy where those platforms have stronger market positions.

---

## 7. Recommendation

### Summary matrix

| Signal | Shooter | Action | Role-playing |
|---|---|---|---|
| Attractiveness score | ✅ Highest | ✅ High | ✅ Moderate |
| Market share trend slope | ✅ +1.6 | ✅ +1.8 | ✅ +0.4 |
| Publisher concentration | ❌ >75% | ✅ <50% | ✴️ 67% |
| New entrant breakout rate | ❌ 11.11% (Low) | ✅ 38.71% (High) | ✴️ 18.18% (Moderate) |
| Japan regional niche | ❌ | ❌ | ✅ +16.82% |
| Top genre on PS4 & XONE | ✅ | ✅ | ❌ |

### Option A — Action on PS4 & XONE
Growing market share, lowest publisher concentration of the three shortlisted genres, and a moderate new entrant success rate. The genre's high game count means differentiation is essential — a generic action title is unlikely to succeed, but a distinctive one has a more level playing field than shooter.

### Option B — Role-playing on PC & 3DS, Japan-led
More forgiving competitive conditions and a significant regional tailwind in Japan. Lower total revenue ceiling than action but a more clearly defined audience. A successful Japanese launch could serve as a beachhead for broader expansion, with PC & 3DS as a primary platforms given role-playing's strong performance. Expand to PS4 later if successful enough to capture global interest.

### Avoid
Shooter (punishing for new entrants despite strong headline metrics), Platform, Strategy, Simulation, Racing, and Adventure.
