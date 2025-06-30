DROP TABLE IF exists seller_income, income_of_days


CREATE TEMP TABLE seller_income AS
SELECT
  e.employee_id,
  CONCAT(e.first_name, ' ', e.last_name) AS seller,
  COUNT(s.sales_id) AS operations,
  FLOOR(SUM(p.price * s.quantity)) AS income,
  FLOOR(AVG(p.price * s.quantity)) AS avg_income
FROM employees e
LEFT JOIN sales s ON e.employee_id = s.sales_person_id
LEFT JOIN products p ON p.product_id = s.product_id
GROUP BY e.employee_id, e.first_name, e.last_name
order by income desc nulls last

CREATE TEMP TABLE income_of_days AS
select
CONCAT(e.first_name, ' ', e.last_name) AS seller,
trim(to_char(s.sale_date, 'Day')) AS day_of_week,
FLOOR(SUM(p.price * s.quantity)) AS income,
(case trim(to_char(s.sale_date, 'Day'))
when 'Monday' then 1
when 'Tuesday' then 2
when 'Wednesday' then 3
when 'Thursday' then 4
when 'Friday' then 5
when 'Saturday' then 6
when 'Sunday' then 7
end) as num_day
FROM employees e
LEFT JOIN sales s ON e.employee_id = s.sales_person_id
LEFT JOIN products p ON p.product_id = s.product_id
GROUP BY s.sale_date, e.employee_id, e.first_name, e.last_name, num_day
order by num_day

--calculates the total number of customers from the customers table.
select
count(customer_id ) as customers_count
from customers

--Top Ten Sellers Report.
SELECT seller, operations, income
FROM seller_income
LIMIT 10

/*
Information about sellers whose average revenue per transaction 
is less than the average revenue per transaction for all sellers.
*/
SELECT
  seller,
  avg_income
FROM seller_income
WHERE avg_income < (SELECT AVG(income) FROM seller_income)
order by avg_income

--Revenue information by day of the week.
select
seller,
coalesce(day_of_week, 'no date'),
COALESCE(sum(income), 0) as income
from income_of_days
group by day_of_week, seller, num_day
order by num_day, seller

--Number of buyers in different age groups: 16-25, 26-40 and 40+
SELECT
    CASE
        WHEN age BETWEEN 16 AND 25 THEN '16-25'
        WHEN age BETWEEN 26 AND 40 THEN '26-40'
        ELSE '40+'
    END AS age_category,
    count(customer_id) AS age_count
FROM customers
GROUP BY age_category
ORDER BY age_category

--Data on the number of unique buyers and the revenue they generated per month
select
to_char(sale_date, 'YYYY-MM') as selling_month,
count(customer_id) as total_customers,
floor(sum(s.quantity * p.price)) as income
from sales s
left join products p
on s.product_id = p.product_id
group by selling_month
order by selling_month

--Data on customers whose first purchase was during promotions
with first_purchase AS (
  SELECT
    s.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) AS customer, 
    s.sale_date,
    CONCAT(e.first_name, ' ', e.last_name) AS seller,
    ROW_NUMBER() OVER (PARTITION BY s.customer_id ORDER BY s.sale_date) AS rn,
    p.price
  FROM sales s
  LEFT JOIN products p ON s.product_id = p.product_id
  LEFT JOIN customers c ON s.customer_id = c.customer_id
  LEFT JOIN employees e ON s.sales_person_id = e.employee_id
  WHERE p.price = 0
  order by customer_id
)
select
customer,
sale_date,
seller
from first_purchase
where rn = 1
