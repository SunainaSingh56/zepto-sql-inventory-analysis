-- ============================================================
-- ZEPTO INVENTORY ANALYSIS — DATABASE SETUP
-- Author   : Sunaina Singh
-- File     : zepto_setup.sql
-- Purpose  : Database creation, table schema, and reference
--            data. Run this file ONCE before running analysis.
-- ============================================================


-- =====================================================
-- STEP 1 : CREATE DATABASE
-- =====================================================

CREATE DATABASE zepto_project;

USE zepto_project;             -- MySQL


-- =====================================================
-- STEP 2 : CREATE MAIN PRODUCT TABLE
-- =====================================================

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

-- Load data from CSV:
-- pgAdmin → Right-click zepto table → Import/Export Data
-- Format: CSV | Header: Yes | Delimiter: ,
-- Dataset source: kaggle.com/datasets/pallavikharbanda/zepto-products


-- =====================================================
-- STEP 3 : CREATE CATEGORY REFERENCE TABLE
-- =====================================================
-- In real systems, a category master table tracks warehouse
-- zone, assigned manager, and reorder threshold per category.
-- This is a dimension table — maintained manually via INSERT.
-- The zepto table (3,732 rows) uses CSV import.
-- This table (15 rows) uses INSERT — standard for small
-- reference/lookup tables in any real-world database.

CREATE TABLE category_info(
    category_id        SERIAL PRIMARY KEY,
    category           VARCHAR(120) UNIQUE,
    warehouse_zone     VARCHAR(10),
    category_manager   VARCHAR(60),
    reorder_threshold  INTEGER       -- minimum units before restocking alert
);

INSERT INTO category_info (category, warehouse_zone, category_manager, reorder_threshold) VALUES
('Fruits & Vegetables',          'Zone A', 'Ravi Sharma',    500),
('Dairy & Breakfast',            'Zone A', 'Pooja Mehta',    400),
('Snacks & Munchies',            'Zone B', 'Arjun Kapoor',   300),
('Beverages',                    'Zone B', 'Sneha Iyer',     250),
('Bakery & Biscuits',            'Zone B', 'Rahul Gupta',    200),
('Personal Care',                'Zone C', 'Neha Joshi',     150),
('Home Care',                    'Zone C', 'Vikram Singh',   100),
('Baby Care',                    'Zone C', 'Priya Nair',      80),
('Eggs, Meat & Fish',            'Zone A', 'Anil Verma',     300),
('Tea, Coffee & Health Drinks',  'Zone B', 'Deepa Rao',      200),
('Atta, Rice & Dal',             'Zone A', 'Suresh Pandey',  600),
('Oils & Ghee',                  'Zone A', 'Kavita Sharma',  350),
('Dry Fruits & Nuts',            'Zone B', 'Manoj Tiwari',   180),
('Cleaning & Household',         'Zone C', 'Anita Dubey',    120),
('Paan Corner',                  'Zone B', 'Rohit Sinha',     50);

-- Verify both tables loaded correctly
SELECT COUNT(*) AS zepto_rows        FROM zepto;
SELECT COUNT(*) AS category_info_rows FROM category_info;

-- ============================================================
-- Setup complete. Run zepto_analysis.sql for full analysis.
-- ============================================================
