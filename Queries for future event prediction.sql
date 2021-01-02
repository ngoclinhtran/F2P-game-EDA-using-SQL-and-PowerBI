/*Create segments category based on average levels played and calculate active users of each category, % active users of that group, average levels played per user of each group, and estimated target of levels played for each group for future event*/
WITH fridaytable AS (
	SELECT tablea.id, 
		AVG(CAST(tablea.levels_played AS float)) AS avg_levels_played_per_user, 
		SUM(tablea.levels_played) AS total_levels_played
	FROM (SELECT dbo.Assignment.date, 
				DATENAME(DW, date) AS day_of_the_week, 
				dbo.Assignment.id, 
				dbo.Assignment.levels_played
		FROM dbo.Assignment) AS tablea
	WHERE day_of_the_week = 'Friday'
	GROUP BY tablea.id),
		avg_levels_played_per_user, 
		total_levels_played,
		(CASE WHEN avg_levels_played_per_user <=5 THEN 'Group1: 0-5'
			WHEN avg_levels_played_per_user >5 AND avg_levels_played_per_user <= 15 THEN 'Group2: 5-15'
			WHEN avg_levels_played_per_user >15 AND avg_levels_played_per_user <= 30 THEN 'Group3: 15-30'
			ELSE 'Group4: 30+'
		END) AS Segments
	FROM fridaytable)
	SELECT tablea.id, 
		AVG(CAST(tablea.levels_played AS float)) AS avg_levels_played, 
		SUM(tablea.levels_played) AS total_levels_played
	FROM (SELECT dbo.Assignment.date, 
				DATENAME(DW, date) AS day_of_the_week, 
				dbo.Assignment.id, 
				dbo.Assignment.levels_played
		FROM dbo.Assignment) AS tablea
	WHERE day_of_the_week = 'Friday'
	GROUP BY tablea.id)

SELECT subquery.Segments,
	COUNT(CASE WHEN subquery.predicted_levels_played >= subquery.target_levels_played THEN 1 END) AS 'estimated_target_completion (players)',
	COUNT(CASE WHEN subquery.predicted_levels_played >= (subquery.target_levels_played * 0.5) THEN 1 END) AS 'estimated_50%_target_completion (players)'
FROM(
SELECT
	id, 
	(CASE WHEN avg_levels_played <=5 THEN 'Group1: 0-5'
		WHEN avg_levels_played >5 AND avg_levels_played <= 15   then 'Group2: 5-15'
		WHEN avg_levels_played >15 AND avg_levels_played <= 30   then 'Group3: 15-30'
		ELSE 'Group4: 30+'
	END) AS Segments,
	avg_levels_played, 
	(CASE WHEN avg_levels_played <=5 THEN 4
		WHEN avg_levels_played >5 AND avg_levels_played <= 15   then 14
		WHEN avg_levels_played >15 AND avg_levels_played <= 30   then 31
		ELSE 64
	END) AS target_levels_played,
	ROUND(avg_levels_played*1.056,0) AS predicted_levels_played
FROM fridaytable ) as subquery
GROUP BY subquery.Segments
ORDER BY Segments;