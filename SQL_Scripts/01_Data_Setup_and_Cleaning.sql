-- ============================================================
-- FILE 1: DATA SETUP & CLEANING
-- Zepto Dark Store Inventory Analysis
-- ============================================================


-- ------------------------------------------------------------
-- TABLE CREATION
-- ------------------------------------------------------------

DROP TABLE IF EXISTS PRODUCT_LEVEL_INVENTORY;

CREATE TABLE PRODUCT_LEVEL_INVENTORY (
    CATEGORY               VARCHAR(100) NOT NULL,
    PRODUCT                VARCHAR(100) NOT NULL,  -- renamed from NAME at schema level
    MRP                    INT          NOT NULL,
    DISCOUNT_PERCENT       INT          NOT NULL,
    AVAILABLE_QUANTITY     INT          NOT NULL,
    DISCOUNTED_SELLING_PRICE INT        NOT NULL,
    WEIGHT_IN_GMS          INT          NOT NULL,
    OUT_OF_STOCK           BOOLEAN      NOT NULL   -- fixed: was VARCHAR(50) storing 'TRUE'/'FALSE'
);


-- ------------------------------------------------------------
-- DATA LOAD
-- Update the path below to your local CSV location
-- ------------------------------------------------------------

COPY PRODUCT_LEVEL_INVENTORY (
    CATEGORY,
    PRODUCT,
    MRP,
    DISCOUNT_PERCENT,
    AVAILABLE_QUANTITY,
    DISCOUNTED_SELLING_PRICE,
    WEIGHT_IN_GMS,
    OUT_OF_STOCK
)
FROM '/path/to/zepto_v2.csv'   -- replace with your actual path
DELIMITER ',' CSV HEADER;


-- ------------------------------------------------------------
-- SANITY CHECKS — run after load to verify data integrity
-- ------------------------------------------------------------

-- Row count
SELECT COUNT(*) AS TOTAL_ROWS FROM PRODUCT_LEVEL_INVENTORY;

-- Preview
SELECT * FROM PRODUCT_LEVEL_INVENTORY LIMIT 10;

-- Distinct categories
SELECT DISTINCT CATEGORY FROM PRODUCT_LEVEL_INVENTORY ORDER BY CATEGORY;

-- Products per category
SELECT
    CATEGORY,
    COUNT(*) AS TOTAL_PRODUCTS
FROM PRODUCT_LEVEL_INVENTORY
GROUP BY CATEGORY
ORDER BY TOTAL_PRODUCTS DESC;


-- ------------------------------------------------------------
-- DATA QUALITY CHECKS
-- ------------------------------------------------------------

-- Null / invalid value audit
SELECT
    SUM(CASE WHEN PRODUCT IS NULL OR TRIM(PRODUCT) = ''   THEN 1 ELSE 0 END) AS NULL_OR_BLANK_PRODUCT,
    SUM(CASE WHEN MRP < 0                                 THEN 1 ELSE 0 END) AS NEGATIVE_MRP_COUNT,
    SUM(CASE WHEN DISCOUNTED_SELLING_PRICE < 0            THEN 1 ELSE 0 END) AS NEGATIVE_PRICE_COUNT,
    SUM(CASE WHEN AVAILABLE_QUANTITY < 0                  THEN 1 ELSE 0 END) AS NEGATIVE_STOCK_COUNT,
    SUM(CASE WHEN WEIGHT_IN_GMS < 0                       THEN 1 ELSE 0 END) AS NEGATIVE_WEIGHT_COUNT,
    SUM(CASE WHEN DISCOUNT_PERCENT NOT BETWEEN 0 AND 100  THEN 1 ELSE 0 END) AS INVALID_DISCOUNT_COUNT
FROM PRODUCT_LEVEL_INVENTORY;

-- Zero-weight records (affects price-per-gram analysis downstream)
SELECT COUNT(*) AS ZERO_WEIGHT_RECORDS
FROM PRODUCT_LEVEL_INVENTORY
WHERE WEIGHT_IN_GMS = 0;

-- Verify discount math: discounted price should be <= MRP
SELECT COUNT(*) AS PRICE_EXCEEDS_MRP
FROM PRODUCT_LEVEL_INVENTORY
WHERE DISCOUNTED_SELLING_PRICE > MRP;


-- ------------------------------------------------------------
-- BASIC CATALOG EXPLORATION
-- ------------------------------------------------------------

-- Top 10 highest MRP products
SELECT PRODUCT, CATEGORY, MRP
FROM PRODUCT_LEVEL_INVENTORY
ORDER BY MRP DESC
LIMIT 10;

-- Top 10 lowest discounted price products
SELECT PRODUCT, CATEGORY, DISCOUNTED_SELLING_PRICE
FROM PRODUCT_LEVEL_INVENTORY
ORDER BY DISCOUNTED_SELLING_PRICE ASC
LIMIT 10;

-- Average MRP per category
SELECT
    CATEGORY,
    ROUND(AVG(MRP), 2) AS AVG_MRP
FROM PRODUCT_LEVEL_INVENTORY
GROUP BY CATEGORY
ORDER BY AVG_MRP DESC;


-- ------------------------------------------------------------
-- STOCK STATUS
-- ------------------------------------------------------------

-- Out-of-stock count per category
SELECT
    CATEGORY,
    COUNT(*) AS OUT_OF_STOCK_COUNT
FROM PRODUCT_LEVEL_INVENTORY
WHERE OUT_OF_STOCK = TRUE
GROUP BY CATEGORY
ORDER BY OUT_OF_STOCK_COUNT DESC;

-- Products with critically low stock (< 5 units, still in stock)
SELECT PRODUCT, CATEGORY, AVAILABLE_QUANTITY
FROM PRODUCT_LEVEL_INVENTORY
WHERE AVAILABLE_QUANTITY < 5
  AND OUT_OF_STOCK = FALSE
ORDER BY AVAILABLE_QUANTITY ASC;

-- Overall out-of-stock rate
SELECT
    ROUND(
        SUM(CASE WHEN OUT_OF_STOCK = TRUE THEN 1 ELSE 0 END) * 100.0 / COUNT(*),
        2
    ) AS OUT_OF_STOCK_RATE_PCT
FROM PRODUCT_LEVEL_INVENTORY;


-- ------------------------------------------------------------
-- DISCOUNT OVERVIEW
-- ------------------------------------------------------------

-- Products with discount above 20%
SELECT CATEGORY, PRODUCT, DISCOUNT_PERCENT
FROM PRODUCT_LEVEL_INVENTORY
WHERE DISCOUNT_PERCENT > 20           -- fixed: was incorrectly "> 21"
ORDER BY DISCOUNT_PERCENT DESC;

-- Average discount per category
SELECT
    CATEGORY,
    ROUND(AVG(DISCOUNT_PERCENT), 2) AS AVG_DISCOUNT_PCT
FROM PRODUCT_LEVEL_INVENTORY
GROUP BY CATEGORY
ORDER BY AVG_DISCOUNT_PCT DESC;

-- Single highest-discounted product
SELECT PRODUCT, CATEGORY, DISCOUNT_PERCENT
FROM PRODUCT_LEVEL_INVENTORY
ORDER BY DISCOUNT_PERCENT DESC
LIMIT 1;
