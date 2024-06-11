SELECT *
FROM data_project.customer_transaction ct 
LIMIT 10;

SELECT CustomerID, SUM(GMV)
FROM data_project.customer_transaction ct 
GROUP BY CustomerID
ORDER BY 2 DESC;

# ROW_NUMBER cho R, F, M
WITH cal AS (
SELECT CustomerID, 
		DATEDIFF(DAY, MAX(Purchase_Date), '2022-09-01') AS recency,
		ROUND(COUNT(DISTINCT CAST(Purchase_Date AS date))*1.00 / DATEDIFF(year, CAST(created_date AS date), '2022-09-01'), 2)  AS frequency,
		(sum(gmv) / DATEDIFF(year, CAST(created_date AS date), '2022-09-01')) AS monetary,
		sum(ct.GMV) AS GMV
FROM data_project.customer_transaction ct 
JOIN data_project.customer_registered cr ON ct.CustomerID = cr.ID
WHERE CustomerID != 0
GROUP BY CustomerID, created_date)
SELECT *,
		ROW_NUMBER() OVER (ORDER BY recency DESC) AS rn_recency,
		ROW_NUMBER() OVER (ORDER BY frequency) AS rn_frequency,
		ROW_NUMBER() OVER (ORDER BY monetary) AS rn_monetary
INTO #calculation
FROM cal;

# Diem R, F, M dua tren row_number
SELECT CustomerID,
		CASE 
			WHEN rn_recency >= 1 AND rn_recency < (SELECT cast(COUNT(DISTINCT(CustomerID)) * 0.25 AS int) FROM #calculation) 
				THEN '1'
			WHEN rn_recency >= (SELECT cast(COUNT(DISTINCT(CustomerID)) * 0.25 AS int) FROM #calculation) AND rn_recency < (SELECT cast(COUNT(DISTINCT(CustomerID)) * 0.5 AS int) FROM #calculation) 
				THEN '2' 
			WHEN rn_recency >= (SELECT cast(COUNT(DISTINCT(CustomerID)) * 0.5 AS int) FROM #calculation) AND rn_recency < (SELECT cast(COUNT(DISTINCT(CustomerID)) * 0.75 AS int) FROM #calculation) 
				THEN '3' 
			ELSE '4' 		
		END	AS R,
		CASE 
			WHEN rn_frequency >= 1 AND rn_frequency < (SELECT cast(COUNT(DISTINCT(CustomerID)) * 0.25 AS int) FROM #calculation) 
				THEN '1'
			WHEN rn_frequency >= (SELECT cast(COUNT(DISTINCT(CustomerID)) * 0.25 AS int) FROM #calculation) AND rn_frequency < (SELECT cast(COUNT(DISTINCT(CustomerID)) * 0.5 AS int) FROM #calculation) 
				THEN '2' 
			WHEN rn_frequency >= (SELECT cast(COUNT(DISTINCT(CustomerID)) * 0.5 AS int) FROM #calculation) AND rn_frequency < (SELECT cast(COUNT(DISTINCT(CustomerID)) * 0.75 AS int) FROM #calculation) 
				THEN '3' 
			ELSE '4' 		
		END	AS F,
		CASE 
			WHEN rn_monetary >= 1 AND rn_monetary < (SELECT cast(COUNT(DISTINCT(CustomerID)) * 0.25 AS int) FROM #calculation) 
				THEN '1'
			WHEN rn_monetary >= (SELECT cast(COUNT(DISTINCT(CustomerID)) * 0.25 AS int) FROM #calculation) AND rn_monetary < (SELECT cast(COUNT(DISTINCT(CustomerID)) * 0.5 AS int) FROM #calculation) 
				THEN '2' 
			WHEN rn_monetary >= (SELECT cast(COUNT(DISTINCT(CustomerID)) * 0.5 AS int) FROM #calculation) AND rn_monetary < (SELECT cast(COUNT(DISTINCT(CustomerID)) * 0.75 AS int) FROM #calculation) 
				THEN '3' 
			ELSE '4' 		
		END	AS M,
		GMV
INTO #result
FROM #calculation;

# Phan loai khach hang dua tren RFM
SELECT rfm_group, 
		COUNT(*) AS gr_count,
		COUNT(*)*100.00 / (SELECT COUNT(*)*1.00 FROM #result) AS gr_percent,
		CASE
			WHEN rfm_group IN (444, 443, 434, 344, 433, 343, 334, 244, 243) THEN 'VIP'
			WHEN rfm_group IN (442, 441, 432, 431, 342, 341, 332, 331) THEN 'Trung thanh'
			WHEN rfm_group IN (424, 423, 324, 323, 234, 233, 413, 414, 313, 314) THEN 'Tiem nang'
			WHEN rfm_group IN (422, 421, 412, 411, 311, 321, 312, 322) THEN 'Khach hang moi'
			ELSE 'Khac'
		END AS customer_type,
		Sum(GMV) AS Total_GMV_group,
		Sum(GMV)*100.00 / (SELECT SUM(GMV) FROM #RESULT) AS Percent_GMV_group
INTO #rfm
FROM (
	select *, concat(R,F,M) as rfm_group 
	from #result
) AS sub
GROUP BY rfm_group;

# So khach hang, GMV cua moi nhom khach hang
SELECT customer_type,
	sum(gr_count) AS type_count,
	sum(gr_count)*100.00 / (SELECT SUM(gr_count)*1.00 FROM #rfm) AS type_percent,
	SUM(Total_GMV_group) AS Total_GMV_type,
	SUM(Total_GMV_group)*100.00 / (SELECT SUM(Total_GMV_group) FROM #rfm) AS Percent_GMV_type
FROM #rfm
GROUP BY customer_type;

# Xoa bang tam
DROP TABLE #result
DROP table #calculation
DROP TABLE #rfm;
