--Use this table to stage the data before transforming and loading it into the final tables. 
--This allows for data cleaning and validation before it is used for analysis.
CREATE TABLE staging_games (
    "rank" INT,
    "name" VARCHAR(255),
    "platform" VARCHAR(50),
    "year" INT,
    "genre" VARCHAR(50),
    "publisher" VARCHAR(255),
    "na_sales" NUMERIC(5,2),
    "eu_sales" NUMERIC(5,2),
    "jp_sales" NUMERIC(5,2),
    "other_sales" NUMERIC(5,2),
    "global_sales" NUMERIC(5,2)
);

CREATE TABLE raw_staging_games (
    "rank" INT,
    "name" VARCHAR(255),
    "platform" VARCHAR(50),
    "year" INT,
    "genre" VARCHAR(50),
    "publisher" VARCHAR(255),
    "na_sales" NUMERIC(5,2),
    "eu_sales" NUMERIC(5,2),
    "jp_sales" NUMERIC(5,2),
    "other_sales" NUMERIC(5,2),
    "global_sales" NUMERIC(5,2)
);