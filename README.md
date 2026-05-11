# 🏘️ London Rental Market Analysis
### A Data Wrangling & SQL Analysis Portfolio Project

**Author:** Oladele Desmond-Eke  
**Tools:** SQL (PostgreSQL), Python (pandas), Excel  
**Domain:** UK Property & Real Estate  

---

## Project Overview

This project analyses a synthetic dataset of 500 London rental listings across 15 boroughs, demonstrating end-to-end data skills from raw ingestion and cleaning through to stakeholder-ready SQL insights.

The dataset mirrors the type of property and lease data managed professionally at Lee Baron and Landswood De Coy, and is designed to showcase practical skills relevant to data analyst roles in property, finance, and public sector environments.

---

## Project Structure

```
uk_rental_analysis/
│
├── data/
│   ├── raw/
│   │   └── london_rentals_raw.csv        # Original messy dataset (515 rows with issues)
│   └── cleaned/
│       └── london_rentals_clean.csv      # Validated, cleaned dataset (500 rows)
│
├── sql/
│   ├── 01_schema_setup.sql               # Table creation & data loading
│   ├── 02_data_cleaning.sql              # Staging, audit, and cleaning logic
│   └── 03_analysis_queries.sql           # Exploratory analysis & insights
│
├── docs/
│   └── data_dictionary.md                # Field definitions and valid values
│
└── README.md
```

---

## Dataset

The raw dataset contains **515 rows** with the following realistic data quality issues introduced for wrangling demonstration:

| Issue Type | Count |
|---|---|
| Duplicate rows | ~15 |
| Inconsistent property type values (e.g. "flat", "FLAT", "flat apartment") | ~80 |
| Inconsistent borough names (e.g. "HACKNEY", "Hackney ") | ~30 |
| Mixed date formats (DD/MM/YYYY, MM-DD-YYYY, etc.) | ~50 |
| Rent values with currency symbols or commas (e.g. "£1,600") | ~40 |
| Missing values in EPC rating, letting agent, furnished fields | ~60 |
| Impossible values (negative bedrooms, £0 rent) | ~10 |

After cleaning, the dataset contains **500 validated rows** ready for analysis.

---

## Key Analysis Areas

### 🔍 Data Cleaning (Script 02)
- Duplicate detection and removal using `ctid`
- Standardisation of categorical fields using `CASE WHEN` + `LOWER/TRIM`
- Null handling and data type enforcement
- Outlier detection and removal (impossible rents/bedrooms)
- Promotion from staging to production table

### 📊 Exploratory Analysis (Script 03)

| Section | Focus |
|---|---|
| A — Market Overview | Summary stats, status breakdown, stock by type |
| B — Borough Analysis | Average/median rent by borough, void rates, cross-tabs |
| C — Pricing Analysis | Rent by bedrooms, rent per bedroom, price distribution |
| D — Lease Analysis | Expiry forecasting, average lease duration, time-to-let |
| E — Agent & Landlord | Market share, void rates by landlord type |
| F — EPC & Property Age | Energy efficiency premium, era vs rent |
| G — Outlier Reporting | Overpriced properties, high service charge flags |

---

## Key Findings (Sample)

- **Camden and Islington** command the highest average rents (£2,700–£2,900/month), while **Waltham Forest and Newham** are the most affordable (£1,600–£1,900/month).
- **Void rates** are highest among Private Landlords, suggesting pricing inefficiency compared to corporate landlords.
- Properties with **EPC ratings of A or B** command a modest premium, reflecting growing tenant preference for energy-efficient homes.
- Approximately **12% of leases** expire within the next 90 days — a key metric for void risk management.
