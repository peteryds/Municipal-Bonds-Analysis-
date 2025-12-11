# Municipal Bonds Analysis

## 1. How to Run the Code

Follow the steps below to set up and reproduce the analysis:

```bash
# 1. Clone the repository
git clone https://github.com/peteryds/Municipal-Bonds-Analysis-.git
cd Municipal-Bonds-Analysis-

# 2. Create the database schema
psql -d muni_db -f schema.sql

# 3. Load the data using the ETL script
python load_data.py

# 4. Run analytical queries
psql -d muni_db -f queries.sql
```
## Requirements

- **PostgreSQL 14+**
- **Python 3.9+**

After setup, all tables, queries, and visualizations will reproduce the results shown in the final report.

---

## 2. Design Overview

### **Database Schema**

This project implements a fully normalized municipal bond database structured around **six core tables**:

- **Issuers** — issuer-level attributes (state, type, demographic/economic fields)
- **Bonds** — bond characteristics (coupon, maturity, duration, purpose)
- **Bond Purposes** — standardized public-purpose sector classifications
- **Credit Ratings** — time-series rating histories across agencies
- **Trades** — transaction-level yields and prices
- **Economic Indicators** — state/date macroeconomic data

The schema follows **Third Normal Form (3NF)** to ensure:

- Minimal redundancy  
- Strong referential integrity  
- Clean joins across entities  
- Efficient analytical performance for time-series, cross-sectional, and political segmentation studies  

**Strategic indexing supports:**

- Latest-trade extraction  
- Yield curve analysis  
- Rating transitions  
- State-level comparisons  

---

### **Analytical Framework**

The SQL analysis uses:

- **CTEs** for structured preprocessing  
- **Window functions** (`LAG`, `AVG OVER`) for YoY changes & yield smoothing  
- **Statistical functions** (`CORR`, `STDDEV`) for macroeconomic and geographic insights  
- **Ranking functions** (`DENSE_RANK`) for credit-tier interpretation  

**Visualizations include:**

- Yield curves  
- Credit rating distribution  
- State-level yield dispersion  
- Sector performance  
- Time-series macro sensitivity  
- Trading activity patterns  

These outputs collectively describe how yields, credit quality, issuance behavior, macroeconomics, and political conditions interact in the U.S. municipal bond market.



