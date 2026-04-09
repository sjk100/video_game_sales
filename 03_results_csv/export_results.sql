CREATE VIEW export_genre_attractiveness AS
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
        "attractiveness_score" DESC;

\copy (SELECT * FROM export_genre_attractiveness) TO 'C:/Users/samue/OneDrive/Documents/coding_projects/video_game_sales/03_results/genre_attractiveness.csv' WITH CSV HEADER;


CREATE VIEW export_market_share_zscore AS 
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
\copy (SELECT * FROM export_market_share_zscore) TO 'C:/Users/samue/OneDrive/Documents/coding_projects/video_game_sales/03_results/market_share_zscore.csv' WITH CSV HEADER;


CREATE VIEW export_market_trend AS
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
\copy (SELECT * FROM export_market_trend) TO 'C:/Users/samue/OneDrive/Documents/coding_projects/video_game_sales/03_results/market_trend.csv' WITH CSV HEADER;

CREATE VIEW export_publisher_dominance AS 
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
\copy (SELECT * FROM export_publisher_dominance) TO 'C:/Users/samue/OneDrive/Documents/coding_projects/video_game_sales/03_results/publisher_dominance.csv' WITH CSV HEADER;

CREATE VIEW export_top_new_entrants AS 
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
    LIMIT 8;
\copy (SELECT * FROM export_top_new_entrants) TO 'C:/Users/samue/OneDrive/Documents/coding_projects/video_game_sales/03_results/top_new_entrants.csv' WITH CSV HEADER;

CREATE VIEW export_entrant_performance AS 
    SELECT
        "entry_performance",
        COUNT(*) AS "count",
        ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS "pct_of_total",
        ROUND(AVG("vs_median_ratio"), 2) AS "avg_vs_median"
    FROM new_entrant_performance_view
    -- WHERE "suspected_sequel" = FALSE --distribution hardly shifts when excluding suspected sequels +/- 1pct_of_total
    GROUP BY "entry_performance"
    ORDER BY "count" DESC;
\copy (SELECT * FROM export_entrant_performance) TO 'C:/Users/samue/OneDrive/Documents/coding_projects/video_game_sales/03_results/entrant_performance.csv' WITH CSV HEADER;

CREATE VIEW export_market_accessability AS 
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
\copy (SELECT * FROM export_market_accessability) TO 'C:/Users/samue/OneDrive/Documents/coding_projects/video_game_sales/03_results/market_accessability.csv' WITH CSV HEADER;

CREATE VIEW export_regional_skew AS 
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
        ROUND((SUM("global_sales") / t.total_global)  * 100, 2) AS global_share,
        ROUND(((SUM("na_sales") / t.total_na) - (SUM("global_sales") / t.total_global))  * 100, 2) AS na_skew,
        ROUND(((SUM("eu_sales") / t.total_eu) - (SUM("global_sales") / t.total_global))  * 100, 2) AS eu_skew,
        ROUND(((SUM("jp_sales") / t.total_jp) - (SUM("global_sales") / t.total_global))  * 100, 2) AS jp_skew,
        ROUND(((SUM("other_sales") / t.total_other) - (SUM("global_sales") / t.total_global))  * 100, 2) AS other_skew
    FROM game_sales_view, totals t
    GROUP BY "genre", t.total_na, t.total_eu, t.total_jp, t.total_other, t.total_global
;
\copy (SELECT * FROM export_regional_skew) TO 'C:/Users/samue/OneDrive/Documents/coding_projects/video_game_sales/03_results/regional_skew.csv' WITH CSV HEADER;

CREATE VIEW export_regional_correlation AS
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
\copy (SELECT * FROM export_regional_correlation) TO 'C:/Users/samue/OneDrive/Documents/coding_projects/video_game_sales/03_results/regional_correlation.csv' WITH CSV HEADER;

CREATE VIEW export_platform_comparison AS
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
\copy (SELECT * FROM export_platform_comparison) TO 'C:/Users/samue/OneDrive/Documents/coding_projects/video_game_sales/03_results/platform_comparison.csv' WITH CSV HEADER;

CREATE VIEW export_platform_lifecycle AS
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
\copy (SELECT * FROM export_platform_lifecycle) TO 'C:/Users/samue/OneDrive/Documents/coding_projects/video_game_sales/03_results/platform_lifecycle.csv' WITH CSV HEADER;

CREATE VIEW export_genre_platform_relationship AS
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
\copy (SELECT * FROM export_genre_platform_relationship) TO 'C:/Users/samue/OneDrive/Documents/coding_projects/video_game_sales/03_results/genre_platform_relationship.csv' WITH CSV HEADER;

