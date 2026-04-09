-- Queries to understand data pre-cleaning for staging_games table

-- Row Count
SELECT COUNT(*) AS total_rows
FROM staging_games;
-- 16598 rows


-- Min and Max Year
SELECT 
    MIN("year") AS "min_year",
    MAX("year") AS "max_year"
FROM staging_games;
-- 1977 to 2020
-- CREATE MIN AND MAX VALUES IN SCHEMA TO VALIDATE

--Years with lowest number of entries
SELECT
    "year",
    COUNT(*) AS amount_of_games
FROM staging_games
GROUP BY "year"
ORDER BY COUNT(*) ASC
LIMIT 10;
--Some old years have low counts but expected as less games and diffiult to source data (1980 has 13 games)
--But 2020 has 1 and 2017 has 3, 2019, 2018 have non.
--Cannot say this gives enough evidence to analyse so will remove 2017 onward
--Will adjust context to be publisher acting in 2016 to look at trends for market entrance

--Null values in each column
SELECT 
    SUM(CASE WHEN "rank" IS NULL THEN 1 ELSE 0 END) AS null_rank,
    SUM(CASE WHEN "name" IS NULL THEN 1 ELSE 0 END) AS null_name,
    SUM(CASE WHEN "platform" IS NULL THEN 1 ELSE 0 END) AS null_platform,
    SUM(CASE WHEN "year" IS NULL THEN 1 ELSE 0 END) AS null_year,
    SUM(CASE WHEN "genre" IS NULL THEN 1 ELSE 0 END) AS null_genre,
    SUM(CASE WHEN "publisher" IS NULL THEN 1 ELSE 0 END) AS null_publisher,
    SUM(CASE WHEN "na_sales" IS NULL THEN 1 ELSE 0 END) AS null_na_sales,
    SUM(CASE WHEN "eu_sales" IS NULL THEN 1 ELSE 0 END) AS null_eu_sales,
    SUM(CASE WHEN "jp_sales" IS NULL THEN 1 ELSE 0 END) AS null_jp_sales,
    SUM(CASE WHEN "other_sales" IS NULL THEN 1 ELSE 0 END) AS null_other_sales,
    SUM(CASE WHEN "global_sales" IS NULL THEN 1 ELSE 0 END) AS null_global_sales
FROM staging_games;
-- 271 null_year, 58 null_pubisher, rest 0
-- 1.63% null_year, 0.35% null_publisher
SELECT COUNT(*) FROM "staging_games" WHERE "publisher" = 'Unknown';
-- 203 publishers are Unknown so adding the 58 null then 261 missing entries at 1.57% of the data
-- Missing values were minimal (<2%)
-- PUBLISHER NULLS STANDARDISE TO 'Unknown', EXCLUDE YEARS FROM TIME-SERIES ANALYSIS TO PRESERVE TEMPORAL ACCURACY


--Unique platform, publisher, and genre
SELECT
    COUNT(DISTINCT "platform") AS unique_platforms,
    COUNT(DISTINCT "genre") AS unique_genres,
    COUNT(DISTINCT "publisher") AS unique_publishers
FROM staging_games;
-- 31 unique platforms, 12 unique genres, 578 unique publishers


-- Check for duplicates
SELECT "name", "platform", COUNT(*) AS count
FROM staging_games
GROUP BY "name", "platform"
HAVING COUNT(*) > 1;
-- 5 titles, platforms have duplicates, MUST INVESTIGATE FURTHER IN CLEANING STEP

-- Need for Speed: Most Wanted on PC and X360
SELECT * 
FROM 
    "staging_games"
WHERE
    "name" = 'Need for Speed: Most Wanted'
    AND
    "platform" IN ('PC', 'X360');
-- Same name & platform but different years
-- Upon investigation, these are different games with the same name and platform released on different years.
-- AMEND NAME IN CLEANING STEP TO AVOID DUPLICATE KEY CONSTRAINT VIOLATION IN FINAL TABLES

-- Wii de Asobu: Metroid Prime on Wii
SELECT *
FROM
    "staging_games"
WHERE
    "name" = 'Wii de Asobu: Metroid Prime'
    AND
    "platform" = 'Wii';
-- Total duplicate
--REMOVE ONE IN CLEANING STEP

-- Madden NFL 13 on PS3
SELECT *
FROM
    "staging_games"
WHERE
    "name" = 'Madden NFL 13'
    AND
    "platform" = 'PS3';
-- Duplicate rows with different sale data
-- Remove rank 16130 as only shows 0.01 eu_sales, rest is empty likely an error

-- Sonic the Hedgehog on PS3
SELECT *
FROM
    "staging_games"
WHERE
    "name" = 'Sonic the Hedgehog'
    AND
    "platform" = 'PS3';
-- Second entry represents missing eu_sales data, combine the sales figures into one row and remove the second entry in cleaning step

--Check if global_sales equals sum of regional sales
SELECT COUNT(*) AS "mismatch_sales"
FROM "staging_games"
WHERE 
    ABS(
        ("na_sales" + "eu_sales" + "jp_sales" + "other_sales" - "global_sales")
    ) > 0.01;
-- 10 mismatches, investigate further
SELECT 
    "name",
    "global_sales",
    ROUND("na_sales" + "eu_sales" + "jp_sales" + "other_sales", 2) AS sum_regional_sales,
    ABS("global_sales" - ("na_sales" + "eu_sales" + "jp_sales" + "other_sales")) AS sales_diff
FROM "staging_games"
WHERE 
    ABS(
        ("na_sales" + "eu_sales" + "jp_sales" + "other_sales" - "global_sales")
    ) > 0.01
ORDER BY sales_diff DESC;
-- sales_diff for mismatches is only 0.02 so probably jsut due to rounding issues, no further cleaning needed


--Levenshtein distance to check for similar publishers
CREATE EXTENSION IF NOT EXISTS fuzzystrmatch;

SELECT 
    "p1"."publisher",
    "p2"."publisher",
    levenshtein("p1"."publisher", "p2"."publisher") AS "distance"
FROM
    (SELECT DISTINCT "publisher" FROM "staging_games") "p1"
JOIN
    (SELECT DISTINCT "publisher" FROM "staging_games") "p2"
ON "p1"."publisher" < "p2"."publisher"
WHERE levenshtein("p1"."publisher", "p2"."publisher") <= 3
ORDER BY "distance";
-- Milestone S.r.l investigate
SELECT DISTINCT "publisher"
FROM "staging_games"
WHERE "publisher" ILIKE '%milestone%';
--Milestone S.r.l, and Milestone S.r.l. likely the same publisher, standardise in cleaning step
--Publisher called Milestone upon investigation is a different company so no cleaning necessary
-- Aria and Arika investigate
SELECT *
FROM "staging_games"
WHERE "publisher" ILIKE '%aria%' OR "publisher" ILIKE '%arika%';
-- After investigation they are different companies so no cleaning necessary


--Whilst verifying changes
SELECT 
    "name",
    "year" 
FROM "staging_games" 
WHERE "name" LIKE '%need for speed%most wanted%';
--Noticed release of 2012 version made in 2013 on wiiU so will amend name to include 2012
--Will investigate if this occurs more often
SELECT 
    "name",
    "genre",
    "publisher",
    COUNT(DISTINCT "year") AS "year_count",
    STRING_AGG(DISTINCT "year"::text, ', ' ORDER BY "year"::text) AS "years",
    STRING_AGG(DISTINCT "platform", ', ') AS "platforms"
FROM "staging_games"
GROUP BY 
    "name", 
    "genre", 
    "publisher"
HAVING COUNT(DISTINCT "year") > 1
ORDER BY "name";
--Happens often but not needed for cleaning, due to not changing names on these releases like with nfs:mw


--Want to test the null values in year to understand if they are random or if there is a pattern to them
--for example if they are more common in certain genres or platforms
SELECT
    "genre",
    COUNT(*) AS "total",
    SUM(CASE WHEN "year" IS NULL THEN 1 ELSE 0 END) AS "null_year_count",
    ROUND(100.0 * SUM(CASE WHEN "year" IS NULL THEN 1 ELSE 0 END) / COUNT(*), 2) AS "null_year_pct"
FROM "staging_games"
GROUP BY "genre"
ORDER BY "null_year_pct" DESC;
--Find that 0.78<=null_year_pct<=2.06 across genres with no clear pattern
SELECT
    "platform",
    COUNT(*) AS "total",
    SUM(CASE WHEN "year" IS NULL THEN 1 ELSE 0 END) AS "null_year_count",
    ROUND(100.0 * SUM(CASE WHEN "year" IS NULL THEN 1 ELSE 0 END) / COUNT(*), 2) AS "null_year_pct"
FROM "staging_games"
GROUP BY "platform"
ORDER BY "null_year_pct" DESC;
--Most platform have similar null_year_pct except for '2600' which has 12.78% with count of 17/133
--WILL INVESTIGATE PLATFORM 2600 IN CLEANING STEP TO FILL IN AS SMALL AMOUNT TO INVESTIGATE MANUALLY
--FURTHER ON FIND ATARI ALSO HAS HIGH NULL_YEAR_PCT, WHO MAKES MANY GAMES ON 2600
--AFTER AMENDING PUBLISHER ATARI LATER NOW HAVE 5/133 NULL VALUE YEARS FOR 2600 SO null_year_pct<5% AND CAN LEAVE NULL VALUES
SELECT
    "publisher",
    COUNT(*) AS "total",
    SUM(CASE WHEN "year" IS NULL THEN 1 ELSE 0 END) AS "null_year_count",
    ROUND(100.0 * SUM(CASE WHEN "year" IS NULL THEN 1 ELSE 0 END) / COUNT(*), 2) AS "null_year_pct"
FROM "staging_games"
GROUP BY "publisher"
ORDER BY "null_year_pct" DESC;
--Many high null_year_pct found, must categorise each situation
--'sears' and 'ultravision' have 100% null_year_pct and only 1 entry each, but significant sales so will manually update
SELECT *
FROM "staging_games"
WHERE "publisher" IN ('sears', 'ultravision');
--'unknown' publisher has 47.69% null_year_pct, LEAVE NULL AND EXCLUDE FROM TIME-SERIES ANALYSIS
--Large publishers 'warner bros. interactive entertainment' and 'atari' can be investigated further and manually add details
SELECT 
    "name",
    "platform",
    "publisher",
    "global_sales"
FROM "staging_games"
WHERE 
    "publisher" IN ('warner bros. interactive entertainment', 'atari')
    AND
    "year" IS NULL
ORDER BY "publisher";
--UPDATE MISSING VALUES, HIGH IMPORTANCE AS LARGE PUBLISHERS WITH MANY SALES
--Look at small publishers with null_year_pct > 5% to see if have enough info to manually fill
SELECT 
    "name",
    "platform",
    "publisher",
    "global_sales"
FROM "staging_games"
WHERE 
    "publisher" IN ('topware interactive', 'slitherine software', 'funsta', 'home entertainment suppliers',
        'microprose', 'black bean games', 'kalypso media', 'system 3 arcade software', 'ghostlight', 'city interactive')
    AND
    "year" IS NULL
ORDER BY "publisher";
--UPDATE MISSING VALUE THAT CAN BE FOUND THROUGH EXTERNAL RESEARCH, LEAVE OTHERS NULL


--Want to test the 'unknown'' values in publisher to understand if they are random or if there is a pattern to them
SELECT
    "genre",
    COUNT(*) AS "total",
    SUM(CASE WHEN "publisher" = 'unknown' THEN 1 ELSE 0 END) AS "unknown_publisher_count",
    ROUND(100.0 * SUM(CASE WHEN "publisher" = 'unknown' THEN 1 ELSE 0 END) / COUNT(*), 2) AS "unknown_publisher_pct"
FROM "staging_games"
GROUP BY "genre"
ORDER BY "unknown_publisher_pct" DESC;
--All below 5% with no clear pattern
SELECT
    "platform",
    COUNT(*) AS "total",
    SUM(CASE WHEN "publisher" = 'unknown' THEN 1 ELSE 0 END) AS "unknown_publisher_count",
    ROUND(100.0 * SUM(CASE WHEN "publisher" = 'unknown' THEN 1 ELSE 0 END) / COUNT(*), 2) AS "unknown_publisher_pct"
FROM "staging_games"
GROUP BY "platform"
ORDER BY "unknown_publisher_pct" DESC;
--All below 5% but gba higher so will investigate further
SELECT
    "name",
    "platform",
    "genre"
FROM "staging_games"
WHERE 
    "publisher" = 'unknown'
    AND
    "platform" = 'gba'
ORDER BY "name";
--A lot of these entries are videos released on console
--Will remove as not relevant for analysis