-- Retention rate
-- first active week of each user
With user_first_week AS (
SELECT user_id,
       EXTRACT(WEEK FROM MIN(date)) AS first_week
  FROM `saas_final_project_dataset.events`
 WHERE user_id IS NOT NULL
 GROUP BY user_id
), -- which weeks users still use the service 
user_retention_week AS ( 
SELECT user_id,
       EXTRACT(WEEK FROM date) AS week_number
  FROM `saas_final_project_dataset.events`
 WHERE user_id IS NOT NULL 
 GROUP BY 1, 2
), -- number of new active users by week 
new_users_by_week AS (
  SELECT first_week,
       COUNT(user_id) AS new_users
  FROM user_first_week
 GROUP BY first_week
), -- number of retained active users by week
retained_users_by_week AS (
SELECT f.first_week,
       r.week_number - f.first_week AS retention_week,
       COUNT(r.user_id) AS retained_users
  FROM user_retention_week AS r
  JOIN user_first_week AS f
    ON r.user_id = f.user_id
 GROUP BY 1, 2  
 ORDER BY 1, 2
) -- retention rate
SELECT CONCAT('Week ', r.first_week) AS first_week,
       CONCAT('Week ', r.retention_week) AS retention_week,
       r.retained_users,
       n.new_users,
       ROUND(r.retained_users*1.00 / new_users, 4) AS retention_rate
  FROM retained_users_by_week AS r
  JOIN new_users_by_week AS n
    ON r.first_week = n.first_week
 ORDER BY 1, 2;
