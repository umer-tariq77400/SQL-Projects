USE gdb023;

--  Markets in which customer "Atliq Exclusive" operates its business in the APAC region
SELECT distinct(market) as markets
FROM dim_customer
WHERE customer = 'Atliq Exclusive' and region = 'APAC';

-- percentage of unique product increase in 2021 vs. 2020
SELECT unique_products_2020,
       unique_products_2021,
     ((unique_products_2021 - unique_products_2020) / unique_products_2021)*100 AS percentage_chg
FROM (SELECT DISTINCT
			(SELECT COUNT(DISTINCT(product_code)) FROM fact_gross_price WHERE fiscal_year = 2020) AS unique_products_2020, 
			(SELECT COUNT(DISTINCT(product_code)) FROM fact_gross_price WHERE fiscal_year = 2021) AS unique_products_2021
      FROM fact_gross_price) AS a;
      
      
-- all the unique product counts for each segment
SELECT segment, COUNT(DISTINCT(product_code)) AS unique_product_count
FROM dim_product
GROUP BY segment
ORDER BY unique_product_count DESC;


-- Segment which had the most increase in unique products in 2021 vs 2020
SELECT segment, product_count_2020, product_count_2021, (product_count_2021 - product_count_2020) AS difference
FROM (SELECT
    segment,
    MAX(CASE WHEN fiscal_year = 2020 THEN unique_products_count END) AS product_count_2020,
    MAX(CASE WHEN fiscal_year = 2021 THEN unique_products_count END) AS product_count_2021
FROM (
    SELECT
        a.segment,
        b.fiscal_year,
        COUNT(DISTINCT a.product_code) AS unique_products_count
    FROM dim_product AS a
    JOIN fact_gross_price AS b
    ON a.product_code = b.product_code
    GROUP BY a.segment, b.fiscal_year
) AS subquery1
GROUP BY segment) AS subquery2
ORDER BY difference DESC
LIMIT 1;

-- products that have the highest and lowest manufacturing costs
(SELECT 
    a.product_code, product,
    manufacturing_cost 
FROM dim_product AS a 
JOIN fact_manufacturing_cost AS b 
ON a.product_code = b.product_code 
ORDER BY manufacturing_cost ASC 
LIMIT 1)
UNION 
(SELECT a.product_code, product, manufacturing_cost 
FROM dim_product AS a 
JOIN fact_manufacturing_cost AS b 
ON a.product_code = b.product_code 
ORDER BY manufacturing_cost DESC 
LIMIT 1);


-- 5 customers who received an average high pre_invoice_discount_pct for the fiscal year 2021 and in the Indian market
SELECT 
   a.customer_code, 
   a.customer, 
   avg(b.pre_invoice_discount_pct) AS average_discount_percentage
FROM dim_customer AS a 
JOIN fact_pre_invoice_deductions AS b
ON a.customer_code = b.customer_code
JOIN fact_sales_monthly AS c
ON b.customer_code = c.customer_code
WHERE market = 'India' and c.fiscal_year = 2021
GROUP BY a.customer_code
ORDER BY average_discount_percentage DESC
LIMIT 5;


--  complete report of the Gross sales amount for the customer “Atliq Exclusive” for each month
SELECT b.fiscal_year AS Year, DATE_FORMAT(b.date, '%Y-%m') AS Month, ROUND(SUM(b.sold_quantity * c.gross_price),2) AS Gross_Sales_Amount
FROM dim_customer AS a
JOIN fact_sales_monthly AS b 
ON a.customer_code = b.customer_code
JOIN fact_gross_price AS c 
ON b.product_code = c.product_code
WHERE a.customer = 'Atliq Exclusive'
GROUP BY b.fiscal_year, DATE_FORMAT(b.date, '%Y-%m');


-- Quarter of 2020, which got the maximum total_sold_quantity
SELECT QUARTER(date) AS Quarter, SUM(sold_quantity) AS total_sold_quantity
FROM  fact_sales_monthly
WHERE fiscal_year = 2020
GROUP BY Quarter
ORDER BY total_sold_quantity DESC;


-- Channel which helped to bring more gross sales in the fiscal year 2021 and the percentage of contribution
SELECT 
    a.channel,
    SUM(b.sold_quantity * c.gross_price) / 1000000 AS gross_sales_mln,
    ROUND((SUM(b.sold_quantity * c.gross_price) / 1000000) / d.total_gross_sales * 100,2) AS percentage
FROM dim_customer AS a
JOIN fact_sales_monthly AS b ON a.customer_code = b.customer_code
JOIN fact_gross_price AS c ON b.product_code = c.product_code
JOIN 
    (SELECT 
         SUM(b.sold_quantity * c.gross_price) / 1000000 AS total_gross_sales
     FROM fact_sales_monthly AS b
     JOIN fact_gross_price AS c ON b.product_code = c.product_code
     WHERE b.fiscal_year = 2021) AS d ON 1=1
WHERE b.fiscal_year = 2021
GROUP BY a.channel, d.total_gross_sales;


-- Top 3 products in each division that have a high total_sold_quantity in the fiscal_year 2021
SELECT 
    division, 
    product_code
FROM (
    SELECT 
        b.division, 
        b.product_code, 
        SUM(a.sold_quantity) AS total_quantity_sold,
        ROW_NUMBER() OVER (PARTITION BY b.division ORDER BY SUM(a.sold_quantity) DESC) AS row_NO
    FROM fact_sales_monthly AS a
    JOIN dim_product AS b ON a.product_code = b.product_code
    WHERE fiscal_year = 2021
    GROUP BY b.division, b.product_code
) AS subquery
WHERE row_NO IN (1, 2, 3);








