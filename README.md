Zepto E-Commerce: Inventory & Pricing Optimization
==================================================

Project Overview
----------------
This project analyzes dark store inventory data for a quick-commerce platform to identify margin leakage, stagnant capital, and physical storage bottlenecks. Using SQL, I engineered custom metrics (like Price-Per-Gram) and built risk profiles to transform raw database rows into actionable supply chain strategies.

Tech Stack & Skills Used
------------------------
- Database: PostgreSQL / Standard SQL
- Techniques: Conditional Aggregation (CASE WHEN), Custom Metric Engineering, Row-level filtering, Multi-condition Logic.
- Focus Area: Inventory Optimization, Margin Protection, Loss Prevention.

Executive Summary & Business Recommendations
--------------------------------------------
Based on the database queries and risk profiles generated, I delivered the following operational directives:

1. Curb Margin Leakage on Premium Tier: Data indicates Premium products hold disproportionately high inventory levels while suffering from an 8.36% average discount rate, resulting in severe margin bleed. Action: Cap premium discounts at 4% and shift promotional focus to moving mid-range volume.

2. Liquidate Stagnant Inventory: Identified a critical bottleneck of items sitting at maximum capacity (6 units) with little to no promotional effort, causing a dark store storage crisis. Action: Implement an immediate 20-25% flash clearance on these specific SKUs to free up physical shelving space for fast-moving goods.

3. Mitigate High-Value Shrinkage Risk: Price-per-gram analysis isolated the most highly concentrated capital assets on our shelves. Action: Relocate these top 10 most expensive/lightest SKUs to a monitored security zone to reduce inventory shrinkage and capital loss.

Repository Structure
--------------------
- 01_Executive_KPI_Dashboard.sql: A macro-level aggregation calculating total active products, categories, potential gross revenue, and total out-of-stock liabilities without grouping.

- 02_Advanced_Insights.sql: A deep dive isolating the Top 5 revenue-generating categories, identifying the most over-discounted category, flagging high-risk/high-capacity inventory, and calculating Top 10 premium price-per-gram items.

--------------------------------------------------
Note: The dataset used for this analysis is proprietary/simulated for portfolio purposes.
