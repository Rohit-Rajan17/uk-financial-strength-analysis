# Data dictionary

## Source (not in this repository)
Fliar Research, *UK Company Financials 2019–2025*, 3% sample: `uk_company_financials_2019_2025_sample.csv`, 100,000 company-years, 51,516 companies, 21 columns. Built from Companies House annual accounts. Licence CC BY-NC 4.0.

## Definitions
- **Equity ratio** = equity ÷ total assets, only where total assets are above zero.
- **State** (`state_10`): **Negative** = equity below zero; **Thin** = equity ratio 0 to under 10%; **Healthy** = 10% or more; **Unknown** = no usable assets figure.
- **Main (central) population**: GBP, fiscal year 2024, equity present, total assets above zero, accounts type not Dormant = **32,137** rows.
- **Equity-only basis**: GBP, FY2024, equity present (44,850 rows, or 44,921 in any currency). Used for the benchmark and the 17.7% figure.
- **Pseudo-sectors**: "Dormant company", "Non-trading company" and "Residents property management". Near-zero equity by design, so left out of sector rankings.
- **Extreme equity**: absolute equity above £1bn (33 rows, all large groups with positive equity).
- **Reliable group**: at least 30 companies.
- **Transition pair**: the same company in consecutive fiscal years, with period ends 300 to 430 days apart.
- **Adverse status** (validity test): proposal to strike off, liquidation, voluntary arrangement, administration or receiver, from the May 2026 register snapshot.
- **Size class**: from the accounts type of the latest accounts: Micro, Small, Medium, Large or group, Dormant, Unknown, Other.

## Pipeline tables

| Table | One row is | Built in |
|---|---|---|
| `raw_company_financials` | a CSV row, all columns as text | 01 / 01a |
| `stg_company_financials` | a company-year, typed, with key and CHECK rules | 02 |
| `stg_rejects` | a row that broke a rule (0 rows) | 02 |
| `dq_log` | a data-quality check and its count (19 rows) | 03 |
| `v_company_clean` (view) | a company-year with cleaned name, size class, flags, equity ratio and state | 04 |

## Star schema

| Table | One row is | Key columns |
|---|---|---|
| `dim_sector` | an SIC section (24, plus Unknown = 0) | `sector_key`, `sic_section`, `is_pseudo_sector`, `is_financial` |
| `dim_division` | an SIC division (89, plus Unknown) | `division_key`, `sic_division`, `sector_key` |
| `dim_region` | a region (12, plus Unknown) | `region_key`, `region` |
| `dim_size` | a size class (7) | `size_key`, `size_class` |
| `dim_date` | a day, 2017 to 2026 (3,652) | `date_key`, year, quarter, month |
| `dim_company` | a company (51,516) | `company_id`, `company_number` (8 characters, text), `legal_name_clean`, `incorporation_year`, `company_status` |
| `fact_company_year` | a company-year (100,000) | keys to every dimension, money figures, `equity_ratio`, `state_10`, flags, `in_central_population` |

"Unknown" members (key 0) keep companies that left the register in the data instead of losing them in joins.

## Results tables (used by Excel and Power BI)

`res_sector`, `res_region`, `res_size`, `res_sector_region`, `res_sector_rank_in_region`, `res_top_negative_large` (named companies, kept local), `res_pairs`, `res_cohort`, `res_concentration`, `res_wilson_region`, `res_wilson_sector_region`, `res_sensitivity`, `res_validity`, `res_concentration_variants`, `res_equity_basis`, `res_cohort_by_sector`. Each script says which table it builds and what it should contain.
