-- ====================================
# ZEPTO E-COMMERCE DATA ANALYSIS
-- ====================================

create database zepto_analysis;
use zepto_analysis;

create table zepto_raw (
sku_id  int auto_increment primary key,
category varchar(120),
name varchar(150),
mrp bigint,
discount_percent decimal(5,2),
available_quantity int,
discounted_selling_price bigint,
weight_in_gms int,
out_of_stock boolean,
quantity int
);

alter table zepto_raw
modify out_of_stock varchar(10);

show tables;
describe zepto_raw;

select * from zepto_raw
limit 10;

-- ===========================
-- # DATA QUALITY CHECK 
-- ===========================

-- 1. check for NULL VALUES
select count(*) as null_rows 
from zepto_raw
where category is null 
or name is null 
or mrp is null 
or discount_percent is null 
or available_quantity is null 
or discounted_selling_price is null 
or weight_in_gms is null 
or out_of_stock is null 
or quantity is null ;

-- 2. check for Duplicate  SKU IDs
select sku_id,
count(*) as duplicate_count
from zepto_raw
group by sku_id
having count(*)>1;

-- 3. check for invalid Prices
select count(*) as invalid_price_rows
from zepto_raw
where mrp <=0
or discounted_selling_price <=0 ;

-- 4. inspect invalid price records
select sku_id,name,category,
mrp,discounted_selling_price
from zepto_raw
where mrp <=0
or discounted_selling_price <=0 ;

-- 5. check for invalid discount percentages
select count(*) as invalid_discount_rows
from zepto_raw
where discount_percent <0
or discount_percent >100 ;

-- 6. check for invalid quantities 
select count(*) as invalid_quantity_rows
from zepto_raw
where available_quantity <0
or quantity <0 ;

-- 7. check invalid_weights
select count(*) as invalid_weight_rows
from zepto_raw
where weight_in_gms <=0 ;

-- 8. inspect invalid weight rows
select sku_id,name,category,weight_in_gms
from zepto_raw
where weight_in_gms <=0 ;

-- 9. check stock status
select out_of_stock,
count(*) as record_count
from zepto_raw
group by out_of_stock ;

-- 10. check for empty category or product names
select count(*) as empty_rows
from zepto_raw
where trim(category) = ''
or trim(name) = '' ;

-- 11. check if selling price exceeds MRP
select count(*) from zepto_raw
where discounted_selling_price > mrp ;

-- 12. check discount percentage conistency
select count(*) as inconsistent_discount_rows
from zepto_raw
where floor(
((mrp-discounted_selling_price) / mrp)*100 ) != discount_percent
and mrp>0 ;

-- =========================
-- # DATA CLEANING
-- =========================

-- # create clean table

create table zepto_clean as
select sku_id,
trim(category) as category,
trim(name) as name,
round(mrp /100 ,2) as mrp, 
discount_percent,available_quantity,
round(discounted_selling_price /100 ,2) as discounted_selling_price,
case 
when weight_in_gms > 0 then weight_in_gms
else null
end as weight_in_gms,
case
when upper(trim(out_of_stock)) = 'True' then 1
when upper(trim(out_of_stock)) = 'False' then 0
end as out_of_stock,
quantity
from zepto_raw
where mrp>0 
and discounted_selling_price > 0 ;


-- 1. check clean table row count
select count(*) as clean_rows
from zepto_clean;

-- 2. verify invalid price removed
select count(*) as invalid_price_rows
from zepto_clean
where mrp <= 0
or discounted_selling_price <= 0 ;

-- 3. verify invalid weights were handled
select sku_id,
name, weight_in_gms
from zepto_clean
where sku_id in (2837,2926,3181,3270) ;

-- 4. verify stock status conversion
select out_of_stock,
count(*) as record_count
from zepto_clean
group by out_of_stock ;

-- ==============================
-- # DATA EXPLORATION / EDA 
-- ===============================

-- 1. total number of products
select count(*) as total_products
from zepto_clean;

-- 2. total number of categories
select count( distinct category ) as total_categories
from zepto_clean;

-- 3. number of products in each category
select category,
count(*) as product_count
from zepto_clean
group by category
order by product_count desc ;

-- 4. product stock status distribution 
select out_of_stock,
count(*) as product_count
from zepto_clean
group by out_of_stock ;

-- 5. average mrp
select round(avg(mrp),2) as avg_mrp
from zepto_clean ;

-- 6. average selling price
select round(avg(discounted_selling_price),2) as avg_selling_price
from zepto_clean ;

-- 7. average discount percentage
select round(avg(discount_percent),2) as avg_discount_percent
from zepto_clean ;

-- 8. total available inventory
select sum(available_quantity) as total_inventory
from zepto_clean ;

-- 9. total inventory by category
select category,
sum(available_quantity) as total_inventory
from zepto_clean
group by category
order by total_inventory desc ; 

-- 10. product price range (minimum and maximum mrp)
select 
min(mrp) as min_mrp,
max(mrp) as max_mrp
from zepto_clean ;


-- ============================
-- # BUSINESS ANALYSIS
-- ============================
-- 1. which products have the highest selling prices?
select sku_id,name,category,
discounted_selling_price
from zepto_clean
order by discounted_selling_price desc
limit 3 ;
 
 -- 2. which products have the lowest selling prices ?
select sku_id,name,category,
discounted_selling_price
from zepto_clean
order by discounted_selling_price asc
limit 3 ;

-- 3. which are the top 10 most discounted products?
select sku_id,name,category,mrp,
discounted_selling_price,discount_percent
from zepto_clean
order by discount_percent desc
limit 10 ;

-- 4. which products provide the highest discount amount?
select sku_id,name,category,mrp,
discounted_selling_price,
round(mrp - discounted_selling_price ,2) as discount_amount
from zepto_clean
order by discount_amount desc
limit 5 ;

-- 5. which categories offer the highest average discount?
select category,
round(avg(discount_percent) ,2) as avg_discount
from zepto_clean
group  by category
order by avg_discount desc ;

-- 6. which product have the highest potential revenue?
select sku_id,name,category,
available_quantity,discounted_selling_price,
round(discounted_selling_price * available_quantity, 2) as potential_revenue
from zepto_clean
order by potential_revenue desc
limit 6 ;

-- 7. which categories have the highest potential revenue?
select category,
round(sum(discounted_selling_price * available_quantity), 2) as potential_revenue
from zepto_clean
group by category
order by potential_revenue desc ;

-- 8. which categories hold the highest inventory value?
select category,
sum(available_quantity) as total_inventory,
round(sum(discounted_selling_price * available_quantity),2) as inventory_value
from zepto_clean 
group by category
order by inventory_value desc ;

 -- 9. which products have the highest available inventory?
select sku_id,name,category,
available_quantity
from zepto_clean
order by available_quantity desc
limit 3 ;

-- 10. which products are currently out of stock?
select sku_id,name,category,
mrp,discounted_selling_price
from zepto_clean
where out_of_stock = 1 ;

-- 11. which products have relatively low discounts?
select sku_id,name,category,
mrp,discount_percent
from zepto_clean
where discount_percent <10
order by discount_percent,mrp desc;

-- 12. how can products be classified based on inventory levels?
select sku_id,name,
category,available_quantity,
case
when out_of_stock = 1 then 'out_of_stock'
when available_quantity <10 then 'low stock'
when available_quantity <50 then 'medium stock'
else 'healthy stock'
end as inventory_status 
from zepto_clean ;

-- 13. which products require inventory attention?
select sku_id,name,category,
available_quantity,
case 
when out_of_Stock = 1 then 'critical'
when available_quantity <10 then 'high'
when available_quantity <50 then 'medium'
else 'low'
end as priority
from zepto_clean
where out_of_Stock = 1
or available_quantity<50 
order by case 
when out_of_stock =1 then 1
when available_quantity<10 then 2
else 3 
end ;

-- 14. what are the top 3 most discounted products in each category?
with ranked_products as (
select sku_id,name,category,
discount_percent,
row_number() over (partition by category
order by discount_percent desc ) as product_rank
from zepto_clean 
)
select sku_id,name,category,
discount_percent,product_rank
from ranked_products
where product_rank <=3
order by category,product_rank ;

-- 15. how do categories rank by potential revenues?
with category_revenue as(
select category,
sum(discounted_selling_price * available_quantity) as potential_revenue
from zepto_clean
group by category 
)
select category,
round(potential_revenue, 2) as potential_revenue,
rank() over(order by potential_revenue desc ) as revenue_rank
from category_revenue
order by revenue_rank ; 

-- 16. which are the top 3 potential revenue products in each category?
with ranked_products as (
select sku_id,name,category,
round(discounted_selling_price * available_quantity, 2) as potenial_revenue,
row_number() over ( partition by category
order by discounted_selling_price * available_quantity desc) as product_rank
from zepto_clean 
)
select sku_id,name,
category,product_rank
from ranked_products
where product_rank<=3
order by category,product_rank ;

-- 17. what is the overall performance of each category?
select category,
count(*) as total_products,
sum(available_quantity) as total_inventory,
round(avg(mrp),2) as avg_mrp,
round(avg(discounted_selling_price),2) as avg_discounted_selling_price,
round(avg(discount_percent),2) as avg_discount,
sum(out_of_stock =1 ) as out_of_stock_products,
round(sum(discounted_selling_price * available_quantity),2) as potential_revenue
from zepto_clean
group by category
order by potential_revenue desc ;

-- 18. which highly discounted products have low inventory?
select sku_id,name,category,
available_quantity,
discount_percent
from zepto_clean
where available_quantity<20
and discount_percent>30
order by discount_percent desc ;

-- 19. which products should recieve the highest business priority?
select sku_id,name,category,
available_quantity,
discount_percent,
case
when out_of_Stock =1 and discounted_selling_price>=500
then 'critical'
when available_quantity<10 and discount_percent >=20
then 'high'
when available_quantity<50
then 'medium'
else 'low'
end as business_priority
from zepto_clean
order by 
case 
when out_of_Stock =1 and discounted_selling_price>=500 then 1
when available_quantity<10 and discount_percent >=20 then 2
when available_quantity<50 then 3
else 4
end ;


-- =========================================
-- BUSINESS INSIGHTS
-- =========================================

-- 1. Cooking Essentials and Munchies have the highest potential
--    revenue at ₹3,37,131 each, making them the strongest
--    revenue-potential categories based on current inventory.

-- 2. Personal Care and Paan Corner have the second-highest
--    potential revenue at ₹2,70,849 each, indicating strong
--    revenue potential from their current inventory.

-- 3. Fruits & Vegetables have the highest average discount
--    at 15.46%, indicating relatively aggressive discounting
--    compared with other categories.

-- 4. Borges Extra Light Olive Oil is among the highest-priced
--    products with a selling price of ₹1,399, making it a
--    high-value product in the assortment.

-- 5. Borges Extra Light Olive Oil has the highest absolute
--    discount amount of ₹1,201, showing that high-priced
--    products can have substantial monetary discounts.

-- 6. Dukes Waffy products have the highest discount percentage,
--    reaching 51%, indicating aggressive promotional pricing
--    for these products.

-- 7. Several highly discounted products have very low inventory,
--    creating a potential stock-out risk if inventory is not
--    replenished.

-- 8. Multiple products have zero available inventory, indicating
--    that stock replenishment is an important area for inventory
--    management.

-- 9. Cooking Essentials and Munchies have the highest inventory
--    value at ₹3,37,131 each, indicating that a significant
--    portion of the inventory value is concentrated in these
--    categories.

-- 10. Category-level analysis shows differences in product count,
--     inventory levels and out-of-stock products, suggesting
--     that inventory management should be evaluated category-wise.

-- 11. Discount percentage and absolute discount amount highlight
--     different pricing patterns: Dukes Waffy leads by discount
--     percentage, while Borges Extra Light Olive Oil leads by
--     absolute discount amount.

-- 12. High-priced products with zero or very low inventory should
--     receive closer monitoring because their unavailability may
--     represent greater potential revenue risk.

-- 13. The product assortment includes very low-priced products,
--     with the lowest observed selling price at ₹9, indicating
--     availability of low-ticket products for price-sensitive
--     customers.

-- 14. Potential revenue should not be interpreted as actual sales
--     revenue because the dataset contains inventory and pricing
--     data but does not contain actual order or units-sold data.

 
 
