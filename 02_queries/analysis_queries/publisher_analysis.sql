--publisher dominance + new entrant performance

--Are genres dominated by giants or fragmented indie space?
\set genre_start 2006
\set genre_end 2016

WITH publisher_sales AS (
    SELECT
        "genre",
        "publisher_name", 
        SUM("global_sales") AS "total_sales"
    FROM "game_sales_view"
    WHERE "year" BETWEEN :genre_start AND :genre_end
    GROUP BY "genre", "publisher_name" 
),
shares AS (
    SELECT
        "genre",
        "publisher_name",
        "total_sales",
        "total_sales" / SUM("total_sales") OVER (PARTITION BY "genre") AS "sales_share",
        ROW_NUMBER() OVER (PARTITION BY "genre" ORDER BY "total_sales" DESC) AS "rank_in_genre"
    FROM "publisher_sales"
),
genre_stats AS (
    SELECT
        "genre",
        SUM("total_sales") FILTER (WHERE "rank_in_genre" <= 5) AS "top5_publisher_sales",
        SUM("sales_share") FILTER (WHERE "rank_in_genre" <= 5) AS "top5_publisher_share",
        SUM(POWER("sales_share", 2)) AS "hhi"
    FROM "shares"
    GROUP BY "genre"
)
SELECT
    "genre",
    ROUND("top5_publisher_sales", 2) AS "top5_publisher_sales",
    ROUND("top5_publisher_share" * 100, 2) AS "top5_publisher_share_percent",
    ROUND("hhi", 4) AS "pub_hhi" -- measures distribution of sales over publishers, low hhi less dominance
FROM "genre_stats"
ORDER BY "hhi" ASC;
--action, adventure, strategy are the least dominated genres, only ones with top5_publisher_share_percent < 50%
--platform, sports, shooters are the most dominated genres, top5_publisher_share_percent > 75%


-- What strategy do successful publishers employ?
WITH recent_publishers AS (
    SELECT DISTINCT "publisher_name"
    FROM game_sales_view
    WHERE "year" BETWEEN 2006 AND 2016
)
SELECT
    g."publisher_name",
    COUNT(DISTINCT g."genre") AS genre_count,
    COUNT(*) AS game_count,
    ROUND(SUM(g."global_sales"), 2) AS total_global_sales,
    ROUND(AVG(g."global_sales"), 2) AS avg_global_sales
FROM game_sales_view g
INNER JOIN recent_publishers rp ON rp."publisher_name" = g."publisher_name"
GROUP BY g."publisher_name"
HAVING COUNT(*) > 5
ORDER BY "avg_global_sales" DESC
LIMIT 20;
--Most successful publishers have a diverse portfolio, high avg_sales ->  genre_count >6
--Maybe as they have money to build diverse portfolio, keep creating fresh games for playerbase and able to take risks?


--view showing new entrant performance titles post 2006 so can gain relevant info
CREATE VIEW new_entrant_performance_view AS
WITH sum_pub AS (
    SELECT
        "publisher_name",
        "game_name",
        "year",
        "genre",
        SUM("global_sales") AS "global_sales"
    FROM game_sales_view
    GROUP BY "publisher_name", "game_name", "year", "genre"
),
pub_games AS (
    SELECT
        "publisher_name",
        "game_name",
        "year",
        "genre",
        "global_sales",
        --Flag sequels and series pickups to keep data usable
        CASE WHEN
            "game_name" ~ '\s[2-9]$'-- ends in single digit
            OR "game_name" ~ '\s1[0-9]$'-- ends in double digit
            OR "game_name" ~* '\s(ii|iii|iv|v|vi|vii|viii|ix|x)(\s|$)'-- roman numerals
            OR "game_name" ~* '(part|episode|chapter|season|vol\.?)\s'-- series indicators
            OR "game_name" ~* '(returns|revenge|reloaded|resurrection|reborn|remastered)'-- continuations
        THEN TRUE ELSE FALSE END AS "suspected_sequel"
    FROM sum_pub
),
ranked_pub_games AS (
    SELECT 
        "publisher_name",
        "game_name",
        "year",
        "genre",
        "global_sales",
        "suspected_sequel",
        ROW_NUMBER() OVER (
            PARTITION BY "publisher_name"
            ORDER BY "year" ASC, "global_sales" DESC) AS time_rank
    FROM pub_games
),
genre_medians AS ( --use median so outliers dont skew results
    SELECT
        "genre",
        "year",
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY "global_sales") AS "genre_year_median"
    FROM sum_pub
    GROUP BY "genre", "year"
)
SELECT
    r."publisher_name",
    r."game_name",
    r."year",
    r."genre",
    r."global_sales",
    r."suspected_sequel",
    ROUND(gm."genre_year_median"::numeric, 4) AS genre_year_median,
    ROUND((r."global_sales" / NULLIF(gm."genre_year_median", 0))::numeric, 2) AS vs_median_ratio,
    --Categorise for vis
    CASE
        WHEN r."global_sales" >= gm."genre_year_median" * 2  THEN 'strong breakout'
        WHEN r."global_sales" >= gm."genre_year_median" THEN 'above median'
        WHEN r."global_sales" >= gm."genre_year_median" * 0.5 THEN 'below median'
        ELSE 'weak entry'
    END AS "entry_performance"
FROM ranked_pub_games r
JOIN genre_medians gm ON 
    gm."genre" = r."genre"
    AND
    gm."year" = r."year"
WHERE 
    r."time_rank" = 1
    AND
    r."year" >= 2006
;

--Top 8 performing new entrants
SELECT 
    "publisher_name",
    "game_name",
    "genre",
    "global_sales",
    "suspected_sequel",
    "vs_median_ratio",
    "entry_performance"
FROM new_entrant_performance_view
ORDER BY "global_sales" DESC
LIMIT 8; --8 as 3 are sequels and want to see top 5
--ben 10: alien force and the walking dead season one build upon pre-existing IP for their first title
--no mans sky, project cars, and winter sports: the ultimate challenge are other 3 high performers but can't notice a pattern
--no mans sky had revolutionary technology and large marketing
--project cars was initially crowdfunded, significant community involvement
--winter sports: the ultimate challenge took advantage of market at the time, wii (motion control) craze and olympics


--Performance review
SELECT
    "entry_performance",
    COUNT(*) AS "count",
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS "pct_of_total",
    ROUND(AVG("vs_median_ratio"), 2) AS "avg_vs_median"
FROM new_entrant_performance_view
-- WHERE "suspected_sequel" = FALSE --distribution hardly shifts when excluding suspected sequels +/- 1pct_of_total
GROUP BY "entry_performance"
ORDER BY "count" DESC;
--50.78% have a weak entry
--Only 28.52% entry titles outperform the median 


--Genre breakdown measuring market accessability
SELECT
    "genre",
    COUNT(*) AS "total_first_entrants",
    COUNT(*) FILTER (WHERE "entry_performance" = 'strong breakout') AS "strong_breakouts",
    COUNT(*) FILTER (WHERE "entry_performance" = 'above median') AS "above_median",
    ROUND(
        (COUNT(*) FILTER (WHERE "entry_performance" = 'strong breakout') + COUNT(*) FILTER (WHERE "entry_performance" = 'above median'))
        * 100.0 / COUNT(*), 2
    ) AS "breakout_rate_pct"
FROM new_entrant_performance_view
GROUP BY "genre"
ORDER BY "breakout_rate_pct" DESC;
--shooter have only has 11.11% breakout chance, eventhough high in other metrics this shows it's unforgiving AVOID
--puzzle has 50% breakout chance, eventhough low in other metrics. shows support for new titles.
--action, adventure, misc relatively forgiving
--role-playing, fighting, sports moderate breakout
--AVOID strategy, simulation, racing, platform
--Relatively as 50% is highest would condsider 
--0 - 16.66% low accessability
--16.67% - 33.33% moderate accessability
--33.34% - 50% high accessability