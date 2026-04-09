--25/03/26
--Trim and lowercase columns for standardisation
UPDATE staging_games
SET
    "name" = TRIM(LOWER("name")),
    "platform" = TRIM(LOWER("platform")),
    "genre" = TRIM(LOWER("genre")),
    "publisher" = TRIM(LOWER("publisher"));

--Publisher NULLS to 'unknown'
UPDATE staging_games
SET "publisher" = 'unknown'
WHERE "publisher" IS NULL;

--Amend Need for Speed: Most Wanted PC & X360 titles to 2005 and 2012 respectively
UPDATE staging_games
SET "name" = 'need for speed: most wanted (2005)'
WHERE "name" = 'need for speed: most wanted' AND "year" = '2005';

UPDATE staging_games
SET "name" = 'need for speed: most wanted (2012)'
WHERE "name" = 'need for speed: most wanted' AND "year" = '2012';

--Remove one row of Wii de Asobu: Metroid Prime on Wii
DELETE FROM staging_games
WHERE 
    name = 'wii de asobu: metroid prime'
    AND
    rank = 15002;

--Remove Madden NFL 13 on PS3 with rank 16130 as likely error with only 0.01 eu_sales
DELETE FROM staging_games
WHERE
    name = 'madden nfl 13'
    AND
    rank = 16130;

--Add sales figures together for Sonic the Hedgehog on PS3 and remove second entry with missing eu_sales data
UPDATE staging_games
SET
    "eu_sales" = "eu_sales" + 0.48
WHERE
    name = 'sonic the hedgehog'
    AND
    platform = 'ps3'
    AND
    rank = 1717;

DELETE FROM staging_games
WHERE
    name = 'sonic the hedgehog'
    AND
    platform = 'ps3'
    AND
    rank = 4147;

--Milestone S.r.l , and Milestone S.r.l. likely the same publisher, standardise in cleaning step
UPDATE staging_games
SET publisher = 'milestone s.r.l.'
WHERE publisher = 'milestone s.r.l';

--Found need for speed: most wanted (2012) has a release in 2013 for the wiiu so will amend name
UPDATE staging_games
SET name = 'need for speed: most wanted (2012)'
WHERE name = 'need for speed: most wanted' AND year = 2013;

--26/03/26

--Update large publishers, 'atari' and 'warner bros. interactive entertainment' with null years pct > 5% manually by researching online
--wbie noticed most from 2011 only 2 from 2008
UPDATE staging_games
SET "year" = '2011'
WHERE 
    "year" IS NULL
    AND "publisher" = 'warner bros. interactive entertainment'
    AND NOT("name" = 'lego batman: the video game');
UPDATE staging_games
SET "year" = '2008'
WHERE
    "name" = 'lego batman: the video game'
    AND "publisher" = 'warner bros. interactive entertainment'
    AND "year" IS NULL;

UPDATE staging_games s
SET "year" = m."year"::INTEGER
FROM (
    VALUES
        ('indy 500', '2600', 'atari', '1977'),
        ('combat', '2600', 'atari', '1977'),
        ('air-sea battle', '2600', 'atari', '1977'),

        ('super breakout', '2600', 'atari', '1978'),
        ('hangman', '2600', 'atari', '1978'),
        ('flag capture', '2600', 'atari', '1978'),
        ('home run', '2600', 'atari', '1978'),

        ('slot machine', '2600', 'atari', '1979'),

        ('adventure', '2600', 'atari', '1980'),
        ('space invaders', '2600', 'atari', '1980'),
        ('circus atari', '2600', 'atari', '1980'),
        ('maze craze: a game of cops ''n robbers', '2600', 'atari', '1980'),

        ('transworld surf', 'xb', 'atari', '2001'),
        ('test drive unlimited 2', 'pc', 'atari', '2011'),
        ('test drive unlimited 2', 'x360', 'atari', '2011'),
        ('test drive unlimited 2', 'ps3', 'atari', '2011')

) AS m("name", "platform", "publisher", "year")
WHERE 
    s."name" = m."name"
    AND s."platform" = m."platform"
    AND s."publisher" = m."publisher"
    AND s."year" IS NULL;

--Update small publishers with null years pct > 5% manually by researching online
UPDATE staging_games s
SET "year" = m."year"::INTEGER
FROM (
    VALUES
        ('rollercoaster tycoon', 'pc', 'microprose', '1999'),
        ('luxor: pharaoh''s challenge', 'wii', 'funsta', '2008'),
        ('record of agarest war zero', 'ps3', 'ghostlight', '2009'),

        ('wrc: fia world rally championship', 'pc', 'black bean games', '2010'),
        ('wrc: fia world rally championship', 'x360', 'black bean games', '2010'),
        ('wrc: fia world rally championship', 'ps3','black bean games', '2010'),
        ('get fit with mel b', 'x360', 'black bean games', '2010'),
        ('the history channel: great battles - medieval', 'ps3', 'slitherine software', '2010'),
        ('ferrari: the race experience', 'wii', 'system 3 arcade software', '2010'),

        ('jonah lomu rugby challenge', 'ps3', 'home entertainment suppliers', '2011'),
        ('tropico 4', 'x360', 'kalypso media', '2011'),
        ('battle vs. chess', 'pc', 'topware interactive', '2011'),
        ('battle vs. chess', 'ps3', 'topware interactive', '2011'),

        ('combat wings: the great battles of wwii', 'wii', 'city interactive', '2012'),
        ('port royale 3', 'ps3', 'kalypso media', '2012'),
        ('port royale 3', 'x360', 'kalypso media', '2012')

) AS m("name", "platform", "publisher", "year")
WHERE 
    s."name" = m."name"
    AND s."platform" = m."platform"
    AND s."publisher" = m."publisher"
    AND s."year" IS NULL;

--Update publisher sears and ultravision, was initially gonna drop but they have significant sales so will update manually
UPDATE staging_games
SET "year" = '1982'
WHERE "name" = 'karate' AND "publisher" = 'ultravision' AND "year" IS NULL;

UPDATE staging_games
SET "year" = '1978'
WHERE "name" = 'breakaway iv' AND "publisher" = 'sears' AND "year" IS NULL;

--Platform 2600 had large percent of null year values, no further updates AS updating 2600 and sears, ultravision sufficient to lower null_year_pct<5%

--Delte video entries from gba as not relevant for analysis
DELETE FROM staging_games
WHERE 
    "name" LIKE '%video%'
    AND "platform" = 'gba'
    AND "publisher" = 'unknown'
    AND "name" <> 'lego star wars: the video game';