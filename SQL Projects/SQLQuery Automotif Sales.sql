SELECT *
FROM automotive_sales_report..sales_data_sample1$
-- Select Distinct
SELECT DISTINCT STATUS FROM automotive_sales_report..sales_data_sample1$
SELECT DISTINCT YEAR_ID FROM automotive_sales_report..sales_data_sample1$
SELECT DISTINCT PRODUCT_LINE FROM automotive_sales_report..sales_data_sample1$
SELECT DISTINCT COUNTRY FROM automotive_sales_report..sales_data_sample1$
SELECT DISTINCT DEAL_SIZE FROM automotive_sales_report..sales_data_sample1$
SELECT DISTINCT TERRITORY FROM automotive_sales_report..sales_data_sample1$

--Grouping Sales by Productline
SELECT PRODUCT_LINE, SUM(CONVERT(decimal(10, 2), SALES)) AS Revenue
FROM automotive_sales_report..sales_data_sample1$
GROUP BY PRODUCT_LINE
ORDER BY Revenue DESC;

SELECT YEAR_ID, SUM(CONVERT(decimal(10, 2), SALES)) Revenue
FROM automotive_sales_report..sales_data_sample1$
GROUP BY YEAR_ID
ORDER BY 2 DESC

SELECT  DEAL_SIZE,  SUM(CONVERT(decimal(10, 2), SALES)) Revenue
FROM automotive_sales_report..sales_data_sample1$
GROUP BY DEAL_SIZE
ORDER BY 2 DESC

----What was the best month for sales in a specific year? How much was earned that month? 
select  MONTH_ID, SUM(CONVERT(decimal(10, 2), SALES)), count(ORDER_NUMBER) Frequency
FROM automotive_sales_report..sales_data_sample1$
WHERE YEAR_ID = 2004 --change year to see the rest
GROUP BY  MONTH_ID
ORDER BY 2 DESC


--November seems to be the month, what product do they sell in November, Classic I believe
SELECT MONTH_ID, PRODUCT_LINE, MONTH_ID, SUM(CONVERT(decimal(10, 2), SALES)) Revenue, count(ORDER_NUMBER) AS OrderCount
FROM automotive_sales_report..sales_data_sample1$
WHERE YEAR_ID = 2004 and MONTH_ID = 11 --change year to see the rest
GROUP BY  MONTH_ID, PRODUCT_LINE
ORDER BY 3 DESC

----Who is our best customer (this could be best answered with RFM)

DROP TABLE IF EXISTS #rfm;

WITH rfm AS 
(
    SELECT 
        CUSTOMER_NAME, 
         SUM(CAST(SALES AS DECIMAL(10, 2))) AS MonetaryValue,
		 AVG(CAST(SALES AS DECIMAL(10, 2))) AS AvgMonetaryValue,
        COUNT(ORDER_NUMBER) AS Frequency,
        MAX(ORDER_DATE) AS last_order_date,
        DATEDIFF(DAY, MAX(ORDER_DATE), (SELECT MAX(ORDER_DATE) FROM automotive_sales_report..sales_data_sample1$)) AS Recency
    FROM 
        automotive_sales_report..sales_data_sample1$
    GROUP BY 
        CUSTOMER_NAME
),
rfm_calc AS
(
    SELECT 
        r.*,
        NTILE(4) OVER (ORDER BY Recency DESC) AS rfm_recency,
        NTILE(4) OVER (ORDER BY Frequency) AS rfm_frequency,
        NTILE(4) OVER (ORDER BY MonetaryValue) AS rfm_monetary
    FROM 
        rfm r
)
SELECT 
    c.CUSTOMER_NAME, 
    rfm_recency, 
    rfm_frequency, 
    rfm_monetary,
    CASE
        WHEN rfm_recency IN (1, 2) AND rfm_frequency IN (1, 2) AND rfm_monetary IN (1, 2) THEN 'lost_customers'
        WHEN rfm_recency IN (1, 3) AND rfm_monetary IN (3, 4) THEN 'slipping_away'
        WHEN rfm_recency IN (3, 4) THEN 'new_customers'
        WHEN rfm_recency IN (2, 3) THEN 'potential_churners'
        WHEN rfm_recency IN (3, 4) AND rfm_frequency IN (3, 4) THEN 'active'
        WHEN rfm_recency = 4 AND rfm_frequency = 4 AND rfm_monetary = 4 THEN 'loyal'
    END AS rfm_segment
INTO #rfm
FROM 
    rfm_calc c;

SELECT 
    CUSTOMER_NAME, 
    rfm_recency, 
    rfm_frequency, 
    rfm_monetary,
    rfm_segment
FROM 
    #rfm;
--What products are most often sold together? 
select distinct ORDER_NUMBER, stuff(

	(select ',' + PRODUCT_CODE
	FROM automotive_sales_report..sales_data_sample1$ p
	where ORDER_NUMBER in 
		(

			select ORDER_NUMBER
			from (
				select ORDER_NUMBER, count(*) rn
				FROM automotive_sales_report..sales_data_sample1$
				where STATUS = 'Shipped'
				group by ORDER_NUMBER
			)m
			where rn = 3
		)
		and p.ORDER_NUMBER = s.ORDER_NUMBER
		for xml path (''))

		, 1, 1, '') ProductCodes

FROM automotive_sales_report..sales_data_sample1$ s
ORDER BY 2 DESC


---EXTRAs----
--What city has the highest number of sales in a specific country
SELECT CITY, SUM(CONVERT(decimal(10, 2), SALES)) AS Revenue
FROM automotive_sales_report..sales_data_sample1$
WHERE COUNTRY = 'UK'
GROUP BY CITY
ORDER BY Revenue DESC;



---What is the best product in United States?
SELECT COUNTRY, YEAR_ID, PRODUCT_LINE, SUM(CONVERT(decimal(10, 2), SALES)) AS Revenue
FROM automotive_sales_report..sales_data_sample1$
WHERE COUNTRY = 'USA'
GROUP BY COUNTRY, YEAR_ID, PRODUCT_LINE
ORDER BY Revenue DESC;
