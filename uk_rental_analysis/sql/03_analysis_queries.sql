-- ============================================================
-- UK Rental Market Analysis — London
-- Script 3: Exploratory Analysis & Insights
-- Author: Oladele Desmond-Eke
-- ============================================================


-- ============================================================
-- SECTION A: Market Overview
-- ============================================================

-- A1. Overall summary statistics
SELECT
    COUNT(*)                             AS total_properties,
    ROUND(AVG(monthly_rent_gbp), 2)      AS avg_monthly_rent,
    MIN(monthly_rent_gbp)                AS min_rent,
    MAX(monthly_rent_gbp)                AS max_rent,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY monthly_rent_gbp) AS median_rent
FROM rentals;

-- A2. Properties by status
SELECT
    status,
    COUNT(*)                         AS count,
    ROUND(AVG(monthly_rent_gbp), 2)  AS avg_rent,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 1) AS pct_of_total
FROM rentals
GROUP BY status
ORDER BY count DESC;

-- A3. Stock breakdown by property type
SELECT
    property_type,
    COUNT(*)                                                       AS total,
    ROUND(AVG(monthly_rent_gbp), 2)                               AS avg_rent,
    MIN(monthly_rent_gbp)                                         AS min_rent,
    MAX(monthly_rent_gbp)                                         AS max_rent,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 1)            AS pct_of_stock
FROM rentals
GROUP BY property_type
ORDER BY avg_rent DESC;


-- ============================================================
-- SECTION B: Borough-Level Analysis
-- ============================================================

-- B1. Average rent by borough (ranked highest to lowest)
SELECT
    borough,
    COUNT(*)                             AS listings,
    ROUND(AVG(monthly_rent_gbp), 2)      AS avg_rent,
    ROUND(MIN(monthly_rent_gbp), 2)      AS min_rent,
    ROUND(MAX(monthly_rent_gbp), 2)      AS max_rent,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY monthly_rent_gbp) AS median_rent
FROM rentals
GROUP BY borough
ORDER BY avg_rent DESC;

-- B2. Borough void rate (% of properties with status = 'Void')
-- High void rate may indicate overpricing or low demand
SELECT
    borough,
    COUNT(*)                                                        AS total_listings,
    SUM(CASE WHEN status = 'Void' THEN 1 ELSE 0 END)              AS void_count,
    ROUND(SUM(CASE WHEN status = 'Void' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS void_rate_pct
FROM rentals
GROUP BY borough
HAVING COUNT(*) >= 10
ORDER BY void_rate_pct DESC;

-- B3. Average rent by borough and property type (cross-tab style)
SELECT
    borough,
    ROUND(AVG(CASE WHEN property_type = 'Studio'             THEN monthly_rent_gbp END), 0) AS avg_studio,
    ROUND(AVG(CASE WHEN property_type = 'Flat'               THEN monthly_rent_gbp END), 0) AS avg_flat,
    ROUND(AVG(CASE WHEN property_type = 'Terraced House'     THEN monthly_rent_gbp END), 0) AS avg_terraced,
    ROUND(AVG(CASE WHEN property_type = 'Semi-Detached House' THEN monthly_rent_gbp END), 0) AS avg_semi_det,
    ROUND(AVG(CASE WHEN property_type = 'Detached House'     THEN monthly_rent_gbp END), 0) AS avg_detached
FROM rentals
GROUP BY borough
ORDER BY avg_flat DESC NULLS LAST;


-- ============================================================
-- SECTION C: Bedroom & Pricing Analysis
-- ============================================================

-- C1. Average rent by bedrooms across all property types
SELECT
    bedrooms,
    COUNT(*)                              AS listings,
    ROUND(AVG(monthly_rent_gbp), 2)       AS avg_rent,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY monthly_rent_gbp) AS median_rent
FROM rentals
WHERE bedrooms IS NOT NULL
GROUP BY bedrooms
ORDER BY bedrooms;

-- C2. Rent per bedroom — value analysis
-- Useful for identifying efficient/inefficient pricing
SELECT
    property_id,
    borough,
    property_type,
    bedrooms,
    monthly_rent_gbp,
    ROUND(monthly_rent_gbp / NULLIF(bedrooms, 0), 2) AS rent_per_bedroom,
    status
FROM rentals
WHERE bedrooms > 0
ORDER BY rent_per_bedroom DESC
LIMIT 20;

-- C3. Price distribution buckets
SELECT
    CASE
        WHEN monthly_rent_gbp < 1500                   THEN 'Under £1,500'
        WHEN monthly_rent_gbp BETWEEN 1500 AND 2499    THEN '£1,500–£2,499'
        WHEN monthly_rent_gbp BETWEEN 2500 AND 3499    THEN '£2,500–£3,499'
        WHEN monthly_rent_gbp BETWEEN 3500 AND 4999    THEN '£3,500–£4,999'
        ELSE '£5,000+'
    END AS rent_band,
    COUNT(*)                         AS count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 1) AS pct_of_total
FROM rentals
GROUP BY rent_band
ORDER BY MIN(monthly_rent_gbp);


-- ============================================================
-- SECTION D: Lease & Tenancy Analysis
-- ============================================================

-- D1. Leases expiring in the next 90 days (as of a given date)
-- Useful for void risk forecasting — mirrors Lee Baron use case
SELECT
    property_id,
    borough,
    property_type,
    bedrooms,
    monthly_rent_gbp,
    lease_end_date,
    lease_end_date - CURRENT_DATE AS days_until_expiry,
    status
FROM rentals
WHERE lease_end_date BETWEEN CURRENT_DATE AND CURRENT_DATE + INTERVAL '90 days'
ORDER BY lease_end_date;

-- D2. Average lease duration by property type
SELECT
    property_type,
    ROUND(AVG(lease_end_date - lease_start_date)) AS avg_lease_days,
    ROUND(AVG(lease_end_date - lease_start_date) / 30.0, 1) AS avg_lease_months
FROM rentals
WHERE lease_start_date IS NOT NULL AND lease_end_date IS NOT NULL
GROUP BY property_type
ORDER BY avg_lease_days DESC;

-- D3. Time to let: days between listing date and lease start
-- Lower = faster to let; useful for demand signal
SELECT
    borough,
    ROUND(AVG(lease_start_date - listing_date)) AS avg_days_to_let
FROM rentals
WHERE listing_date IS NOT NULL AND lease_start_date IS NOT NULL
    AND lease_start_date > listing_date
GROUP BY borough
ORDER BY avg_days_to_let ASC;


-- ============================================================
-- SECTION E: Letting Agent & Landlord Analysis
-- ============================================================

-- E1. Market share by letting agent
SELECT
    COALESCE(letting_agent, 'Unknown') AS letting_agent,
    COUNT(*)                           AS listings,
    ROUND(AVG(monthly_rent_gbp), 2)    AS avg_rent,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 1) AS market_share_pct
FROM rentals
GROUP BY letting_agent
ORDER BY listings DESC;

-- E2. Void rate by landlord type
-- Do private landlords have higher void rates than corporates?
SELECT
    landlord_type,
    COUNT(*)                                                        AS total,
    SUM(CASE WHEN status = 'Void' THEN 1 ELSE 0 END)              AS voids,
    ROUND(SUM(CASE WHEN status = 'Void' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS void_rate_pct,
    ROUND(AVG(monthly_rent_gbp), 2)                               AS avg_rent
FROM rentals
GROUP BY landlord_type
ORDER BY void_rate_pct DESC;


-- ============================================================
-- SECTION F: EPC & Property Age Analysis
-- ============================================================

-- F1. Average rent by EPC rating
-- Do higher-rated (more efficient) properties command a premium?
SELECT
    epc_rating,
    COUNT(*)                          AS count,
    ROUND(AVG(monthly_rent_gbp), 2)   AS avg_rent,
    ROUND(AVG(year_built), 0)         AS avg_year_built
FROM rentals
WHERE epc_rating IS NOT NULL
GROUP BY epc_rating
ORDER BY epc_rating;

-- F2. Property age buckets vs average rent
SELECT
    CASE
        WHEN year_built < 1950             THEN 'Pre-1950'
        WHEN year_built BETWEEN 1950 AND 1979 THEN '1950–1979'
        WHEN year_built BETWEEN 1980 AND 1999 THEN '1980–1999'
        WHEN year_built BETWEEN 2000 AND 2014 THEN '2000–2014'
        WHEN year_built >= 2015            THEN '2015–Present'
    END AS era,
    COUNT(*)                           AS count,
    ROUND(AVG(monthly_rent_gbp), 2)    AS avg_rent
FROM rentals
WHERE year_built IS NOT NULL
GROUP BY era
ORDER BY MIN(year_built);


-- ============================================================
-- SECTION G: Outlier & Exception Reporting
-- ============================================================

-- G1. Significantly overpriced properties
-- More than 1.5x the borough average for same property type
WITH borough_type_avg AS (
    SELECT
        borough,
        property_type,
        ROUND(AVG(monthly_rent_gbp), 2) AS avg_rent
    FROM rentals
    GROUP BY borough, property_type
)
SELECT
    r.property_id,
    r.borough,
    r.property_type,
    r.bedrooms,
    r.monthly_rent_gbp,
    b.avg_rent AS borough_type_avg,
    ROUND(r.monthly_rent_gbp / b.avg_rent, 2) AS rent_ratio,
    r.status
FROM rentals r
JOIN borough_type_avg b
    ON r.borough = b.borough AND r.property_type = b.property_type
WHERE r.monthly_rent_gbp > b.avg_rent * 1.5
ORDER BY rent_ratio DESC;

-- G2. Properties with high service charge relative to rent
SELECT
    property_id,
    borough,
    property_type,
    monthly_rent_gbp,
    service_charge_gbp,
    ROUND(service_charge_gbp / monthly_rent_gbp * 100, 1) AS service_charge_pct
FROM rentals
WHERE service_charge_gbp > 0
ORDER BY service_charge_pct DESC
LIMIT 15;
