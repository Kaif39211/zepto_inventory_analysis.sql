-- ============================================================
-- FILE 4: ADVANCED ANALYTIC INSIGHTS
-- Zepto Dark Store Inventory Analysis
-- ============================================================


-- ------------------------------------------------------------
-- PRICE BAND SEGMENTATION
-- Budget: MRP < ₹2,000 | Mid-Range: ₹2,000–₹5,000 | Premium: > ₹5,000
-- ------------------------------------------------------------

WITH PRICE_BAND AS (
    SELECT
        PRODUCT,
        CATEGORY,
        MRP,
        DISCOUNTED_SELLING_PRICE,
        AVAILABLE_QUANTITY,
        DISCOUNT_PERCENT,
        CASE
            WHEN MRP > 5000                  THEN 'PREMIUM'
            WHEN MRP BETWEEN 2000 AND 5000   THEN 'MID_RANGE'
            ELSE                                  'BUDGET'
        END AS PRICE_BAND
    FROM PRODUCT_LEVEL_INVENTORY
)
SELECT
    PRICE_BAND,
    COUNT(PRODUCT)                                          AS PRODUCT_COUNT,
    SUM(DISCOUNTED_SELLING_PRICE * AVAILABLE_QUANTITY)      AS POTENTIAL_REVENUE,  -- fixed: typo POTENTIAN_REVENUE
    ROUND(AVG(DISCOUNT_PERCENT), 2)                         AS AVG_DISCOUNT_PCT
FROM PRICE_BAND
GROUP BY PRICE_BAND
ORDER BY
    CASE PRICE_BAND
        WHEN 'PREMIUM'   THEN 1
        WHEN 'MID_RANGE' THEN 2
        ELSE 3
    END;


-- ------------------------------------------------------------
-- STOCK EFFICIENCY ANALYSIS
-- ------------------------------------------------------------

-- Shelf-hoggers: full bin capacity (6 units) with zero discount
-- Signal: items sitting at max stock with no promotional push — likely stagnant
SELECT
    CATEGORY,
    PRODUCT,
    MRP,
    AVAILABLE_QUANTITY,
    DISCOUNT_PERCENT,
    (MRP * AVAILABLE_QUANTITY) AS CAPITAL_LOCKED
FROM PRODUCT_LEVEL_INVENTORY
WHERE AVAILABLE_QUANTITY = 6
  AND DISCOUNT_PERCENT = 0
  AND OUT_OF_STOCK = FALSE
ORDER BY CAPITAL_LOCKED DESC;


-- ------------------------------------------------------------
-- KPI EXECUTIVE DASHBOARD
-- Single-query summary for stakeholder reporting
-- ------------------------------------------------------------

SELECT
    COUNT(DISTINCT PRODUCT)                                             AS TOTAL_PRODUCTS,
    COUNT(DISTINCT CATEGORY)                                            AS TOTAL_CATEGORIES,
    SUM(DISCOUNTED_SELLING_PRICE * AVAILABLE_QUANTITY)                  AS TOTAL_POTENTIAL_REVENUE,
    ROUND(AVG(DISCOUNT_PERCENT), 2)                                     AS AVG_DISCOUNT_PCT,
    SUM(CASE WHEN OUT_OF_STOCK = TRUE  THEN 1 ELSE 0 END)               AS TOTAL_OOS_ITEMS,
    ROUND(
        SUM(CASE WHEN OUT_OF_STOCK = TRUE THEN 1 ELSE 0 END)
        * 100.0 / COUNT(*), 2
    )                                                                   AS OOS_RATE_PCT
FROM PRODUCT_LEVEL_INVENTORY;


-- ------------------------------------------------------------
-- CATEGORY-LEVEL KPI BREAKDOWN
-- ------------------------------------------------------------

-- Top 5 categories by potential revenue
SELECT
    CATEGORY,
    SUM(DISCOUNTED_SELLING_PRICE * AVAILABLE_QUANTITY) AS CATEGORY_REVENUE
FROM PRODUCT_LEVEL_INVENTORY
WHERE OUT_OF_STOCK = FALSE
GROUP BY CATEGORY
ORDER BY CATEGORY_REVENUE DESC
LIMIT 5;

-- Most over-discounted category (margin risk alert)
SELECT
    CATEGORY,
    ROUND(AVG(DISCOUNT_PERCENT), 2) AS AVG_DISCOUNT_PCT
FROM PRODUCT_LEVEL_INVENTORY
GROUP BY CATEGORY
ORDER BY AVG_DISCOUNT_PCT DESC
LIMIT 1;

-- Out-of-stock rate per category
SELECT
    CATEGORY,
    COUNT(*) AS TOTAL_SKUS,
    SUM(CASE WHEN OUT_OF_STOCK = TRUE THEN 1 ELSE 0 END) AS OOS_SKUS,
    ROUND(
        SUM(CASE WHEN OUT_OF_STOCK = TRUE THEN 1 ELSE 0 END) * 100.0 / COUNT(*),
        2
    ) AS OOS_RATE_PCT
FROM PRODUCT_LEVEL_INVENTORY
GROUP BY CATEGORY
ORDER BY OOS_RATE_PCT DESC;


-- ------------------------------------------------------------
-- HIGH-RISK INVENTORY ITEMS
-- Max stock + high MRP + heavy discount = capital at risk
-- ------------------------------------------------------------

SELECT
    CATEGORY,
    PRODUCT,
    MRP,
    AVAILABLE_QUANTITY,
    DISCOUNT_PERCENT,
    ROUND(MRP * (DISCOUNT_PERCENT / 100.0) * AVAILABLE_QUANTITY, 2) AS MARGIN_AT_RISK
FROM PRODUCT_LEVEL_INVENTORY
WHERE AVAILABLE_QUANTITY = 6
  AND MRP > 3000
  AND DISCOUNT_PERCENT > 15
  AND OUT_OF_STOCK = FALSE
ORDER BY MARGIN_AT_RISK DESC;


-- ------------------------------------------------------------
-- PRICE-PER-GRAM: SHRINKAGE SECURITY FLAG
-- Top 10 highest-value items by weight density
-- Recommendation: move to secured/monitored shelving
-- ------------------------------------------------------------

SELECT
    CATEGORY,
    PRODUCT,
    MRP,
    WEIGHT_IN_GMS,
    ROUND(MRP::NUMERIC / WEIGHT_IN_GMS, 2) AS PRICE_PER_GRAM
FROM PRODUCT_LEVEL_INVENTORY
WHERE WEIGHT_IN_GMS > 0
ORDER BY PRICE_PER_GRAM DESC
LIMIT 10;


-- ------------------------------------------------------------
-- PREMIUM TIER DISCOUNT AUDIT
-- Validates whether premium products are being over-discounted
-- Recommendation: cap premium discounts at 4%
-- ------------------------------------------------------------

SELECT
    PRODUCT,
    CATEGORY,
    MRP,
    DISCOUNT_PERCENT,
    DISCOUNTED_SELLING_PRICE,
    ROUND(MRP * (DISCOUNT_PERCENT / 100.0), 2) AS DISCOUNT_AMOUNT_PER_UNIT,
    AVAILABLE_QUANTITY,
    ROUND(MRP * (DISCOUNT_PERCENT / 100.0) * AVAILABLE_QUANTITY, 2) AS TOTAL_MARGIN_SURRENDERED
FROM PRODUCT_LEVEL_INVENTORY
WHERE MRP > 5000
  AND DISCOUNT_PERCENT > 4
  AND OUT_OF_STOCK = FALSE
ORDER BY TOTAL_MARGIN_SURRENDERED DESC;
