-- DATA CLEANING
USE sales;
SELECT * FROM markets;

SELECT DISTINCT *
FROM markets
ORDER BY zone ASC;

SELECT COUNT(*)
FROM transactions
WHERE market_code IN (097, 999);
-- market_code 097, 999 (newyork, paris) are anomolies
-- No transaction record exists for the two markets

SELECT *
FROM markets
LEFT JOIN transactions 
	ON markets.markets_code = transactions.market_code
ORDER BY market_code;

CREATE VIEW markets_clean AS
SELECT *
FROM markets
WHERE markets_code IN (
	SELECT DISTINCT transactions.market_code
    FROM transactions );

SELECT COUNT(*)
FROM transactions
WHERE sales_amount <= 0;
-- 1611 transactions with 0 or less than 0 amount
SELECT COUNT(*) FROM sales.transactions;
-- 150283 records where 1611 are empty records. 
SELECT SUM(sales_qty) 
FROM transactions
WHERE sales_amount <=0; 
-- 12781 products sold where sale amount is less than or equal to 0
SELECT SUM(sales_qty)
FROM transactions
WHERE !(sales_amount <=0); 
-- 2431634 products have proper sale amount
-- It is hardly over 0.5% of products sold with record. So, we can avoid using these
-- This will not have much impact on the analysis.
-- Create a view to avoid using the empty records.

-- There are some record which have USD as currency 
SELECT * FROM transactions WHERE currency = 'USD';
SELECT DISTINCT currency FROM transactions;
-- INR and USD appear twice.(there is an escape sequence in currency name) 
-- Convert USD to INR then overwrite the INR(with escape seq) as INR

CREATE VIEW transactions_clean AS
SELECT product_code,
customer_code,
market_code,
order_date,
sales_qty,
-- convert USD to INR in sales_amount
    CASE 
        WHEN TRIM(REPLACE(REPLACE(currency, '\r', ''), '\n', '')) = 'USD' 
        THEN sales_amount * 89
        ELSE sales_amount
    END AS sales_amount,
    -- normalize currency to INR
    'INR' AS currency
FROM 
    transactions
WHERE 
    sales_amount > 0;
-- Fixed USD to INR conversion rate used for analysis simplicity
-- Exchange rate = 1 USD = 89 INR


SELECT * FROM markets_clean ORDER BY markets_name;
-- Bhopal appears to have a duplicate with different market_code (007, 013)
-- 13228 records have bhopal 007 and 96 records have bhopal 013.
-- It is possible that bhopal has 2 markets within the city
-- Keep both for analysis

