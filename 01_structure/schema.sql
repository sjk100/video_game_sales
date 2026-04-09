DROP TABLE IF EXISTS "platforms" CASCADE;
DROP TABLE IF EXISTS "games" CASCADE;
DROP TABLE IF EXISTS "sales" CASCADE;
DROP TABLE IF EXISTS "publishers" CASCADE;
DROP TABLE IF EXISTS "game_releases" CASCADE;

-- The schema is normalized, allowing analysis across multiple dimensions like platform, region, and time.
CREATE TABLE "platforms" (
    "id" INT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    "platform" VARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE "publishers" (
    "id" INT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    "name" VARCHAR(255) NOT NULL UNIQUE
);

CREATE TABLE "games" (
    "id" INT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    "name" VARCHAR(255) NOT NULL,
    "genre" VARCHAR(50),
    "publisher_id" INT NOT NULL,
    FOREIGN KEY (publisher_id) REFERENCES publishers(id)
);

CREATE TABLE "game_releases" (
    "id" INT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    "game_id" INT NOT NULL,
    "platform_id" INT NOT NULL,
    "year" INT CHECK (year >= 1970 AND year <= 2100),
    FOREIGN KEY (game_id) REFERENCES games(id) ON DELETE CASCADE,
    FOREIGN KEY (platform_id) REFERENCES platforms(id),
    UNIQUE (game_id, platform_id, year)
);

CREATE TABLE "sales" (
    "release_id" INT NOT NULL UNIQUE,
    "na_sales" NUMERIC(5,2),
    "eu_sales" NUMERIC(5,2),
    "jp_sales" NUMERIC(5,2),
    "other_sales" NUMERIC(5,2),
    "global_sales" NUMERIC(5,2),
    FOREIGN KEY (release_id) REFERENCES game_releases(id) ON DELETE CASCADE
);
