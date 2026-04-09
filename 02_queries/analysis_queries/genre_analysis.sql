--wealth distribution + market share trends 

--create view to simplify queries
CREATE VIEW game_sales_view AS 
    SELECT
        g."id" AS "game_id",
        g."name" AS "game_name",
        g."genre" AS "genre",

        p."id" AS "publisher_id",
        p."name" AS "publisher_name",

        pl."id" AS "platform_id",
        pl."platform" AS "platform_name",

        gr."id" AS "release_id",
        gr."year" AS "year",

        s."na_sales",
        s."eu_sales",
        s."jp_sales",
        s."other_sales",
        s."global_sales"
    FROM
        "games" g
    JOIN "publishers" p ON p."id" = g."publisher_id"
    JOIN "game_releases" gr ON gr."game_id" = g."id"
    JOIN "platforms" pl ON pl."id" = gr."platform_id"
    JOIN "sales" s ON s."release_id" = gr."id"
;


--want to see how wealth is distributed throughout each genre
\set genre_start 2006
\set genre_end 2016

WITH genre_sales AS (
    SELECT
        "genre",
        "game_name",
        SUM("global_sales") AS "total_sales"
    FROM "game_sales_view"
    WHERE "year" BETWEEN :genre_start AND :genre_end
    GROUP BY "genre", "game_name"
),
shares AS(
    SELECT
        "genre",
        "game_name",
        "total_sales",
        "total_sales" / SUM("total_sales") OVER (PARTITION BY "genre") AS "sales_share",
        ROW_NUMBER() OVER (PARTITION BY "genre" ORDER BY "total_sales" DESC) AS "rank_in_genre"
    FROM "genre_sales"
),
genre_stats AS (
    SELECT
    "genre",
    COUNT(*) AS "game_count",
    AVG("total_sales") AS "avg_sales_per_game",
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY "total_sales") AS "median_sales_per_game",
    SUM(sales_share) FILTER (WHERE "rank_in_genre" <= 10) AS "top10_share",
    SUM(POWER("sales_share", 2)) AS "hhi" --measure concentration with Herfindahl-Hirschmann Index
FROM "shares"
GROUP BY "genre"
),
--find minmax hhi for normalisation
minmax_hhi AS (
    SELECT
        MIN("hhi") AS "min_hhi",
        MAX("hhi") AS "max_hhi"
    FROM genre_stats
),
--normalise HHI from 0-1
normalised_hhi AS (
    SELECT
        g.*,
        (g."hhi" - m."min_hhi") / NULLIF((m."max_hhi" - m."min_hhi"), 0) AS "norm_hhi"
    FROM "genre_stats" g
    CROSS JOIN "minmax_hhi" m
),
--next two CTES to compute constants for attractiveness score, use variance-based weighting
weights AS (
    SELECT
        STDDEV(1 - "norm_hhi") AS "std_hhi",
        STDDEV(1 - "top10_share") AS "std_top10"
    FROM normalised_hhi
),
final AS (
    SELECT 
        n.*,
        (w."std_hhi" / (w."std_hhi" + w."std_top10")) AS A,
        (w."std_top10" / (w."std_hhi" + w."std_top10")) AS B
    FROM "normalised_hhi" n
    CROSS JOIN weights w 
)
SELECT
    "genre",
    "game_count",
    ROUND("avg_sales_per_game", 2) AS "avg_sales_per_game", --mean is sensitive to blockbusters, aligns with potential
    ROUND("median_sales_per_game"::numeric, 2) AS "median_sales_per_game", --shows typical outcome, shows usual expectation
    ROUND("top10_share" * 100, 2) AS "top10_percent",
    ROUND("hhi", 4) AS "genre_hhi",
    ROUND("norm_hhi", 4) AS "norm_hhi",
    ROUND("median_sales_per_game"::numeric * (A * (1-"norm_hhi") + B * (1-"top10_share")), 4) AS "attractiveness_score" --Weights mean sales by penalising for high norm_hhi and high top10_share.
FROM
    "final"
ORDER BY 
    "attractiveness_score" DESC
;
--shooters stand out as it has highest attractiveness score as high median sales and moderate hhi
--platform has high median sales but the worst hhi so market is dominated and not good idea to pursue
--action is heavily saturated but has low hhi so wealth is most evenly distributed, pursue if have unique title that can stand out
--role-playing has moderate sales but low hhi so could be safe to pursue
--avoid adventure as lowest sales eventhough moderate hhi



--CREATE VIEW FOR MARKET SHARE
--market size changes over time, this allows us to compare data from different years
CREATE VIEW market_share_view AS 
    SELECT
        "genre",
        "year",
        SUM("global_sales")
        / SUM(SUM("global_sales")) OVER (PARTITION BY "year") * 100 AS market_share 
        --market_share instead of sales as success relative to each year as market grows/shrinks, makes valid for comparison
    FROM
        "game_sales_view"
    WHERE "year" BETWEEN 2006 AND 2016
    GROUP BY 
        "year", 
        "genre"
;

--GENRE MARKET SHARE OVER TIME AND Z-SCORE ANALYSIS
--STABILITY OVER TIME
--z score allows us to compare a genre against it's historical average performance, shows if consistent
--z=0 normal year, z>1 good, z>2 exceptional, z<-1 weak
--z score relative to time period in query
--z score best for tech audience, supporting not headline
SELECT
    "genre",
    "year",
    ROUND(market_share, 2) AS market_share,
    ROUND(
        (market_share 
        - AVG(market_share) OVER (PARTITION BY "genre")) 
        / NULLIF(STDDEV(market_share) OVER (PARTITION BY "genre"), 0)
    , 4) AS "genre_z_score" -- z = (value - mean)/std_dev
FROM
    market_share_view
ORDER BY 
    "genre" ASC,
    "year" ASC
;
--action, shooter trend from -ve in 2006 to +ve in 2016, constant growth
--fighitng is volatile market, z score alternates +ve and -ve 
--role-playing has been performing bettwer over time but dipped in 2016


--LOOK AT TREND WITH SLOPE OF MARKET SHARE OVER THE LAST DECADE
WITH genre_avg AS (
    SELECT
        "genre",
        AVG("year") AS avg_year,
        AVG(market_share) AS avg_share
    FROM market_share_view
    GROUP BY "genre"
)
SELECT
    m."genre",
    ROUND(SUM((m."year" - a.avg_year) * (m.market_share - a.avg_share)) /
        NULLIF(SUM(POWER(m."year" - a.avg_year, 2)), 0), 4) AS trending_slope
    FROM market_share_view m
    JOIN genre_avg a ON a."genre" = m."genre"
    GROUP BY m."genre"
    ORDER BY trending_slope DESC
;
--shooter, action, and role-playing only genres trending positively in the last ten years
--shooter and action clearly above at 1.6 and 1.8
--role-playing at 0.4

