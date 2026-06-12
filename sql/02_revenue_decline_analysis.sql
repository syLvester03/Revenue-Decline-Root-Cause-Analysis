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

/* Identify if 2020 is expected to see growth in last 6 months to overcome decline */
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



