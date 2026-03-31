-- ============================================================
-- FILE 3: INTERMEDIATE BUSINESS SIMULATIONS
-- Zepto Dark Store Inventory Analysis
-- ============================================================


-- ------------------------------------------------------------
-- REVENUE RANKING & TOP PRODUCTS
-- ------------------------------------------------------------

-- Potential revenue for every in-stock product
WITH PRODUCT_REVENUE AS (
    SELECT
        CATEGORY,
        PRODUCT,
        AVAILABLE_QUANTITY,
        DISCOUNTED_SELLING_PRICE,
        (AVAILABLE_QUANTITY * DISCOUNTED_SELLING_PRICE) AS POTENTIAL_REVENUE
    FROM PRODUCT_LEVEL_INVENTORY
    WHERE OUT_OF_STOCK = FALSE
)
SELECT *
FROM PRODUCT_REVENUE
ORDER BY POTENTIAL_REVENUE DESC;


-- Rank products by revenue within each category
SELECT
    CATEGORY,
    PRODUCT,
    DISCOUNTED_SELLING_PRICE * AVAILABLE_QUANTITY AS PRODUCT_REVENUE,
    DENSE_RANK() OVER (
        PARTITION BY CATEGORY
        ORDER BY DISCOUNTED_SELLING_PRICE * AVAILABLE_QUANTITY DESC
    ) AS CATEGORY_RANK
FROM PRODUCT_LEVEL_INVENTORY
WHERE OUT_OF_STOCK = FALSE;


-- Top 3 revenue-generating products per category (restock priority list)
WITH RANKED_PRODUCTS AS (
    SELECT
        CATEGORY,
        PRODUCT,
        DISCOUNTED_SELLING_PRICE * AVAILABLE_QUANTITY AS PRODUCT_REVENUE,
        DENSE_RANK() OVER (
            PARTITION BY CATEGORY
            ORDER BY DISCOUNTED_SELLING_PRICE * AVAILABLE_QUANTITY DESC
        ) AS CATEGORY_RANK
    FROM PRODUCT_LEVEL_INVENTORY
    WHERE OUT_OF_STOCK = FALSE
)
SELECT *
FROM RANKED_PRODUCTS
WHERE CATEGORY_RANK <= 3
ORDER BY CATEGORY, CATEGORY_RANK;


-- ------------------------------------------------------------
-- CATEGORY REVENUE CONCENTRATION
-- ------------------------------------------------------------

-- Revenue concentration across IN-STOCK products
-- fixed: was incorrectly filtering OUT_OF_STOCK = TRUE
SELECT
    CATEGORY,
    SUM(DISCOUNTED_SELLING_PRICE * AVAILABLE_QUANTITY) AS CATEGORY_REVENUE
FROM PRODUCT_LEVEL_INVENTORY
WHERE OUT_OF_STOCK = FALSE
GROUP BY CATEGORY
ORDER BY CATEGORY_REVENUE DESC;


-- % revenue contribution of each product within its category
WITH PRODUCT_REVENUE AS (
    SELECT
        CATEGORY,
        PRODUCT,
        (DISCOUNTED_SELLING_PRICE * AVAILABLE_QUANTITY) AS EACH_PRODUCT_REVENUE
    FROM PRODUCT_LEVEL_INVENTORY
)
SELECT
    CATEGORY,
    PRODUCT,
    EACH_PRODUCT_REVENUE,
    SUM(EACH_PRODUCT_REVENUE) OVER (PARTITION BY CATEGORY) AS CATEGORY_TOTAL_REVENUE,
    ROUND(
        EACH_PRODUCT_REVENUE * 100.0
        / NULLIF(SUM(EACH_PRODUCT_REVENUE) OVER (PARTITION BY CATEGORY), 0),
        2
    ) AS REVENUE_CONTRIBUTION_PCT
FROM PRODUCT_REVENUE
ORDER BY CATEGORY, REVENUE_CONTRIBUTION_PCT DESC;


-- ------------------------------------------------------------
-- INVENTORY RISK MODELS
-- ------------------------------------------------------------

-- Risk Model 1: Margin Bleeders
-- High discount + low stock + still listed as available
-- Signal: product is being discounted aggressively but barely has inventory to sell
SELECT
    PRODUCT,
    CATEGORY,
    MRP,
    DISCOUNT_PERCENT,
    AVAILABLE_QUANTITY,
    OUT_OF_STOCK
FROM PRODUCT_LEVEL_INVENTORY
WHERE DISCOUNT_PERCENT > 20
  AND AVAILABLE_QUANTITY < 5
  AND OUT_OF_STOCK = FALSE
ORDER BY DISCOUNT_PERCENT DESC;


-- Risk Model 2: Luxury Anchors
-- Above-average MRP within category + sitting at high stock + deep discount
-- Signal: expensive items not moving, being over-discounted to clear
-- fixed: subquery was missing required alias (would throw PostgreSQL error)
SELECT *
FROM (
    SELECT
        CATEGORY,
        PRODUCT,
        MRP,
        AVAILABLE_QUANTITY,
        DISCOUNT_PERCENT,
        ROUND(AVG(MRP) OVER (PARTITION BY CATEGORY), 2) AS CATEGORY_AVG_MRP
    FROM PRODUCT_LEVEL_INVENTORY
) AS CATEGORY_BENCHMARKS                              -- fixed: alias added
WHERE MRP > CATEGORY_AVG_MRP
  AND AVAILABLE_QUANTITY > 2
  AND DISCOUNT_PERCENT > 30
ORDER BY AVAILABLE_QUANTITY DESC;


-- ------------------------------------------------------------
-- MARGIN LEAKAGE
-- ------------------------------------------------------------

-- High discount + critically low stock
-- Products where margin is being surrendered with almost nothing left to sell
SELECT
    CATEGORY,
    PRODUCT,
    MRP,
    DISCOUNT_PERCENT,
    AVAILABLE_QUANTITY,
    ROUND(MRP * (DISCOUNT_PERCENT / 100.0) * AVAILABLE_QUANTITY, 2) AS MARGIN_SURRENDERED
FROM PRODUCT_LEVEL_INVENTORY
WHERE DISCOUNT_PERCENT > 15
  AND AVAILABLE_QUANTITY < 3
  AND OUT_OF_STOCK = FALSE
ORDER BY MARGIN_SURRENDERED DESC;
