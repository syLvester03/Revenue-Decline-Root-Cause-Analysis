# Revenue Decline Root Cause Analysis

## Executive Summary
This project investigates the root cause of a significant revenue decline (₹7.8 Cr drop between 2018 and 2019) for a B2B hardware/electronics supplier. While initial hypotheses suggested seasonality or broad market weakness, a deep-dive data analysis using **SQL** and **Python** revealed that **86.9% of the revenue drop is directly attributable to reduced orders from just the Top 10 customers. 
The analysis proves that the business is facing a severe customer concentration risk rather than a systemic market downturn**. 

## Project Structure
The repository is structured to reflect a professional data analysis pipeline:

- `data/Raw_Data.sql`: The raw database dump used for the analysis.
- `sql/01_data_cleaning.sql`: SQL scripts to clean anomalies (invalid transactions, duplicate markets) and normalize currency (USD to INR).
- `sql/02_revenue_decline_analysis.sql`: Exploratory SQL queries that identified the Q4 revenue dips and localized the problem to customer behavior.
- `notebooks/03_customer_concentration_analysis.ipynb`: A Python (Pandas & Matplotlib) deep dive that quantifies the concentration risk and formulates business recommendations.

## Tech Stack
- **SQL (MySQL):** Data cleaning, ETL, and initial exploratory data analysis.
- **Python (Pandas, Matplotlib, SQLAlchemy):** Advanced data manipulation, statistical deep-dives, and data visualization.

## Key Findings
1. **It's a Concentration Problem, Not Seasonality:** The Top 10 customers account for 73–77% of total revenue every year. Their reduced purchasing behavior drove the massive 2019 revenue decline.
2. **Growth in the Long Tail:** While Top 10 customers pulled back, non-Top 10 customer revenue actually grew by ₹25L in Q3 2019, proving that broad market demand remains healthy.
3. **Volume Drop:** Top 10 customer order volume fell by 24.3% YoY, confirming that the revenue drop was caused by fewer purchases, not just smaller basket sizes.

## Strategic Recommendations
- **Immediate Account Management:** Deploy targeted retention efforts for the "Critical-tier" customers. Four specific accounts are responsible for 77% of the total revenue decline.
- **Diversification Strategy:** Actively invest in and develop the non-Top 10 customer base, which has already demonstrated organic growth despite the top-heavy revenue losses.
- **Investigate the "Why":** Combine these quantitative findings with CRM data or sales team feedback to understand *why* the top accounts are ordering less (e.g., competitor pricing, contract renegotiations, or inventory changes).