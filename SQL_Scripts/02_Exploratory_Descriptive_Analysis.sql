-- ============================================================
-- FILE 2: EXPLORATORY & DESCRIPTIVE ANALYSIS
-- Zepto Dark Store Inventory Analysis
-- ============================================================


-- ------------------------------------------------------------
-- REVENUE SIMULATION
-- Using AVAILABLE_QUANTITY to reflect actual sellable stock
-- ------------------------------------------------------------

-- Total potential revenue across all in-stock products
SELECT
    SUM(DISCOUNTED_SELLING_PRICE * AVAILABLE_QUANTITY) AS TOTAL_POTENTIAL_REVENUE  -- fixed: was SUM(MRP) with no quantity
FROM PRODUCT_LEVEL_INVENTORY
WHERE OUT_OF_STOCK = FALSE;

-- Potential revenue per category
SELECT
    CATEGORY,
    SUM(DISCOUNTED_SELLING_PRICE * AVAILABLE_QUANTITY) AS CATEGORY_POTENTIAL_REVENUE
FROM PRODUCT_LEVEL_INVENTORY
WHERE OUT_OF_STOCK = FALSE
GROUP BY CATEGORY
ORDER BY CATEGORY_POTENTIAL_REVENUE DESC;

-- Top 5 revenue-generating categories
SELECT
    CATEGORY,
    SUM(DISCOUNTED_SELLING_PRICE * AVAILABLE_QUANTITY) AS CATEGORY_POTENTIAL_REVENUE
FROM PRODUCT_LEVEL_INVENTORY
WHERE OUT_OF_STOCK = FALSE
GROUP BY CATEGORY
ORDER BY CATEGORY_POTENTIAL_REVENUE DESC
LIMIT 5;

-- Top 20 revenue-generating products
SELECT
    PRODUCT,
    CATEGORY,
    DISCOUNTED_SELLING_PRICE * AVAILABLE_QUANTITY AS PRODUCT_POTENTIAL_REVENUE
FROM PRODUCT_LEVEL_INVENTORY
WHERE OUT_OF_STOCK = FALSE
ORDER BY PRODUCT_POTENTIAL_REVENUE DESC
LIMIT 20;


-- ------------------------------------------------------------
-- PROFIT SIMULATION
-- Assumption: COGS = 70% of MRP → Gross Margin = 30%
-- ------------------------------------------------------------

-- Estimated gross profit per product (computed inline — no schema mutation)
SELECT
    PRODUCT,
    CATEGORY,
    MRP,
    AVAILABLE_QUANTITY,
    ROUND(MRP * 0.30, 2)                            AS UNIT_PROFIT_MARGIN,
    ROUND(MRP * 0.30 * AVAILABLE_QUANTITY, 2)       AS TOTAL_STOCK_PROFIT   -- fixed: was ignoring quantity
FROM PRODUCT_LEVEL_INVENTORY
WHERE OUT_OF_STOCK = FALSE
ORDER BY TOTAL_STOCK_PROFIT DESC;

-- Category-wise gross profit
SELECT
    CATEGORY,
    ROUND(SUM(MRP * 0.30 * AVAILABLE_QUANTITY), 2) AS CATEGORY_GROSS_PROFIT
FROM PRODUCT_LEVEL_INVENTORY
WHERE OUT_OF_STOCK = FALSE
GROUP BY CATEGORY
ORDER BY CATEGORY_GROSS_PROFIT DESC;


-- ------------------------------------------------------------
-- DISCOUNT IMPACT ANALYSIS
-- ------------------------------------------------------------

-- Average MRP vs average discount per category side by side
SELECT
    CATEGORY,
    ROUND(AVG(MRP), 2)              AS AVG_MRP,
    ROUND(AVG(DISCOUNT_PERCENT), 2) AS AVG_DISCOUNT_PCT,
    ROUND(AVG(DISCOUNTED_SELLING_PRICE), 2) AS AVG_SELLING_PRICE
FROM PRODUCT_LEVEL_INVENTORY
GROUP BY CATEGORY
ORDER BY AVG_DISCOUNT_PCT DESC;

-- Category with the single highest average discount
SELECT
    CATEGORY,
    ROUND(AVG(DISCOUNT_PERCENT), 2) AS AVG_DISCOUNT_PCT
FROM PRODUCT_LEVEL_INVENTORY
GROUP BY CATEGORY
ORDER BY AVG_DISCOUNT_PCT DESC
LIMIT 1;

-- Discount vs stock correlation per category
-- Note: a negative value suggests higher discounts correlate with lower stock (potential clearance signal)
SELECT
    CATEGORY,
    ROUND(CORR(DISCOUNT_PERCENT, AVAILABLE_QUANTITY)::NUMERIC, 4) AS DISCOUNT_STOCK_CORRELATION
FROM PRODUCT_LEVEL_INVENTORY
GROUP BY CATEGORY
ORDER BY DISCOUNT_STOCK_CORRELATION DESC;


-- ------------------------------------------------------------
-- WEIGHT-BASED PRICING (Price-Per-Gram Density)
-- NULLIF guards against division-by-zero on zero-weight records
-- ------------------------------------------------------------

-- Full price-per-gram listing
SELECT
    PRODUCT,
    CATEGORY,
    MRP,
    WEIGHT_IN_GMS,
    ROUND(MRP::NUMERIC / NULLIF(WEIGHT_IN_GMS, 0), 4) AS PRICE_PER_GRAM
FROM PRODUCT_LEVEL_INVENTORY
ORDER BY PRICE_PER_GRAM DESC NULLS LAST;

-- Top 10 most expensive per gram (high shrinkage risk)
SELECT
    PRODUCT,
    CATEGORY,
    MRP,
    WEIGHT_IN_GMS,
    ROUND(MRP::NUMERIC / WEIGHT_IN_GMS, 4) AS PRICE_PER_GRAM
FROM PRODUCT_LEVEL_INVENTORY
WHERE WEIGHT_IN_GMS > 0
ORDER BY PRICE_PER_GRAM DESC
LIMIT 10;

-- Top 10 cheapest per gram (bulk/commodity items)
SELECT
    PRODUCT,
    CATEGORY,
    MRP,
    WEIGHT_IN_GMS,
    ROUND(MRP::NUMERIC / WEIGHT_IN_GMS, 4) AS PRICE_PER_GRAM
FROM PRODUCT_LEVEL_INVENTORY
WHERE WEIGHT_IN_GMS > 0
ORDER BY PRICE_PER_GRAM ASC
LIMIT 10;
