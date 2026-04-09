--input from cleaned staging table to the final working tables
BEGIN;

INSERT INTO "platforms" ("platform")
SELECT DISTINCT "platform"
FROM staging_games
WHERE "platform" IS NOT NULL;

INSERT INTO "publishers" ("name")
SELECT DISTINCT "publisher"
FROM staging_games
WHERE "publisher" IS NOT NULL;

INSERT INTO "games" ("name", "genre", "publisher_id")
SELECT DISTINCT ON (s."name", s."publisher")
    s."name",
    s."genre",
    p."id"
FROM staging_games s
JOIN publishers p ON s."publisher" = p."name";

INSERT INTO game_releases ("game_id", "platform_id", "year")
SELECT DISTINCT
    g."id",
    pl."id",
    s."year"
FROM staging_games s
JOIN "publishers" p ON s."publisher" = p."name"
JOIN "games" g ON s."name" = g."name"
    AND p."id" = g."publisher_id"
JOIN "platforms" pl ON s."platform" = pl."platform";

INSERT INTO "sales" ("release_id", "na_sales", "eu_sales", "jp_sales", "other_sales", "global_sales")
SELECT DISTINCT ON (gr."id")
    gr."id",
    s."na_sales",
    s."eu_sales",
    s."jp_sales",
    s."other_sales",
    s."global_sales"
FROM staging_games s
JOIN "publishers" p ON s."publisher" = p."name"
JOIN "games" g ON s."name" = g."name"
    AND p."id" = g."publisher_id"
JOIN "platforms" pl ON s."platform" = pl."platform"
JOIN "game_releases" gr ON g."id" = gr."game_id"
    AND pl."id" = gr."platform_id"
    AND s."year" = gr."year";

COMMIT;