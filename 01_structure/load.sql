\copy raw_staging_games FROM 'path:/coding_projects/video_game_sales/vgsales.csv' DELIMITER ',' CSV HEADER NULL 'N/A';
\copy staging_games FROM 'path:/coding_projects/video_game_sales/vgsales.csv' DELIMITER ',' CSV HEADER NULL 'N/A';
-- NULL values in the CSV are represented as 'N/A', 
--so we specify that in the COPY command to ensure they are correctly interpreted as NULL in the database.
--Noticed as went to load CSV but data type of year column is INT but there are some 'N/A' values which caused error.