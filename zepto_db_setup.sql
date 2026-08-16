-- ============================================================
-- ZEPTO INVENTORY ANALYSIS — DATABASE SETUP
-- Author   : Sunaina Singh
-- File     : zepto_db_setup.sql
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
-- =====================================================
-- STEP 3 : CREATE CATEGORY REFERENCE TABLE
-- =====================================================
CREATE TABLE category_info(
    category_id        SERIAL PRIMARY KEY,
    category           VARCHAR(120) UNIQUE,
    warehouse_zone     VARCHAR(10),
    category_manager   VARCHAR(60),
    reorder_threshold  INTEGER      
);

INSERT INTO category_info (category, warehouse_zone, category_manager, reorder_threshold) VALUES
('Cooking Essentials',    'Zone A', 'Kavita Sharma',  800),
('Munchies',              'Zone B', 'Arjun Kapoor',   600),
('Packaged Food',         'Zone A', 'Suresh Pandey',  500),
('Ice Cream & Desserts',  'Zone C', 'Pooja Mehta',    300),
('Chocolates & Candies',  'Zone B', 'Rahul Gupta',    400),
('Personal Care',         'Zone C', 'Neha Joshi',     300),
('Paan Corner',           'Zone B', 'Rohit Sinha',    200),
('Home & Cleaning',       'Zone C', 'Anita Dubey',    150),
('Biscuits',              'Zone B', 'Manoj Tiwari',   200),
('Dairy, Bread & Batter', 'Zone A', 'Ravi Sharma',    400),
('Beverages',             'Zone B', 'Sneha Iyer',     250),
('Health & Hygiene',      'Zone C', 'Vikram Singh',   150),
('Fruits & Vegetables',   'Zone A', 'Deepa Rao',      500),
('Meats, Fish & Eggs',    'Zone A', 'Anil Verma',     300);

-- Verify both tables loaded correctly
SELECT COUNT(*) AS zepto_rows        FROM zepto;
SELECT COUNT(*) AS category_info_rows FROM category_info;

-- ============================================================
-- Setup complete. Run zepto_analysis.sql for full analysis.
-- ============================================================