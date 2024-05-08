-- first and last date in the events database
SELECT MIN(date) AS first_date,
       MAX(date) AS last_date
FROM `saas_final_project_dataset.events`;

-- first and last date in the user database
SELECT MIN(created_date) AS first_date,
       MAX(created_date) AS last_date
FROM `saas_final_project_dataset.user_info`;  

-- how many users, accesses
SELECT COUNT(*) AS accesses, -- Number of accesses
       COUNT (DISTINCT user_id) AS users, -- Number of users
       ROUND(COUNT(*) / COUNT(DISTINCT date), 0) AS accesses_day, -- Accesses per day
       ROUND(COUNT(DISTINCT user_id) / COUNT(DISTINCT date), 0) AS users_day, -- Users per day
       ROUND(SUM(volume) / COUNT(DISTINCT user_id), 2) AS volumer_pe_user, -- volume per user
       ROUND(SUM(volume) / COUNT(*), 2) AS volume_per_work -- volume per work
  FROM `saas_final_project_dataset.events`
 WHERE user_id IS NOT NULL;

-- Check the data in user_info
-- users have multiple row values
SELECT *
FROM `saas_final_project_dataset.user_info`
WHERE user_id in (
SELECT user_id
FROM `saas_final_project_dataset.user_info`
GROUP BY user_id
HAVING COUNT(*) > 1
)
ORDER BY user_id;

-- how many users using the servie during the period and which country they come from
-- clean data in user_info - take the country code when the user_id was first created
-- prevent duplicated user_id in user_info when joining
WITH user_row AS (
  SELECT *,
       ROW_NUMBER() OVER(PARTITION BY user_id ORDER BY created_date ASC) AS ROW 
  FROM `saas_final_project_dataset.user_info`
 WHERE mp_country_code IS NOT NULL
)
SELECT MAX(g.Country) AS Country,
       g.Code,
       COUNT(DISTINCT e.user_id) AS users
  FROM `saas_final_project_dataset.events` AS e
  JOIN user_row AS u
    ON e.user_id = u.user_id
  JOIN `saas_final_project_dataset.geography` AS g
    ON u.mp_country_code = g.Code
 WHERE u.ROW = 1
 GROUP BY g.Code
 ORDER BY users DESC;

-- usage over time
SELECT date, 
       ROUND(SUM(volume), 2) AS total_volume
  FROM `saas_final_project_dataset.events`
 WHERE user_id IS NOT NULL
 GROUP BY date;

-- user per platform over time
SELECT date,
       platform,
       COUNT(DISTINCT user_id) AS users
  FROM `saas_final_project_dataset.events`
 WHERE user_id IS NOT NULL
 GROUP BY date, platform;