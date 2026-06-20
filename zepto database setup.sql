-- Zepto Inventory Dataset - Database & Table Setup
-- create database

CREATE DATABASE zepto_SQL_project;

CREATE TABLE zepto1(
    sku_id SERIAL PRIMARY KEY,
    category VARCHAR(120),
    name VARCHAR(150) NOT NULL,
    mrp NUMERIC(8,2),
    discountPercent NUMERIC(5,2),
    availableQuantity INTEGER,
    discountedSellingPrice NUMERIC(8,2),
    weightInGms INTEGER,
    outOfStock VARCHAR(6),
    quantity INTEGER
);
-- Load data (after table creation)
-- Import the CSV via pgAdmin: right-click 
--zepto table -> Import/Export Data-- (Format: csv, Header: Yes, Delimiter: ,)

-- verify the data loaded correctly
SELECT COUNT(*) FROM zepto;
SELECT * FROM zepto LIMIT 10