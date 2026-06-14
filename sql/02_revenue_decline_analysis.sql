USE sales;

/* Problem: Is revenue decline primarily caused by seasonal purchasing patterns 
			or by a small group of high-value customers reducing their purchases? */

-- Revenue breakdown and Trend
SELECT * 
FROM transactions_clean;

SELECT YEAR(order_date) AS year, MONTH(order_date) AS month
FROM transactions_clean
GROUP BY year, month
ORDER BY year, month;		-- Only last 3 months for 2017, first 6 months for 2020

SELECT YEAR(order_date) AS year, SUM(sales_amount) AS revenue
FROM transactions_clean
GROUP BY year
ORDER BY year;  	--  Revenue in 2018 -> 41.4 Cr, decline after that in 2019 and 2020 (33.6Cr, 14.2Cr)
-- 2017 can not be comprehended because it has data for only last 3 months. 

SELECT *,
	SUM(revenue) OVER(ORDER BY year,qtr) AS rolling_total,
    DENSE_RANK() OVER(PARTITION BY year ORDER BY revenue DESC) AS revenue_contribution_rank
FROM (
	SELECT YEAR(order_date) AS year,
		QUARTER(order_date) AS qtr,
		SUM(sales_amount) AS revenue
	FROM transactions_clean
    GROUP BY year, qtr
    ) AS t
GROUP BY year, qtr
HAVING year != 2017
ORDER BY year, qtr;		-- Total Revenue across 3 years (18,19,20) is 89.3Cr
-- Q1 and Q3 perform better than Q2 and Q4
-- Q2, Q4 consistently rank 3rd, 4th respectively for revenue contribution
-- Q4 sees the highest dip in revenue every year

-- Investigate the Q4 dip, Whether a product type fails or a customer type

-- Product Type breakdown
SELECT *,
	DENSE_RANK() OVER(PARTITION BY product_type,year ORDER BY revenue DESC) AS revenue_contribution_rank
FROM (
	SELECT product_type,
		YEAR(order_date) AS year,
		QUARTER(order_date) AS qtr,
		SUM(sales_amount) AS revenue
	FROM transactions_clean AS tc
	INNER JOIN products AS pr 
		ON tc.product_code = pr.product_code
	GROUP BY product_type, year, qtr
	HAVING year NOT IN (2017,2020)
    ) AS t
ORDER BY product_type, year, qtr;
-- Q4 ranks last in revenue contribution for both product types Distribution and Own Brand, except for Distribution in 2019.
-- only Products codes available no Product names or categories. Thus, it cannot be identified if a certain product or category is failing in Q4.

-- CUSTOMER BASED ANALYSIS

-- Customer type breakdown
SELECT *,
	DENSE_RANK() OVER(PARTITION BY customer_type, year ORDER BY revenue DESC)
FROM (
	SELECT customer_type,
		YEAR(order_date) AS year,
		QUARTER(order_date) AS qtr,
		SUM(sales_amount) AS revenue
	FROM transactions_clean AS tc
	INNER JOIN customers AS cust
		ON tc.customer_code = cust.customer_code
	GROUP BY customer_type, year, qtr
	HAVING year NOT IN (2017,2020)
    ) AS t
GROUP BY customer_type, year, qtr
ORDER BY customer_type, year, qtr;
-- Q4 ranks last in revenue contribution in both E-commerce and Brick & Mortar customers

-- Brick & Mortar breakdown
SELECT *
FROM (
	SELECT customer_type,
		custmer_name,
		YEAR(order_date) AS year,
		QUARTER(order_date) AS qtr,
		SUM(sales_amount) AS revenue
	FROM transactions_clean AS tc
	INNER JOIN customers AS cust
		ON tc.customer_code = cust.customer_code
	WHERE customer_type = 'Brick & Mortar'
	GROUP BY customer_type, custmer_name, year, qtr
	HAVING year NOT IN (2017,2020) 
    ) AS t
GROUP BY customer_type, custmer_name, year, qtr
ORDER BY customer_type, custmer_name, year, qtr;


/* 2018: 
1- Acclaimed Stores generated 37.2lakhs in Q1, dropped to 16.5lakhs in Q4, with a declining quarterly pattern
2- Electricalsara Stores generated 48.7lakhs in Q3, dropped to 37.7lakhs in Q4, Q1 and Q2 remained above 43lakhs
3- Epic Stores generated 20.8lakhs in Q2 and Q3, dropped to 15.9lakhs in Q4
4- Excel Stores  generated 55lakhs in Q2, dropped to 39lakhs in Q4, Q1 and Q3 remained above 43lakhs
5- Premium Stores  generated 51lakhs in Q2, dropped to 37lakhs in Q4, Q2 -> 47.5 and Q3 -> 50lakhs
6- Forward Stores  generated 30lakhs in Q1, dropped to 19lakhs in Q4, Q2 -> 21 and Q3 -> 24.5lakhs
- not as significant decline in Q4 for Info Stores, Flawless Stores, Nomad Stores, Surface Stores
2019:
1- Electricalsara Stores dropped to 31.6lakhs in Q4, 33lakhs in Q2 as the minimun in the first 3 quarters 
2- Unity Stores dropped to 7.8lakhs in Q4 from 17lakhs in Q3
- Minor Q4 dips in Atlas Stores, Electricalsopedia Stores, Epic Stores, Integration Stores.

14/19 stores purchased less in Q4 across both years
*/

-- Brick & Mortar breakdown
SELECT *
FROM (
	SELECT customer_type,
		custmer_name,
		YEAR(order_date) AS year,
		QUARTER(order_date) AS qtr,
		SUM(sales_amount) AS revenue
	FROM transactions_clean AS tc
	INNER JOIN customers AS cust
		ON tc.customer_code = cust.customer_code
	WHERE customer_type = 'E-commerce'
	GROUP BY customer_type, custmer_name, year, qtr
	HAVING year NOT IN (2017,2020) 
    ) AS t
GROUP BY customer_type, custmer_name, year, qtr
ORDER BY customer_type, custmer_name, year, qtr;
/* 2018: 
1- Control generated 50.9lakhs in Q1, dropped to 26lakhs in Q4, declining pattern (almost -10lakhs QoQ)
2- Leader generated 30lakhs in Q1, dropped to 1.8lakhs in Q4, Q2 and Q3 remained above 20lakhs
3- Sage generated 10lakhs in Q1, dropped to 1.4lakhs in Q4, Q2 -> 40K and Q3 -> 1.7lakhs
- Not as significant decline in Q4 for Sound, Expression

2019:
1- Electricalsocity generated 8lakhs in Q4, averages over 13lakhs for the first three quarters
2- Leader generated only 3k in Q4, averages over 20lakhs for the first three quarters
- Minor Q4 dips in All-Out, Control, Elite, Expression, Propel, Relief, Sage, Sound, Zone

12/19 E-commerce Customers buy less in Q4 across both years
*/

--  Quantify how much does each customers effect the Revenue
WITH cust_revenue AS (
	SELECT customer_type,
			custmer_name,
			SUM(sales_amount) AS revenue
		FROM transactions_clean AS tc
		INNER JOIN customers AS cust
			ON tc.customer_code = cust.customer_code
		GROUP BY customer_type, custmer_name
	)
SELECT *,
	(rolling_total*100) / SUM(revenue) OVER() AS cum_contribution
FROM (
	SELECT *,
		(revenue*100) / SUM(revenue) OVER() AS rev_contribution_percent,
		SUM(revenue) OVER (ORDER BY revenue DESC) AS rolling_total
	FROM cust_revenue
    ) AS t
ORDER BY rev_contribution_percent DESC
LIMIT 16;

/* Electricalsara Stores of type Brick & Mortar contributes almost 42% of the revenue (41Cr)
- Top 5 customers contribute 61% of the revenue	(60Cr)
- Top 10 customers contribute 75% of the revenue	(74Cr)
- Top 16 customers contribute 85.6% of the revenue (84.4Cr)
-> Revenue is heavily concentrated amongst the top customers
- 7 of the Top 10 customers are type Brick & Mortar
-->TOP customers in order: Electricalsara Stores, Electricalslytical, Excel Stores, Premium Stores, Nixon, Info Stores, 
Control, Surge Stores, Acclaimed Stores, Forward Stores, Epic Stores, Nomad Stores, Electricalsocity, Modular, Atlas Stores, Leader
-> Q4 Revenue decline is concentrated among major customers.
*/

-- MARKET BASED ANALYSIS

WITH market_rev AS (
	SELECT zone, 
		SUM(sales_amount) AS revenue
    FROM markets_clean AS mc 
	INNER JOIN transactions_clean AS tc 
		ON mc.markets_code = tc.market_code
	GROUP BY zone
)
SELECT *,
	ROUND((revenue*100) / SUM(revenue) OVER(),1) AS Revenue_share
FROM market_rev;	-- North holds 68.6% Revenue Share, Central - 26.7% and South - 4.6%
-- Revenue is significantly concentrated in the North zone

SELECT zone, COUNT( DISTINCT markets_name) AS total_markets
FROM transactions_clean AS tc
INNER JOIN markets_clean AS mc
	ON tc.market_code = mc.markets_code
GROUP BY zone;		-- 6 markets in North, 5 in South and 3 in central

SELECT zone,
	YEAR(order_date) AS year,
    SUM(sales_amount) AS revenue
FROM transactions_clean AS tc
INNER JOIN markets_clean AS mc
	ON tc.market_code = mc.markets_code
GROUP BY zone, year
ORDER BY zone, year;
-- 2018-2019: Revenue decline of 6.2Cr in North zone and 1.3Cr in Central zone

SELECT markets_code,
	markets_name,
    SUM(sales_amount) AS revenue
FROM transactions_clean AS tc
INNER JOIN markets_clean AS mc
	ON tc.market_code = mc.markets_code
WHERE zone = 'North'
GROUP BY markets_code, markets_name
ORDER BY revenue DESC; -- Delhi NCR is the biggest market with revenue 52Cr across all years
-- Ahmedabad - 13Cr, Kanpur 1.3Cr and the rest of markets are below 50lakhs

SELECT markets_code,
	markets_name,
    SUM(sales_amount) AS revenue
FROM transactions_clean AS tc
INNER JOIN markets_clean AS mc
	ON tc.market_code = mc.markets_code
WHERE zone = 'Central'
GROUP BY markets_code, markets_name
ORDER BY revenue DESC; -- Mumbai is the biggest market with revenue 15Cr across all years
-- Bhopal has two markets with combined revenue of - 5.8Cr, Nagpur - 5.5Cr

SELECT markets_code,
	markets_name,
    SUM(sales_amount) AS revenue
FROM transactions_clean AS tc
INNER JOIN markets_clean AS mc
	ON tc.market_code = mc.markets_code
WHERE zone = 'South'
GROUP BY markets_code, markets_name
ORDER BY revenue DESC; -- Only 2 Markets above 1.8Cr (Kochi & Chennai), Hyderabad - 74 Lakhs, rest are all below 9Lakhs

SELECT *,
	revenue_19 - revenue_18 AS revenue_change
FROM (
	SELECT zone, markets_code, markets_name,
		   SUM(CASE WHEN YEAR(order_date)=2018 THEN sales_amount ELSE 0 END) AS revenue_18,
		   SUM(CASE WHEN YEAR(order_date)=2019 THEN sales_amount ELSE 0 END) AS revenue_19
	FROM transactions_clean tc
	INNER JOIN markets_clean mc 
		ON tc.market_code = mc.markets_code
	GROUP BY zone, markets_code, markets_name
    ) AS t
ORDER BY zone, revenue_change;
/* 2018-2019: 
North:
- all markets are declining
- Delhi NCR - 5Cr, Ahmedabad - 89lakhs,  Kanpur - 14Lakhs, and the last 3 combined - around 25lakhs 
Central:
- 2018-2019: Bhopal(Mark007) sees growth of 12lakhs, rest are all declining
- Mumbai - 1.1Cr, Bhopal(Mark013) just under 10lakhs, Nagpur - 17Lakhs
South:
- Growth in 3 markets, Hyderabad & Kochi - over 3.5lakhs, Bhubaneshwar - 1.3Lakh. Chennai saw decline of 38Lakhs
- Bengaluru had revenue in 2018, 0 in 2019 — effectively shut down
*/

SELECT zone,
	COUNT(*) AS order_volume,
	ROUND(AVG(sales_amount),1) AS avg_order_value,
    AVG(sales_qty) AS avg_basket_size
FROM transactions_clean AS tc
INNER JOIN markets_clean AS mc
	ON tc.market_code = mc.markets_code
INNER JOIN customers AS cust
	ON tc.customer_code = cust.customer_code 
GROUP BY zone;	-- Central leads in order volume 72k, North 68k, South 8k
-- North has the highest average order value of 9.9k, South - 5.6k, Central - 3.6k
-- South has the highest avg basket size of 49, North - 18, Central - 10

WITH stats_2018 AS (
	SELECT zone,
		YEAR(order_date) AS year,
		COUNT(*) AS order_volume_18,
		ROUND(AVG(sales_amount),1) AS avg_order_value_18,
		AVG(sales_qty) AS avg_basket_size_18
	FROM transactions_clean AS tc
	INNER JOIN markets_clean AS mc
		ON tc.market_code = mc.markets_code
	GROUP BY zone, year
	HAVING year = 2018
	ORDER BY zone
    ),
stats_2019 AS (
	SELECT zone,
		YEAR(order_date) AS year,
		COUNT(*) AS order_volume_19,
		ROUND(AVG(sales_amount),1) AS avg_order_value_19,
		AVG(sales_qty) AS avg_basket_size_19
	FROM transactions_clean AS tc
	INNER JOIN markets_clean AS mc
		ON tc.market_code = mc.markets_code
	GROUP BY zone, year
	HAVING year = 2019
	ORDER BY zone
    )
SELECT st18.zone,
    order_volume_19 - order_volume_18 AS order_vol_change,
    avg_order_value_19 - avg_order_value_18 AS avg_order_val_change,
    avg_basket_size_19 - avg_basket_size_18 AS avg_basket_size_change
FROM stats_2018 AS st18
INNER JOIN stats_2019 AS st19
	ON st18.zone = st19.zone;
-- Central: All 3 decreased 
-- North and South: Decrease in order_volume, increase in avg_order_val and avg_basket_size


-- Customers and zones commbined
SELECT zone, COUNT(DISTINCT custmer_name) AS total_customers
FROM transactions_clean AS tc
INNER JOIN markets_clean AS mc
	ON tc.market_code = mc.markets_code
INNER JOIN customers AS cust
	ON tc.customer_code = cust.customer_code
GROUP BY zone;
-- Central has the most customers - 36, North - 26, South - 11

SELECT custmer_name, COUNT(DISTINCT zone) AS zone_count
FROM transactions_clean AS tc
INNER JOIN markets_clean AS mc
	ON tc.market_code = mc.markets_code
INNER JOIN customers AS cust
	ON tc.customer_code = cust.customer_code 
GROUP BY custmer_name
ORDER BY custmer_name;
-- Most of the customers exist in multiple zones (purchases from multiple zones)

SELECT zone_count, COUNT(custmer_name) AS customer_count
FROM (
	SELECT custmer_name, 
		COUNT(DISTINCT zone) AS zone_count
	FROM transactions_clean AS tc
	INNER JOIN markets_clean AS mc
		ON tc.market_code = mc.markets_code
	INNER JOIN customers AS cust
		ON tc.customer_code = cust.customer_code 
	GROUP BY custmer_name
	ORDER BY custmer_name
    ) AS t
GROUP BY zone_count;
-- 19 customers make purchases from 2 zones, 11 customers are only limited to a single zone, 8 customers exist across all zones
