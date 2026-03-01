# Zepto E-Commerce: Inventory & Pricing Optimization

## Project Overview

This project analyzes dark store inventory data for a quick-commerce platform to identify margin 
leakage, stagnant capital, and physical storage bottlenecks. Using SQL, I engineered custom metrics 
(like Price-Per-Gram) and built risk profiles to transform raw database rows into actionable supply 
chain strategies.

---

## Tech Stack & Skills Used

- **Database:** PostgreSQL / Standard SQL
- **Techniques:** Window Functions (DENSE_RANK, SUM OVER PARTITION BY), CTEs (Common Table 
  Expressions), Conditional Aggregation (CASE WHEN), Custom Metric Engineering, Subqueries, 
  Row-level Filtering, Multi-condition Logic, CORR() for correlation analysis
- **Focus Area:** Inventory Optimization, Margin Protection, Loss Prevention

---

## Dataset

- **Table:** `PRODUCT_LEVEL_INVENTORY`
- **Source:** Simulated dataset modeled after Zepto's dark store SKU structure (for portfolio purposes)
- **Schema:**

| Column | Type | Description |
|---|---|---|
| CATEGORY | VARCHAR | Product category (e.g., Dairy, Snacks, Beverages) |
| PRODUCT | VARCHAR | Product name / SKU |
| MRP | INT | Maximum Retail Price |
| DISCOUNT_PERCENT | INT | Discount applied (%) |
| AVAILABLE_QUANTITY | INT | Units currently in stock |
| DISCOUNTED_SELLING_PRICE | INT | Final price after discount |
| WEIGHT_IN_GMS | INT | Product weight in grams |
| OUT_OF_STOCK | VARCHAR | Stock status ('TRUE' / 'FALSE') |
| QUANTITY | INT | Quantity sold or demand proxy |

---

## Repository Structure

- **`setup.sql`** — Table creation, schema definition, and data loading
- **`Analyse the data of zepto.sql`** — All analysis queries organized into the following sections:
  - Data Exploration
  - Price Analysis
  - Stock Status
  - Discount Insights
  - Revenue Simulation
  - Profit Simulation
  - Discount Impact Analysis
  - Weight-Based Pricing & Price-Per-Gram
  - Revenue Ranking & Top Products
  - Margin Leakage
  - Inventory Risk Model
  - KPI Dashboard

---

## Executive Summary & Business Recommendations

Based on the SQL queries and risk profiles generated, I delivered the following operational directives:

### 1. Curb Margin Leakage on Premium Tier
Data indicates Premium products (MRP > ₹5,000) hold disproportionately high inventory levels while 
suffering from an 8.36% average discount rate, resulting in severe margin bleed.  
**Action:** Cap premium discounts at 4% and shift promotional focus to moving mid-range volume.

### 2. Liquidate Stagnant Inventory
Identified a critical bottleneck of items sitting at maximum capacity (6 units) with zero promotional 
effort (0% discount), causing a dark store storage crisis.  
**Action:** Implement an immediate 20–25% flash clearance on these specific SKUs to free up physical 
shelving space for fast-moving goods.

### 3. Mitigate High-Value Shrinkage Risk
Price-per-gram analysis isolated the most capital-concentrated assets on the shelves — lightweight, 
high-MRP products most vulnerable to shrinkage and theft.  
**Action:** Relocate the Top 10 most expensive-per-gram SKUs to a monitored security zone to reduce 
inventory shrinkage and capital loss.

---

## Key Analytical Queries

| Analysis | Technique Used |
|---|---|
| Revenue contribution per product within category | Window Function (SUM OVER PARTITION BY) |
| Top 3 products per category by revenue | CTE + DENSE_RANK() |
| Luxury Anchors (high MRP, high stock, over-discounted) | Subquery + AVG OVER PARTITION BY |
| Price-Per-Gram premium SKU isolation | Custom metric with NULLIF division guard |
| Discount vs. stock correlation by category | CORR() aggregation |
| Price band segmentation (Budget / Mid-range / Premium) | CASE WHEN + GROUP BY |
| KPI Dashboard (5 metrics in one query) | Conditional Aggregation |

---

## Assumptions

- Cost of goods is assumed at **70% of MRP**, giving a gross margin of 30%
- `AVAILABLE_QUANTITY = 6` is treated as maximum dark store shelf capacity for a single SKU
- `OUT_OF_STOCK = 'FALSE'` filters active inventory for revenue calculations
- Price bands defined as: Budget = MRP < ₹2,000 | Mid-range = ₹2,000–₹5,000 | Premium = MRP > ₹5,000

---

*Note: Dataset is simulated for portfolio purposes and does not represent actual Zepto business data.*
