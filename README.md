# 🛒 Zepto Inventory Analysis | SQL Project

**Turning 3,700+ raw inventory rows into pricing, stock, and revenue decisions — using nothing but SQL.**

Zepto is one of India's fastest-growing quick-commerce platforms, delivering groceries in minutes. Behind every "10-min delivery" promise is an inventory system juggling thousands of SKUs, fluctuating stock, and aggressive discounting. This project digs into that inventory data to answer questions a **category manager or business analyst** would actually ask: *What's driving revenue? What's sitting out of stock? Where are we discounting too much — or too little?*

---

## 📑 Table of Contents
- [Tools Used](#-tools-used)
- [Dataset](#-dataset)
- [Project Structure](#-project-structure)
- [Schema Design](#-schema-design)
- [Project Workflow](#-project-workflow)
- [Data Cleaning & Deduplication](#-data-cleaning--deduplication)
- [Analysis Sections](#-analysis-sections)
- [Key Insights](#-key-insights)
- [Challenges Faced](#-challenges-faced)
- [How to Run This Project](#-how-to-run-this-project)
- [What's Next](#-whats-next)
- [Let's Connect](#-lets-connect)

---

## 🛠 Tools Used

| Tool | Purpose |
|---|---|
| **MySQL 8.0** | Data cleaning, schema design, querying, business logic |
| **VS Code + SQLTools** | Query development & execution environment |

---

## 📦 Dataset

| Detail | Value |
|---|---|
| Source | [Kaggle — Zepto Inventory Dataset](https://www.kaggle.com/datasets/palvinder2006/zepto-inventory-dataset) |
| Raw rows | 3,732 |
| After removing invalid entry | 3,731 |
| After deduplication | 1,675 |
| Columns | 9 |
| Key fields | `name`, `category`, `mrp`, `discountPercent`, `discountedSellingPrice`, `availableQuantity`, `weightInGms`, `outOfStock`, `quantity` |

---

## 📁 Project Structure

```
zepto-inventory-analysis/
│
├── zepto_db_setup.sql            # Table creation, CSV import, category reference data
├── zepto_analysis.sql            # 4 sections · 20 numbered queries (Q1–Q20)
├── sql_schema_overview.png       # Table schema & JOIN relationship
├── sql_dedup_result.png          # Before/after row count (3,731 → 1,675)
├── sql_outofstock_highmrp.png    # High-MRP out-of-stock products
├── sql_revenue_by_category.png   # Revenue ranking by category
├── sql_avg_discount_category.png # Average discount per category
├── sql_join_query_output.png     # Section 4 JOIN query result
└── README.md
```

> **Two-file approach:** Setup is completely separated from analysis — making the project easy to review, reproduce, and extend.

---

## 🗂 Schema Design

```sql
-- Main inventory table
CREATE TABLE zepto (
    sku_id                 SERIAL PRIMARY KEY,
    Category               VARCHAR(120),
    name                   VARCHAR(150) NOT NULL,
    mrp                    NUMERIC(8,2),
    discountPercent        NUMERIC(5,2),
    availableQuantity      INTEGER,
    discountedSellingPrice NUMERIC(8,2),
    weightInGms            INTEGER,
    outOfStock             VARCHAR(6),
    quantity               INTEGER
);

-- Category reference table (enables JOIN-based analysis)
CREATE TABLE category_info (
    category_id        SERIAL PRIMARY KEY,
    category           VARCHAR(120) UNIQUE,
    warehouse_zone     VARCHAR(10),
    category_manager   VARCHAR(60),
    reorder_threshold  INTEGER
);
```

> `zepto_clean` is derived from `zepto` after cleaning and deduplication. `category_info` is a reference/dimension table linking inventory with warehouse and operational metadata — reflecting real-world database design where business context lives in a separate lookup table.

![Schema Overview](sql_schema_overview.png)

---

## 🔄 Project Workflow

```
🔍 Explore → 🧹 Clean → 🏗 Deduplicate → 💡 Analyze → 📊 Insights
```

| Phase | What Happened |
|---|---|
| **Exploration** | Row counts, null audits, category listing, stock-status breakdown, duplicate detection |
| **Cleaning** | Deleted invalid pricing row, converted paise → rupees, created `zepto_clean` |
| **Business Analysis** | Q1–Q16: aggregations, subqueries, CTEs, window functions on `zepto_clean` |
| **JOIN Analysis** | Q17–Q20: INNER JOIN, LEFT JOIN, CASE WHEN, CTE + window function |

---

## 🧹 Data Cleaning & Deduplication

### Issues Found & Fixed

| Issue | Fix |
|---|---|
| 1 row with `mrp = 0` | Deleted |
| Prices stored in paise (e.g. 2500 = ₹25) | Divided by 100 |
| `outOfStock` rejected as boolean | Imported as `VARCHAR(6)`, filtered with `= 'TRUE'` |
| 1,187 products duplicated across category tags | Deduplicated with `ROW_NUMBER()` into `zepto_clean` |

```sql
-- Convert paise → rupees
UPDATE zepto
SET mrp = mrp / 100.0,
    discountedSellingPrice = discountedSellingPrice / 100.0;

-- Create clean deduplicated table for all analysis
CREATE TABLE zepto_clean AS
SELECT sku_id, category, name, mrp,
       discountPercent, availableQuantity,
       discountedSellingPrice, weightInGms, outOfStock
FROM (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY name, category
               ORDER BY sku_id
           ) AS rn
    FROM zepto
) ranked
WHERE rn = 1;
```

### How the Duplicate Bug Was Caught

Early revenue queries returned **identical totals** across unrelated categories — Packaged Food, Ice Cream & Desserts, and Chocolates & Candies all showed the same figure. Rather than accepting it, I wrote a diagnostic query:

```sql
SELECT name, COUNT(DISTINCT category) AS category_count
FROM zepto
GROUP BY name
HAVING category_count > 1
ORDER BY category_count DESC;
```

This revealed **1,187 products duplicated across multiple category labels** — adding 2,057 excess rows. After deduplication: **3,731 → 1,675 rows**. All revenue figures were recalculated from the clean table.

> 💡 This is the kind of data quality bug that goes unnoticed when analysts trust output without questioning it. Catching it required understanding *why* results looked wrong — not just that they did.

![Deduplication Result](sql_dedup_result.png)

---

## 💡 Analysis Sections

`zepto_analysis.sql` contains **4 sections**. Sections 1–2 run on raw `zepto`. Sections 3–4 run on `zepto_clean`.

---

### 📌 Section 1 — Data Exploration (6 Queries)

Initial scan before any analysis. Covers row counts, null checks, category listing, stock breakdown, and duplicate detection.

```sql
-- In-stock vs out-of-stock breakdown
SELECT outOfStock, COUNT(sku_id) AS product_count
FROM zepto GROUP BY outOfStock;

-- Products with multiple SKUs — exposed the duplication problem
SELECT name, COUNT(sku_id) AS sku_count
FROM zepto GROUP BY name
HAVING COUNT(sku_id) > 1 ORDER BY sku_count DESC;
```

---

### 📌 Section 2 — Data Cleaning & Deduplication

Covers `DELETE`, `UPDATE`, CTE-based duplicate identification, and `CREATE TABLE zepto_clean`. Detailed above in the [Data Cleaning](#-data-cleaning--deduplication) section.

---

### 📌 Section 3 — Business Insights (Q1–Q16)

16 queries on `zepto_clean`, ordered by increasing complexity.

<details>
<summary><b>Q1 · Top 10 most-discounted products</b></summary>

```sql
SELECT DISTINCT name, mrp, discountPercent
FROM zepto_clean
ORDER BY discountPercent DESC LIMIT 10;
```
**Finding:** Biscuit/wafer brands (Dukes Waffy) and ready-to-cook kits dominate — all at 50–51% off.
</details>

<details>
<summary><b>Q2 · High-value products currently out of stock</b></summary>

```sql
SELECT DISTINCT name, mrp
FROM zepto_clean
WHERE outOfStock = 'TRUE' AND mrp > 300
ORDER BY mrp DESC;
```
**Finding:** Patanjali Cow's Ghee (₹565), MamyPoko Pants (₹399), Aashirvaad Atta (₹315) — daily essentials — all out of stock.
</details>

![Out of Stock High MRP](sql_outofstock_highmrp.png)

<details>
<summary><b>Q3 · Estimated revenue per category</b></summary>

```sql
SELECT category,
       ROUND(SUM(discountedSellingPrice * availableQuantity), 2) AS estimated_revenue
FROM zepto_clean
GROUP BY category ORDER BY estimated_revenue DESC;
```
**Finding:** Cooking Essentials leads at ₹2,83,472 — nearly **27x** the revenue of Fruits & Vegetables (₹10,378).
</details>

![Revenue by Category](sql_revenue_by_category.png)

<details>
<summary><b>Q5 · Top 5 categories by average discount</b></summary>

```sql
SELECT category, ROUND(AVG(discountPercent), 2) AS avg_discount
FROM zepto_clean
GROUP BY category ORDER BY avg_discount DESC LIMIT 5;
```
**Finding:** Fruits & Vegetables (15.93%) and Meats, Fish & Eggs (9.91%) lead — perishables discounted hardest before spoilage.
</details>

![Average Discount by Category](sql_avg_discount_category.png)

<details>
<summary><b>Q10 · Top 3 best-deal products per category (DENSE_RANK)</b></summary>

```sql
WITH category_ranked AS (
    SELECT name, category, discountPercent,
           DENSE_RANK() OVER (
               PARTITION BY category ORDER BY discountPercent DESC
           ) AS rnk
    FROM zepto_clean
)
SELECT name, category, discountPercent, rnk
FROM category_ranked WHERE rnk <= 3
ORDER BY category, rnk;
```
**Finding:** Powers a "Best Deals per Category" display — real feature logic, not just a query exercise.
</details>

<details>
<summary><b>Q16 · Full category performance dashboard (CTE + RANK)</b></summary>

```sql
WITH category_summary AS (
    SELECT category,
        COUNT(DISTINCT name)                                       AS unique_products,
        ROUND(AVG(discountPercent), 2)                            AS avg_discount_pct,
        ROUND(AVG(mrp), 2)                                        AS avg_mrp,
        ROUND(SUM(discountedSellingPrice * availableQuantity), 2) AS total_revenue,
        SUM(CASE WHEN outOfStock = 'TRUE'  THEN 1 ELSE 0 END)    AS out_of_stock_count,
        SUM(CASE WHEN outOfStock = 'FALSE' THEN 1 ELSE 0 END)    AS in_stock_count
    FROM zepto_clean GROUP BY category
)
SELECT *, RANK() OVER (ORDER BY total_revenue DESC) AS revenue_rank
FROM category_summary ORDER BY revenue_rank;
```
**Finding:** One query delivers the full management view — revenue rank, stockout count, avg MRP, and discount % per category.
</details>

> 📂 All 16 queries (Q1–Q16) including window functions `RANK`, `DENSE_RANK`, `ROW_NUMBER`, cumulative revenue, correlated subqueries, CTEs, and `CASE WHEN` are in `zepto_analysis.sql` Section 3.

---

### 📌 Section 4 — Multi-Table Analysis / JOINs (Q17–Q20)

Uses `category_info` to link inventory data with warehouse zone, category manager, and reorder threshold.

<details>
<summary><b>Q17 · INNER JOIN — Revenue per category with manager & zone</b></summary>

```sql
SELECT ci.category, ci.category_manager, ci.warehouse_zone,
       ROUND(SUM(z.discountedSellingPrice * z.availableQuantity), 2) AS total_revenue
FROM zepto_clean z
INNER JOIN category_info ci ON z.category = ci.category
GROUP BY ci.category, ci.category_manager, ci.warehouse_zone
ORDER BY total_revenue DESC;
```
**Finding:** Maps revenue accountability directly to category managers and zones — real operations reporting logic.
</details>

<details>
<summary><b>Q18 · LEFT JOIN — Detect categories missing from master table</b></summary>

```sql
SELECT z.category, ci.category_manager, ci.warehouse_zone,
       COUNT(z.sku_id) AS total_skus,
       ROUND(AVG(z.discountPercent), 2) AS avg_discount
FROM zepto_clean z
LEFT JOIN category_info ci ON z.category = ci.category
GROUP BY z.category, ci.category_manager, ci.warehouse_zone
ORDER BY total_skus DESC;
```
**Finding:** NULL values in manager/zone columns expose data gaps in the reference table — a data completeness check.
</details>

<details>
<summary><b>Q19 · JOIN + CASE WHEN — Automated restock alert</b></summary>

```sql
SELECT ci.category, ci.category_manager, ci.warehouse_zone,
       ci.reorder_threshold, SUM(z.availableQuantity) AS current_inventory,
       CASE
           WHEN SUM(z.availableQuantity) < ci.reorder_threshold       THEN 'RESTOCK NOW'
           WHEN SUM(z.availableQuantity) < ci.reorder_threshold * 1.5 THEN 'LOW STOCK'
           ELSE 'SUFFICIENT'
       END AS stock_status
FROM zepto_clean z
INNER JOIN category_info ci ON z.category = ci.category
GROUP BY ci.category, ci.category_manager, ci.warehouse_zone, ci.reorder_threshold
ORDER BY current_inventory ASC;
```
**Finding:** Outputs an actionable RESTOCK NOW / LOW STOCK / SUFFICIENT status per category — operations-ready logic.
</details>

<details>
<summary><b>Q20 · JOIN + CTE + Window Function — Top revenue category per warehouse zone</b></summary>

```sql
WITH zone_revenue AS (
    SELECT ci.warehouse_zone, ci.category, ci.category_manager,
           ROUND(SUM(z.discountedSellingPrice * z.availableQuantity), 2) AS revenue
    FROM zepto_clean z
    INNER JOIN category_info ci ON z.category = ci.category
    GROUP BY ci.warehouse_zone, ci.category, ci.category_manager
)
SELECT warehouse_zone, category, category_manager, revenue,
       RANK() OVER (PARTITION BY warehouse_zone ORDER BY revenue DESC) AS rank_within_zone
FROM zone_revenue
ORDER BY warehouse_zone, rank_within_zone;
```
**Finding:** Zone managers can instantly see which category drives the most revenue in their zone — combines JOIN, CTE, and window function in one query.
</details>

![JOIN Query Output](sql_join_query_output.png)

---

## 🔑 Key Insights

> 🏆 **Cooking Essentials** is Zepto's revenue powerhouse — estimated **₹2,83,472**, nearly 27x the revenue of Fruits & Vegetables.

> 🥦 **Perishables get discounted hardest.** Fruits & Vegetables (15.93% avg discount) and Meats, Fish & Eggs (9.91%) top the discount charts — a classic "sell before it spoils" strategy.

> 📉 **Stockouts hitting high-value staples.** Ghee, atta, and chilli powder — daily essentials at ₹300+ MRP — found out of stock. These are the SKUs that should never run dry.

> 🔍 **Caught and fixed a critical data quality bug.** Identical revenue totals across unrelated categories led to discovering 1,187 products duplicated across multiple category tags — 2,057 excess rows. After deduplication, dataset dropped from 3,731 → 1,675 rows and all figures were recalculated.

> 🗂 **JOINs unlocked operational insights.** Building `category_info` and writing JOIN queries revealed warehouse zone revenue distribution, category manager stockout accountability, and automated restock alerts — context that single-table queries simply can't provide.

---

## 🧩 Challenges Faced

**Boolean import error:** MySQL rejected `outOfStock` as a true boolean during CSV import. Fixed by importing as `VARCHAR(6)` and filtering with string comparison (`= 'TRUE'`).

**Hidden duplicate bug:** Early revenue queries returned identical totals for unrelated categories. Traced the issue to 1,187 products carrying multiple category labels — required writing diagnostic queries before trusting any business conclusion.

**Deduplication logic correction:** Initial `ROW_NUMBER()` partitioned by `name` only, which was incorrect. Corrected to `PARTITION BY name, category` to properly handle products legitimately appearing across different categories.

---

## ▶️ How to Run This Project

**Step 1 — Clone the repo**
```bash
git clone https://github.com/SunainaSingh56/zepto-inventory-analysis.git
```

**Step 2 — Create the database (MySQL client)**
```sql
CREATE DATABASE zepto_project;
USE zepto_project;
```

**Step 3 — Run setup file** *(run once — creates tables, load CSV, inserts reference data)*
```sql
SOURCE zepto_db_setup.sql;
```

**Step 4 — Import CSV into `zepto` table**, then run analysis:
```sql
SOURCE zepto_analysis.sql;
```

> Requires MySQL 8.0+ · VS Code with SQLTools, MySQL Workbench, or any MySQL client

---

## 🚀 What's Next

- [ ] Power BI dashboard built on top of `zepto_clean` findings
- [ ] Expand `category_info` with real margin and shelf-life data for deeper JOIN analysis
- [ ] Wrap cleaning + deduplication into a reusable stored procedure

---

## 🤝 Let's Connect

📌 **GitHub:** [SunainaSingh56](https://github.com/SunainaSingh56)
📌 **LinkedIn:** [Sunaina Singh](https://www.linkedin.com/in/sunainasingh56)

*Found this useful? A ⭐ on the repo goes a long way!*
