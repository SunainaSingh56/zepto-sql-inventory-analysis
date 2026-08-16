-- ============================================================
-- ZEPTO INVENTORY ANALYSIS — QUERIES
-- Author   : Sunaina Singh
-- File     : zepto_analysis.sql
-- Skills   : Data Exploration · Data Cleaning · Deduplication ·
--            Aggregations · Subqueries · CTEs ·
--            Window Functions · JOINs
-- ============================================================


-- =====================================================
-- SECTION 1 : DATA EXPLORATION
-- =====================================================

-- Total row count
SELECT COUNT(*) AS total_rows
FROM zepto;


-- Sample records
SELECT *
FROM zepto
LIMIT 10;

-- NULL check across all columns
SELECT *
FROM zepto
WHERE category              IS NULL
   OR name                  IS NULL
   OR mrp                   IS NULL
   OR discountPercent        IS NULL
   OR availableQuantity      IS NULL
   OR discountedSellingPrice IS NULL
   OR weightInGms            IS NULL
   OR outOfStock             IS NULL
   OR quantity               IS NULL;

-- All distinct product categories
SELECT DISTINCT category
FROM zepto
ORDER BY category;

-- In-stock vs out-of-stock product count
SELECT outOfStock,
       COUNT(sku_id) AS product_count
FROM zepto
GROUP BY outOfStock;

-- Products appearing with multiple SKU IDs under the same name
-- This query revealed the duplication problem in the dataset
SELECT name,
       COUNT(sku_id) AS sku_count
FROM zepto
GROUP BY name
HAVING COUNT(sku_id) > 1
ORDER BY sku_count DESC;


-- =====================================================
-- SECTION 2 : DATA CLEANING & DEDUPLICATION
-- =====================================================

-- Identify records where price is 0 (invalid / corrupt data)
SELECT *
FROM zepto
WHERE mrp = 0
   OR discountedSellingPrice = 0;

-- Delete rows where MRP = 0
DELETE FROM zepto
WHERE mrp = 0;

-- Convert prices from paise to rupees
-- Raw dataset stores values in paise (e.g. 5000 = ₹50.00)
UPDATE zepto
SET mrp = mrp / 100.0,
    discountedSellingPrice = discountedSellingPrice / 100.0;

-- Verify price conversion
SELECT mrp, discountedSellingPrice
FROM zepto
LIMIT 10;

-- Identify all duplicate rows
-- Same product name + category appearing with different SKU IDs
WITH duplicate_check AS (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY name, category
               ORDER BY sku_id
           ) AS rn
    FROM zepto
)
SELECT *
FROM duplicate_check
WHERE rn > 1;

-- Final clean dataset — 1 unique row per product
WITH deduplicated AS (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY name, category
               ORDER BY sku_id
           ) AS rn
    FROM zepto
)
SELECT sku_id, category, name, mrp,
       discountPercent, availableQuantity,
       discountedSellingPrice, weightInGms, outOfStock
FROM deduplicated
WHERE rn = 1;

-- Store deduplicated result as a permanent clean table
-- All Section 3 and Section 4 analysis runs on zepto_clean
-- Pehle galat table drop karo
DROP TABLE zepto_clean;

-- Sahi partitioning se banao
CREATE TABLE zepto_clean AS
SELECT sku_id, category, name, mrp,
       discountPercent, availableQuantity,
       discountedSellingPrice, weightInGms, outOfStock
FROM (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY name
               ORDER BY sku_id
           ) AS rn
    FROM zepto
) ranked
WHERE rn = 1;

-- Verify
SELECT COUNT(*) AS before_dedup FROM zepto;
SELECT COUNT(*) AS after_dedup FROM zepto_clean;

-- KEY FINDING:
-- Original dataset    : 3,732 rows
-- After deduplication : 1,675 unique products
-- 2,057 duplicate SKUs removed — ~55% of raw data was redundant
-- Not mentioned in dataset description — discovered independently during cleaning.


-- =====================================================
-- SECTION 3 : BUSINESS INSIGHTS & ANALYSIS
-- =====================================================
-- Queries ordered by increasing complexity.
-- Every query answers a real business question.
-- =====================================================

-- Q1 : Top 10 products with the highest discount percentage
SELECT DISTINCT name, mrp, discountPercent
FROM zepto_clean
ORDER BY discountPercent DESC
LIMIT 10;

-- Q2 : High-value products currently out of stock
--      Restocking these first protects the most revenue
SELECT DISTINCT name, mrp
FROM zepto_clean
WHERE outOfStock = 'TRUE'
  AND mrp > 300
ORDER BY mrp DESC;

-- Q3 : Estimated revenue potential per category
--      Revenue = discounted selling price × available quantity
SELECT category,
       ROUND(SUM(discountedSellingPrice * availableQuantity), 2) AS estimated_revenue
FROM zepto_clean
GROUP BY category
ORDER BY estimated_revenue DESC;

-- Q4 : Premium products with low discount (below 10%)
--      High MRP + low discount = strong candidates for a promotional push
SELECT DISTINCT name, mrp, discountPercent
FROM zepto_clean
WHERE mrp > 500
  AND discountPercent < 10
ORDER BY mrp DESC;

-- Q5 : Top 5 categories by average discount
--      Shows which categories are most price-competitive
SELECT category,
       ROUND(AVG(discountPercent), 2) AS avg_discount
FROM zepto_clean
GROUP BY category
ORDER BY avg_discount DESC
LIMIT 5;

-- Q6 : Price per gram for products weighing 100g or more
--      In quick commerce, weight-adjusted value drives repeat purchases
SELECT DISTINCT name, weightInGms, discountedSellingPrice,
       ROUND(discountedSellingPrice / weightInGms, 2) AS price_per_gram
FROM zepto_clean
WHERE weightInGms >= 100
ORDER BY price_per_gram ASC;

-- Q7 : Product weight segmentation — Low / Medium / Bulk
--      Supports delivery slot planning and packaging decisions
SELECT DISTINCT name, weightInGms,
    CASE
        WHEN weightInGms < 1000 THEN 'Low'
        WHEN weightInGms < 5000 THEN 'Medium'
        ELSE 'Bulk'
    END AS weight_category
FROM zepto_clean
ORDER BY weightInGms;

-- Q8 : Total inventory weight per category
--      Helps warehouse team plan storage and logistics capacity
SELECT category,
       SUM(weightInGms * availableQuantity) AS total_inventory_weight_gms
FROM zepto_clean
GROUP BY category
ORDER BY total_inventory_weight_gms DESC;

-- Q9 : Rank products by MRP within each category
--      Identifies the premium tier of products in every category
SELECT name, category, mrp,
       RANK() OVER (
           PARTITION BY category
           ORDER BY mrp DESC
       ) AS mrp_rank
FROM zepto_clean
ORDER BY category, mrp_rank;

-- Q10 : Top 3 best-deal products per category by discount
--       Used for homepage "Best Deals" display per category
WITH category_ranked AS (
    SELECT name, category, discountPercent,
           DENSE_RANK() OVER (
               PARTITION BY category
               ORDER BY discountPercent DESC
           ) AS rnk
    FROM zepto_clean
)
SELECT name, category, discountPercent, rnk
FROM category_ranked
WHERE rnk <= 3
ORDER BY category, rnk;

-- Q11 : Each product's MRP vs its category average
--       Positive diff → overpriced relative to category
--       Negative diff → affordable relative to category
SELECT name, category, mrp,
       ROUND(AVG(mrp) OVER (PARTITION BY category), 2)       AS category_avg_mrp,
       ROUND(mrp - AVG(mrp) OVER (PARTITION BY category), 2) AS diff_from_avg
FROM zepto_clean
ORDER BY category, diff_from_avg DESC;

-- Q12 : Cumulative revenue contribution by category
--       Answers: how many categories together drive 80% of total revenue?
WITH revenue_by_category AS (
    SELECT category,
           ROUND(SUM(discountedSellingPrice * availableQuantity), 2) AS category_revenue
    FROM zepto_clean
    GROUP BY category
)
SELECT category,
       category_revenue,
       ROUND(SUM(category_revenue) OVER (
           ORDER BY category_revenue DESC
       ), 2) AS cumulative_revenue
FROM revenue_by_category
ORDER BY category_revenue DESC;

-- Q13 : Categories offering above-average discounts
--       Pinpoints which categories are discounting more than market average
SELECT category,
       ROUND(AVG(discountPercent), 2) AS avg_discount
FROM zepto_clean
GROUP BY category
HAVING AVG(discountPercent) > (
    SELECT AVG(discountPercent) FROM zepto_clean
)
ORDER BY avg_discount DESC;

-- Q14 : Products priced above their own category's average MRP
--       Flags premium-positioned products within each category
SELECT name, category, mrp
FROM zepto_clean z1
WHERE mrp > (
    SELECT AVG(mrp)
    FROM zepto_clean z2
    WHERE z2.category = z1.category
)
ORDER BY category, mrp DESC;

-- Q15 : Flash sale candidates — in-stock, high MRP, low discount
--       Marketing team can directly target these for next promotion
WITH promo_candidates AS (
    SELECT name, category, mrp,
           discountPercent, discountedSellingPrice,
           availableQuantity
    FROM zepto_clean
    WHERE outOfStock      = 'FALSE'
      AND mrp             > 200
      AND discountPercent < 20
)
SELECT *
FROM promo_candidates
ORDER BY mrp DESC;

-- Q16 : Complete category performance dashboard
--       One query — full business overview per category with revenue rank
WITH category_summary AS (
    SELECT
        category,
        COUNT(DISTINCT name)                                       AS unique_products,
        ROUND(AVG(discountPercent), 2)                            AS avg_discount_pct,
        ROUND(AVG(mrp), 2)                                        AS avg_mrp,
        ROUND(SUM(discountedSellingPrice * availableQuantity), 2) AS total_revenue,
        SUM(CASE WHEN outOfStock = 'TRUE'  THEN 1 ELSE 0 END)    AS out_of_stock_count,
        SUM(CASE WHEN outOfStock = 'FALSE' THEN 1 ELSE 0 END)    AS in_stock_count
    FROM zepto_clean
    GROUP BY category
)
SELECT *,
       RANK() OVER (ORDER BY total_revenue DESC) AS revenue_rank
FROM category_summary
ORDER BY revenue_rank;


-- =====================================================
-- SECTION 4 : MULTI-TABLE ANALYSIS (JOINs)
-- =====================================================

-- Q17 : INNER JOIN — Revenue per category with manager and zone
SELECT ci.category,
       ci.category_manager,
       ci.warehouse_zone,
       ROUND(SUM(z.discountedSellingPrice * z.availableQuantity), 2) AS total_revenue
FROM zepto_clean z
INNER JOIN category_info ci
        ON z.category = ci.category
GROUP BY ci.category, ci.category_manager, ci.warehouse_zone
ORDER BY total_revenue DESC;

-- Q18 : LEFT JOIN — Detect categories missing from the master table
--       NULL values in manager/zone = data gap that needs fixing
SELECT z.category,
       ci.category_manager,
       ci.warehouse_zone,
       COUNT(z.sku_id)                  AS total_skus,
       ROUND(AVG(z.discountPercent), 2) AS avg_discount
FROM zepto_clean z
LEFT JOIN category_info ci
       ON z.category = ci.category
GROUP BY z.category, ci.category_manager, ci.warehouse_zone
ORDER BY total_skus DESC;

-- Q19 : JOIN + CASE WHEN — Automated restock alert per category
--       Operations team gets actionable status: RESTOCK NOW / LOW STOCK / SUFFICIENT
SELECT ci.category,
       ci.category_manager,
       ci.warehouse_zone,
       ci.reorder_threshold,
       SUM(z.availableQuantity) AS current_inventory,
       CASE
           WHEN SUM(z.availableQuantity) < ci.reorder_threshold       THEN 'RESTOCK NOW'
           WHEN SUM(z.availableQuantity) < ci.reorder_threshold * 1.5 THEN 'LOW STOCK'
           ELSE 'SUFFICIENT'
       END AS stock_status
FROM zepto_clean z
INNER JOIN category_info ci
        ON z.category = ci.category
GROUP BY ci.category, ci.category_manager, ci.warehouse_zone, ci.reorder_threshold
ORDER BY current_inventory ASC;

-- Q20 : JOIN + CTE + Window Function — Top revenue category per warehouse zone
--       Zone managers can see which category drives most revenue in their zone
WITH zone_revenue AS (
    SELECT ci.warehouse_zone,
           ci.category,
           ci.category_manager,
           ROUND(SUM(z.discountedSellingPrice * z.availableQuantity), 2) AS revenue
    FROM zepto_clean z
    INNER JOIN category_info ci
            ON z.category = ci.category
    GROUP BY ci.warehouse_zone, ci.category, ci.category_manager
)
SELECT warehouse_zone,
       category,
       category_manager,
       revenue,
       RANK() OVER (
           PARTITION BY warehouse_zone
           ORDER BY revenue DESC
       ) AS rank_within_zone
FROM zone_revenue
ORDER BY warehouse_zone, rank_within_zone;


-- ============================================================
-- END OF PROJECT
-- GitHub   : github.com/SunainaSingh56
-- LinkedIn : linkedin.com/in/sunainasingh56
-- ============================================================