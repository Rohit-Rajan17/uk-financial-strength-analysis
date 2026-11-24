# Verification log

Every check made on the results, what it found, and what changed because of it. Script numbers refer to `sql/`.

## 1. Load, staging and data quality

| Check | Result | Action |
|---|---|---|
| Raw rows loaded (01) | 100,000 | – |
| Staged vs rejected rows (02) | 100,000 staged, 0 rejected, difference 0 | All typing and CHECK rules passed |
| Fill rates (01) | Equity 98.6%, total assets 72.9%, employees 79.4%, profit 3.8%, turnover 2.5% | No profit or margin analysis claimed |
| Rows by fiscal year (01) | 2025: 39,001; 2024: 45,544; 2023: 14,986; 2019–2022: 469 together | Results treated as FY2023–FY2025 only |
| Data-quality log (03) | 19 checks, e.g. 156 non-GBP rows, 20,420 rows with 0 employees, 13,339 dormant-accounts rows | Non-GBP rows excluded from £ figures |
| Population funnel (03) | 100,000 → GBP 99,844 → FY2024 45,473 → equity present 44,850 → assets > 0 32,970 → not dormant 32,137 | 32,137 = main population |
| Flags never blank (04) | 0 blank flags after a fix | Bug found in testing: six flags could be blank, so `NOT flag` filters would silently drop rows. Wrapped in `COALESCE` |
| Fact table vs clean view (06) | 100,000 rows; central assets £656,922,621,948 in both | – |

## 2. Trust tests

| Check | Result | Reading |
|---|---|---|
| Wilson 95% intervals by region (12a) | London 23.9% (22.9–25.0); only Wales (18.0–23.9) overlaps it | Only "London is higher" is claimed; no league table for the other regions |
| Wilson intervals for 147 sector × region groups, ranked by lower bound (12b) | 21 clearly above and 22 clearly below the 20.3% baseline, against about 3–4 each by chance | The pattern is real. Not adjusted for multiple comparisons |
| 3 × 3 sensitivity grid (12c) | Negative share 18.3–20.2%; London gap 4.4–5.0 points; accommodation 32.2–32.6%; thin share 10.7–19.5% | Negative-equity findings stable. Thin share depends on the cut-off, so the cut-off is always stated |
| Validity against May 2026 register status (13) | Adverse status: negative 2.46%, healthy 1.79% (1.37×), thin 1.30%. Left the register: 18.7% vs 18.9% | A weak screen, not a predictor of failure |
| Benchmark against the publisher (14) | Equity-present basis: overall 17.7 (publisher 17.8), London 20.1 (20.0), real estate 24.1 (24.1), finance 13.7 (14.0), accommodation 28.7 (27.0), Northern Ireland 13.3 (11.1) | All six published figures fall inside the sample's 95% intervals |

## 3. Verification reruns

| Check | Result | Action |
|---|---|---|
| Concentration without suspect rows (15a) | Top 1% holds 53.3%, 53.3%, 51.8% and 51.5% of the deficit under four rule sets; total deficit moves from £0.79bn to £1.14bn | Quote shares ("about half"), never the pound total |
| Findings on the broader equity-only basis (15b) | London 23.9% on both bases; accommodation 31.7% vs 32.6%; real estate 26.9% vs 27.1%; finance 15.4% vs 14.2% | Findings survive the 11,880 rows with no assets. Electricity and gas (n = 100) moved 6 points, so it is not ranked |
| Extreme-equity rows (15c) | 33 rows over £1bn, all positive equity, real large groups | Kept. They cannot affect negative-equity shares. Medians used, never means |
| Equity above assets (15c) | 73 central rows, largest gap £86,286, all positive equity | Immaterial; logged and kept |
| London's share (15c) | 26.6% of companies (publisher: about 26%). Share of assets 45.2%, falling to 34.6% without 5 groups | The publisher's 71%-of-assets figure did not reproduce and is not quoted |
| Age within sector (15d) | Newest companies have a higher negative share than the oldest in 15 of 15 sectors | Age is a real second factor, not sector mix. Survivorship still applies |
| Reconciliation (15e) | 14 of 14 checks agree: row counts, asset sums and every results table add up to its population | – |

## 4. Other layers

| Check | Result |
|---|---|
| Excel workbook | Full local version: 22 tabs, 16,047 formulas, 0 errors, 27 of 27 reconciliation checks agree with SQL. Public copy in `excel/`: 18 summary tabs, 2,531 formulas, 0 errors, 315 check cells all OK |
| Power BI | Every figure in the report's data tables matches the SQL results (regions, 147 sector × region groups, sectors, size, cohorts, transitions, validity, headline) |
| Full rerun | All 26 scripts re-run end to end from the raw CSV on 24 Nov 2026; every expected value listed in the scripts was reproduced |

## Claims withdrawn or narrowed

- **"London holds 71% of assets"**: withdrawn (the sample gives 45.2%, and it depends on a few groups).
- **Electricity and gas as a weak sector**: not ranked (n = 90 to 100, unstable between bases).
- **"Wales is the second-weakest region"**: withdrawn (its interval overlaps most regions).
- **Concentration in pounds**: replaced by shares.
