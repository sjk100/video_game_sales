--regional skew + correlations + platform selection + genre × platform

--Weak globally but strong in one region -> niche opportunity
WITH totals AS (
    SELECT
        SUM("na_sales") AS total_na,
        SUM("eu_sales") AS total_eu,
        SUM("jp_sales") AS total_jp,
        SUM("other_sales") AS total_other,
        SUM("global_sales") AS total_global
    FROM game_sales_view
)
SELECT
    "genre",
--    ROUND((SUM("na_sales") / t.total_na)  * 100, 2) AS na_share,
--    ROUND((SUM("eu_sales") / t.total_eu)  * 100, 2) AS eu_share,
--    ROUND((SUM("jp_sales") / t.total_jp)  * 100, 2) AS jp_share,
--    ROUND((SUM("other_sales") / t.total_other)  * 100, 2) AS other_share,
    ROUND((SUM("global_sales") / t.total_global)  * 100, 2) AS global_share,
    ROUND(((SUM("na_sales") / t.total_na) - (SUM("global_sales") / t.total_global))  * 100, 2) AS na_skew,
    ROUND(((SUM("eu_sales") / t.total_eu) - (SUM("global_sales") / t.total_global))  * 100, 2) AS eu_skew,
    ROUND(((SUM("jp_sales") / t.total_jp) - (SUM("global_sales") / t.total_global))  * 100, 2) AS jp_skew,
    ROUND(((SUM("other_sales") / t.total_other) - (SUM("global_sales") / t.total_global))  * 100, 2) AS other_skew
    FROM game_sales_view, totals t
    GROUP BY "genre", t.total_na, t.total_eu, t.total_jp, t.total_other, t.total_global
;
-- JP has largest +ve skew role-playing by +16.82%, niche opportunity


--Correlation between regions
WITH corr AS (
    SELECT
        ROUND(CORR("na_sales", "na_sales")::numeric, 2) AS na,
        ROUND(CORR("na_sales", "eu_sales")::numeric, 2) AS na_eu,
        ROUND(CORR("na_sales", "jp_sales")::numeric, 2) AS na_jp,
        ROUND(CORR("na_sales", "other_sales")::numeric, 2) AS na_other,
        ROUND(CORR("na_sales", "global_sales")::numeric, 2) AS na_global,
        ROUND(CORR("eu_sales", "eu_sales")::numeric, 2) AS eu,
        ROUND(CORR("eu_sales", "jp_sales")::numeric, 2) AS eu_jp,
        ROUND(CORR("eu_sales", "other_sales")::numeric, 2) AS eu_other,
        ROUND(CORR("eu_sales", "global_sales")::numeric, 2) AS eu_global,
        ROUND(CORR("jp_sales", "jp_sales")::numeric, 2) AS jp,
        ROUND(CORR("jp_sales", "other_sales")::numeric, 2) AS jp_other,
        ROUND(CORR("jp_sales", "global_sales")::numeric, 2) AS jp_global,
        ROUND(CORR("other_sales", "other_sales")::numeric, 2) AS other,
        ROUND(CORR("other_sales", "global_sales")::numeric, 2) AS other_global,
        ROUND(CORR("global_sales", "global_sales")::numeric, 2) AS global
    FROM game_sales_view
)
SELECT 'na' AS region, na AS na, na_eu AS eu, na_jp AS jp, na_other AS other, na_global AS global FROM corr
UNION ALL
SELECT 'eu', na_eu, eu, eu_jp, eu_other, eu_global FROM corr
UNION ALL
SELECT 'jp', na_jp, eu_jp, jp, jp_other, jp_global FROM corr
UNION ALL
SELECT 'other', na_other, eu_other, jp_other, other, other_global FROM corr
UNION ALL
SELECT 'global', na_global, eu_global, jp_global, other_global, global FROM corr;
--jp has low correlation with other regions 
--jp-na at 0.45 jp-eu at 0.44 jp-other at 0.29 jp-global at 0.61, it is truly an independant market
--intra regions (excluding jp) roughly around 0.63 to 0.77
--na and eu very similar to global at 0.94 and 0.9 respectively
--other regions generally correlate to the global market at 0.75



--WHICH PLATFORM SHOULD WE AIM TO RELEASE ON?

--view to seperate platforms that are still active as of latest release in database
CREATE VIEW active_platform_view AS 
    SELECT DISTINCT "platform_name"
    FROM game_sales_view
    WHERE "year" = '2016';


\set year_start 2006
\set year_end 2016

WITH platform_shares AS (
    SELECT
        g."platform_name",
        g."game_name",
        g."global_sales",
        SUM(g."global_sales") OVER (PARTITION BY g."platform_name") AS platform_total,
        g."release_id"
    FROM game_sales_view g
    INNER JOIN active_platform_view ap ON ap."platform_name" = g."platform_name" -- INNER as any platform without 2016 entry will be excluded
    WHERE "year" BETWEEN :year_start AND :year_end
)
SELECT
    "platform_name",
    SUM("global_sales") AS "global_sales",
    COUNT("release_id") AS "number_of_releases",
    ROUND(SUM("global_sales") / COUNT("release_id"), 4) AS "sales_per_release",
    ROUND(SUM(POWER(global_sales / platform_total, 2)), 4) AS "hhi"
FROM platform_shares
GROUP BY "platform_name"
ORDER BY "sales_per_release" DESC
;
--ps4 is the leading platform followed by x360 but that is now obsolete as new gen (at time of this data) is ps4 v xone
--ps4 most sales_per_release
--ps4 has lower hhi than xone so slightly more evenly distributed wealth
--ps4 should be target platform


--PLATFORM LIFECYCLE CURVE
SELECT
    g."platform_name",
    g."year",
    ROUND(COUNT(g."release_id") / SUM(COUNT(g."release_id")) OVER (PARTITION BY g."year") * 100, 4) AS release_share
FROM
    game_sales_view g
INNER JOIN
    active_platform_view ap ON ap."platform_name" = g."platform_name"
WHERE "year" BETWEEN 2006 AND 2016
GROUP BY
    g."platform_name", g."year"
ORDER BY
    g."platform_name" ASC,
    g."year" ASC
;
--ps4 gets 31.1% of games released in 2016 but also high sales_per_release
--followed by (of current gen) psv with 17.4%, then xone at 15.7%, pc at 11.0%, 3ds at 10.2%
--ps3 at 9.3%, wiiu at 2.9%, x360 at 2.3% have diminished their market share will be at end of cycle


-- Genre x Platform sales
WITH genre_platform_stats AS (
    SELECT
        g."genre",
        g."platform_name",
        COUNT(*) AS game_count,
        ROUND(AVG(g."global_sales"), 4) AS avg_global_sales,
        SUM(g."global_sales") AS total_global_sales
    FROM game_sales_view g
    INNER JOIN 
        active_platform_view ap ON ap."platform_name" = g."platform_name" -- INNER as any platform without 2016 entry will be excluded
    WHERE g."platform_name" IN ('ps4', 'xone', 'psv', '3ds', 'pc')
    GROUP BY g."genre", g."platform_name"
    HAVING COUNT(*) > 20
),
ranked_gp AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (PARTITION BY "platform_name" ORDER BY "avg_global_sales" DESC) AS genre_rank
    FROM genre_platform_stats
)
SELECT
    "platform_name",
    "genre",
    "game_count",
    ROUND("avg_global_sales", 2) AS avg_global_sales,
    "total_global_sales"
FROM ranked_gp
WHERE "genre_rank" <= 3
ORDER BY
    "platform_name",
    "genre_rank" ASC
;
--ps4 and xone have best 3 performing genres same, shooter, sports, and action 
--if targeting ps4 will also benefit from xone as shared market
--3ds best are platform, simulation, role-playing
--pc best are role-playing, simulation, misc
--psv best are sports, misc, role-playing