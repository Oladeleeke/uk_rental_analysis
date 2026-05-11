# Data Dictionary — London Rentals Dataset

| Field | Type | Description | Valid Values / Format |
|---|---|---|---|
| `property_id` | VARCHAR | Unique property identifier | PROP0001–PROP0500 |
| `borough` | VARCHAR | London borough | 15 London boroughs (see below) |
| `postcode` | VARCHAR | UK postcode | Standard UK format e.g. E8 1AA |
| `property_type` | VARCHAR | Type of property | Flat, Studio, Terraced House, Semi-Detached House, Detached House, Maisonette |
| `bedrooms` | INT | Number of bedrooms | 0 (Studio) to 5 |
| `bathrooms` | INT | Number of bathrooms | 1 to 4 |
| `monthly_rent_gbp` | NUMERIC | Monthly rent in GBP | £1,000–£6,000 typical range |
| `listing_date` | DATE | Date property listed | 2022-01-01 to 2024-12-31 |
| `lease_start_date` | DATE | Tenancy start date | Typically 7–60 days after listing |
| `lease_end_date` | DATE | Tenancy end date | 12 or 24 months after start |
| `status` | VARCHAR | Current listing status | Let, Available, Void, Under Offer |
| `letting_agent` | VARCHAR | Managing letting agent | Foxtons, Savills, Knight Frank, Countrywide, Hunters, Purplebricks, Direct, Haart |
| `landlord_type` | VARCHAR | Type of landlord | Private Landlord, Housing Association, Corporate Landlord, Estate Agency |
| `epc_rating` | CHAR(1) | Energy Performance Certificate rating | A (most efficient) to E |
| `year_built` | INT | Year property was built | 1900–2020 |
| `service_charge_gbp` | NUMERIC | Monthly service charge (flats/maisonettes) | £0–£300; 0 for houses |
| `furnished` | VARCHAR | Furnishing status | Furnished, Unfurnished, Part Furnished |

---

## Boroughs Included

Camden, Ealing, Greenwich, Hackney, Hammersmith and Fulham, Haringey,
Islington, Lambeth, Lewisham, Newham, Southwark, Tower Hamlets,
Waltham Forest, Wandsworth, Brent
