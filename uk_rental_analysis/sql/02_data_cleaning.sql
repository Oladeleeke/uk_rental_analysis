-- ============================================================
-- UK Rental Market Analysis — London
-- Script 2: Data Cleaning & Wrangling (Raw Dataset)
-- Author: Oladele Desmond-Eke
-- ============================================================
-- This script documents the cleaning steps applied to the raw
-- dataset before loading into the rentals table for analysis.
-- Run these queries against a staging table loaded from:
-- data/raw/london_rentals_raw.csv
-- ============================================================

-- STEP 1: Load raw data into staging table
DROP TABLE IF EXISTS rentals_staging;

CREATE TABLE rentals_staging AS TABLE rentals WITH NO DATA;
ALTER TABLE rentals_staging DROP CONSTRAINT IF EXISTS rentals_staging_pkey;

-- \COPY rentals_staging FROM 'data/raw/london_rentals_raw.csv' WITH (FORMAT csv, HEADER true);


-- ============================================================
-- STEP 2: Audit — understand the raw data quality issues
-- ============================================================

-- 2a. Total row count (expect ~515 including duplicates)
SELECT COUNT(*) AS total_rows FROM rentals_staging;

-- 2b. Check for duplicate property_ids
SELECT property_id, COUNT(*) AS occurrences
FROM rentals_staging
GROUP BY property_id
HAVING COUNT(*) > 1
ORDER BY occurrences DESC;

-- 2c. Check for nulls / empty strings across key fields
SELECT
    SUM(CASE WHEN property_id   IS NULL OR property_id = ''   THEN 1 ELSE 0 END) AS missing_property_id,
    SUM(CASE WHEN borough       IS NULL OR borough = ''       THEN 1 ELSE 0 END) AS missing_borough,
    SUM(CASE WHEN property_type IS NULL OR property_type = '' THEN 1 ELSE 0 END) AS missing_property_type,
    SUM(CASE WHEN bedrooms      IS NULL                       THEN 1 ELSE 0 END) AS missing_bedrooms,
    SUM(CASE WHEN epc_rating    IS NULL OR epc_rating = ''    THEN 1 ELSE 0 END) AS missing_epc,
    SUM(CASE WHEN letting_agent IS NULL OR letting_agent = '' THEN 1 ELSE 0 END) AS missing_agent,
    SUM(CASE WHEN furnished     IS NULL OR furnished = ''     THEN 1 ELSE 0 END) AS missing_furnished
FROM rentals_staging;

-- 2d. Check distinct property_type values (expect inconsistencies)
SELECT property_type, COUNT(*) AS count
FROM rentals_staging
GROUP BY property_type
ORDER BY count DESC;

-- 2e. Check distinct borough values (expect casing/spacing issues)
SELECT borough, COUNT(*) AS count
FROM rentals_staging
GROUP BY borough
ORDER BY borough;

-- 2f. Check for impossible/outlier rent values
SELECT property_id, monthly_rent_gbp, property_type, bedrooms, borough
FROM rentals_staging
WHERE monthly_rent_gbp <= 0 OR monthly_rent_gbp > 20000
ORDER BY monthly_rent_gbp;

-- 2g. Check for impossible bedroom counts
SELECT property_id, bedrooms, property_type
FROM rentals_staging
WHERE bedrooms < 0 OR bedrooms > 10
ORDER BY bedrooms;


-- ============================================================
-- STEP 3: Clean — build a corrected version of the data
-- ============================================================

-- 3a. Remove exact duplicates (keep first occurrence per property_id)
DELETE FROM rentals_staging
WHERE ctid NOT IN (
    SELECT MIN(ctid)
    FROM rentals_staging
    GROUP BY property_id
);

-- Confirm duplicate removal
SELECT COUNT(*) AS rows_after_dedup FROM rentals_staging;

-- 3b. Standardise property_type values
UPDATE rentals_staging
SET property_type = CASE
    WHEN LOWER(TRIM(property_type)) IN ('flat', 'flat apartment') THEN 'Flat'
    WHEN LOWER(TRIM(property_type)) IN ('studio', 'studio flat') THEN 'Studio'
    WHEN LOWER(TRIM(property_type)) IN ('terraced house', 'terraced', 'terraced house ') THEN 'Terraced House'
    WHEN LOWER(TRIM(property_type)) IN ('semi-detached house', 'semi detached', 'semi detached house', 'semi-det') THEN 'Semi-Detached House'
    WHEN LOWER(TRIM(property_type)) IN ('detached house', 'detached') THEN 'Detached House'
    WHEN LOWER(TRIM(property_type)) IN ('maisonette', 'maisonette ') THEN 'Maisonette'
    ELSE INITCAP(TRIM(property_type))
END;

-- 3c. Standardise borough name (trim whitespace, fix casing)
UPDATE rentals_staging
SET borough = INITCAP(TRIM(
    REPLACE(REPLACE(REPLACE(
        LOWER(borough),
    'towerhamilets', 'tower hamlets'),
    'tower hamlets', 'tower hamlets'),
    'hamlets', 'hamlets')
));

-- Fix known variants not caught by INITCAP
UPDATE rentals_staging SET borough = 'Tower Hamlets'
WHERE LOWER(TRIM(REPLACE(borough, ' ', ''))) = 'towerhamlets';

-- 3d. Remove rows with impossible rent values
DELETE FROM rentals_staging
WHERE monthly_rent_gbp <= 0 OR monthly_rent_gbp > 20000;

-- 3e. Null out impossible bedroom values (flag for review rather than delete)
UPDATE rentals_staging
SET bedrooms = NULL
WHERE bedrooms < 0 OR bedrooms > 10;

-- 3f. Standardise NULL-like empty strings to actual NULLs
UPDATE rentals_staging SET epc_rating    = NULL WHERE TRIM(epc_rating) = '';
UPDATE rentals_staging SET letting_agent = NULL WHERE TRIM(letting_agent) = '';
UPDATE rentals_staging SET furnished     = NULL WHERE TRIM(furnished) = '';
UPDATE rentals_staging SET service_charge_gbp = 0 WHERE service_charge_gbp IS NULL;

-- 3g. Derive lease_duration_days for analysis convenience
ALTER TABLE rentals_staging ADD COLUMN IF NOT EXISTS lease_duration_days INT;
UPDATE rentals_staging
SET lease_duration_days = lease_end_date - lease_start_date
WHERE lease_start_date IS NOT NULL AND lease_end_date IS NOT NULL;


-- ============================================================
-- STEP 4: Final validation before promoting to main table
-- ============================================================

-- 4a. Row count check
SELECT COUNT(*) AS clean_row_count FROM rentals_staging;

-- 4b. Distinct standardised property types
SELECT DISTINCT property_type FROM rentals_staging ORDER BY property_type;

-- 4c. Distinct standardised boroughs
SELECT DISTINCT borough FROM rentals_staging ORDER BY borough;

-- 4d. Rent range sanity check
SELECT
    MIN(monthly_rent_gbp) AS min_rent,
    MAX(monthly_rent_gbp) AS max_rent,
    ROUND(AVG(monthly_rent_gbp), 2) AS avg_rent
FROM rentals_staging;

-- 4e. Null summary post-clean
SELECT
    SUM(CASE WHEN epc_rating IS NULL THEN 1 ELSE 0 END) AS null_epc,
    SUM(CASE WHEN bedrooms IS NULL THEN 1 ELSE 0 END) AS null_bedrooms,
    SUM(CASE WHEN letting_agent IS NULL THEN 1 ELSE 0 END) AS null_agent
FROM rentals_staging;


-- ============================================================
-- STEP 5: Promote cleaned data to main table
-- ============================================================

INSERT INTO rentals
SELECT
    property_id, borough, postcode, property_type,
    bedrooms, bathrooms, monthly_rent_gbp,
    listing_date, lease_start_date, lease_end_date,
    status, letting_agent, landlord_type, epc_rating,
    year_built, service_charge_gbp, furnished
FROM rentals_staging
ON CONFLICT (property_id) DO NOTHING;

SELECT COUNT(*) AS final_row_count FROM rentals;
