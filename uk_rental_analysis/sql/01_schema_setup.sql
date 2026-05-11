-- ============================================================
-- UK Rental Market Analysis — London
-- Script 1: Schema Setup & Table Creation
-- Author: Oladele Desmond-Eke
-- ============================================================

-- Create database (run once)
-- CREATE DATABASE uk_rental_analysis;
-- \c uk_rental_analysis;

DROP TABLE IF EXISTS rentals;

CREATE TABLE rentals (
    property_id       VARCHAR(10)    PRIMARY KEY,
    borough           VARCHAR(60)    NOT NULL,
    postcode          VARCHAR(10),
    property_type     VARCHAR(30)    NOT NULL,
    bedrooms          SMALLINT,
    bathrooms         SMALLINT,
    monthly_rent_gbp  NUMERIC(10,2)  NOT NULL,
    listing_date      DATE,
    lease_start_date  DATE,
    lease_end_date    DATE,
    status            VARCHAR(20),
    letting_agent     VARCHAR(50),
    landlord_type     VARCHAR(40),
    epc_rating        CHAR(1),
    year_built        SMALLINT,
    service_charge_gbp NUMERIC(8,2)  DEFAULT 0,
    furnished         VARCHAR(20)
);

-- After creating the table, load the clean CSV:
-- \COPY rentals FROM 'data/cleaned/london_rentals_clean.csv' WITH (FORMAT csv, HEADER true);
