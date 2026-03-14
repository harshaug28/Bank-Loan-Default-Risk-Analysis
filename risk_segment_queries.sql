-- ============================================================
-- Bank Loan Default Risk Analysis — SQL Queries
-- Project: Financial Sector Data Analytics Portfolio
-- Tools:   SQLite / PostgreSQL / BigQuery compatible
-- ============================================================


-- ============================================================
-- SECTION 1: Portfolio Overview
-- ============================================================

-- 1.1 Overall default rate and portfolio summary
SELECT
    COUNT(*)                                              AS total_loans,
    SUM(default_flag)                                     AS total_defaults,
    ROUND(AVG(default_flag) * 100, 2)                    AS default_rate_pct,
    ROUND(SUM(loan_amnt) / 1000000.0, 1)                 AS total_portfolio_m,
    ROUND(SUM(CASE WHEN default_flag = 1 THEN loan_amnt ELSE 0 END) / 1000000.0, 1) 
                                                          AS capital_at_risk_m,
    ROUND(AVG(loan_amnt), 0)                             AS avg_loan_amnt,
    ROUND(AVG(annual_inc), 0)                            AS avg_annual_income,
    ROUND(AVG(dti), 2)                                   AS avg_dti,
    ROUND(AVG(int_rate), 2)                              AS avg_interest_rate_pct
FROM loans;


-- 1.2 Default trend by year (requires issue_year column)
SELECT
    issue_year,
    COUNT(*)                                             AS total_loans,
    SUM(default_flag)                                    AS defaults,
    ROUND(AVG(default_flag) * 100, 2)                   AS default_rate_pct,
    ROUND(SUM(loan_amnt) / 1000000.0, 1)                AS volume_m
FROM loans
GROUP BY issue_year
ORDER BY issue_year;


-- ============================================================
-- SECTION 2: Risk Segmentation
-- ============================================================

-- 2.1 Default rate and exposure by loan grade
SELECT
    grade,
    COUNT(*)                                             AS total_loans,
    SUM(default_flag)                                    AS total_defaults,
    ROUND(AVG(default_flag) * 100, 2)                   AS default_rate_pct,
    ROUND(SUM(loan_amnt) / 1000000.0, 1)                AS total_exposure_m,
    ROUND(SUM(CASE WHEN default_flag = 1 THEN loan_amnt ELSE 0 END) / 1000000.0, 1) 
                                                         AS capital_at_risk_m,
    ROUND(AVG(int_rate), 2)                              AS avg_interest_rate_pct,
    ROUND(AVG(annual_inc), 0)                            AS avg_income
FROM loans
GROUP BY grade
ORDER BY grade;


-- 2.2 Default rate by DTI segment
SELECT
    CASE
        WHEN dti > 43  THEN '4_DTI > 43% (Very High)'
        WHEN dti > 30  THEN '3_DTI 30-43% (High)'
        WHEN dti > 20  THEN '2_DTI 20-30% (Moderate)'
        ELSE                '1_DTI < 20% (Low)'
    END                                                  AS dti_segment,
    COUNT(*)                                             AS total_loans,
    ROUND(AVG(default_flag) * 100, 2)                   AS default_rate_pct,
    ROUND(SUM(loan_amnt) / 1000000.0, 1)                AS exposure_m,
    ROUND(SUM(CASE WHEN default_flag = 1 THEN loan_amnt ELSE 0 END) / 1000000.0, 1)
                                                         AS capital_at_risk_m
FROM loans
GROUP BY dti_segment
ORDER BY dti_segment;


-- 2.3 Default rate by revolving utilization bucket
SELECT
    CASE
        WHEN revol_util >= 90  THEN '5_Util >= 90%'
        WHEN revol_util >= 75  THEN '4_Util 75-90%'
        WHEN revol_util >= 50  THEN '3_Util 50-75%'
        WHEN revol_util >= 25  THEN '2_Util 25-50%'
        ELSE                        '1_Util < 25%'
    END                                                  AS util_bucket,
    COUNT(*)                                             AS total_loans,
    ROUND(AVG(default_flag) * 100, 2)                   AS default_rate_pct,
    ROUND(SUM(loan_amnt) / 1000000.0, 1)                AS exposure_m
FROM loans
GROUP BY util_bucket
ORDER BY util_bucket;


-- 2.4 Default rate by loan purpose
SELECT
    purpose,
    COUNT(*)                                             AS total_loans,
    ROUND(AVG(default_flag) * 100, 2)                   AS default_rate_pct,
    ROUND(SUM(loan_amnt) / 1000000.0, 1)                AS exposure_m,
    ROUND(AVG(loan_amnt), 0)                             AS avg_loan_size
FROM loans
GROUP BY purpose
ORDER BY default_rate_pct DESC;


-- 2.5 Default rate by employment length
SELECT
    emp_length,
    COUNT(*)                                             AS total_loans,
    ROUND(AVG(default_flag) * 100, 2)                   AS default_rate_pct,
    ROUND(AVG(annual_inc), 0)                            AS avg_income,
    ROUND(AVG(dti), 2)                                   AS avg_dti
FROM loans
GROUP BY emp_length
ORDER BY default_rate_pct DESC;


-- ============================================================
-- SECTION 3: High-Risk Borrower Identification
-- ============================================================

-- 3.1 Multi-factor high-risk segment identification
SELECT
    CASE
        WHEN grade IN ('E','F','G') AND dti > 35  THEN 'Critical: Subprime + High DTI'
        WHEN grade IN ('E','F','G')                THEN 'High: Subprime Grade'
        WHEN dti > 43                              THEN 'High: DTI Breach'
        WHEN revol_util >= 75 AND grade IN ('D','E','F','G') 
                                                   THEN 'High: High Util + Poor Grade'
        WHEN revol_util >= 75                      THEN 'Medium: High Revolving Util'
        WHEN credit_history_years < 3              THEN 'Medium: Thin File'
        ELSE                                            'Standard'
    END                                                  AS risk_segment,
    COUNT(*)                                             AS total_loans,
    ROUND(AVG(default_flag) * 100, 2)                   AS default_rate_pct,
    ROUND(SUM(loan_amnt) / 1000000.0, 1)                AS exposure_m
FROM loans
GROUP BY risk_segment
ORDER BY default_rate_pct DESC;


-- 3.2 Top 10% riskiest individual loans (for manual review queue)
SELECT
    id,
    grade,
    purpose,
    loan_amnt,
    annual_inc,
    dti,
    int_rate,
    revol_util,
    credit_history_years,
    default_flag,
    predicted_default_prob           -- from model output, joined in
FROM loans
WHERE predicted_default_prob >= 0.70
ORDER BY predicted_default_prob DESC
LIMIT 100;


-- ============================================================
-- SECTION 4: Business Impact Quantification
-- ============================================================

-- 4.1 Dollar impact of DTI cap policy (cap at 43%)
WITH dti_impact AS (
    SELECT
        CASE WHEN dti > 43 THEN 'Would be declined (DTI breach)' ELSE 'Approved' END AS policy_outcome,
        COUNT(*)                                                     AS loans,
        SUM(default_flag)                                            AS actual_defaults,
        ROUND(SUM(CASE WHEN default_flag=1 THEN loan_amnt ELSE 0 END)/1000000.0, 1)
                                                                     AS default_exposure_m
    FROM loans
    GROUP BY policy_outcome
)
SELECT
    policy_outcome,
    loans,
    actual_defaults,
    default_exposure_m,
    ROUND(default_exposure_m * 100.0 / SUM(default_exposure_m) OVER(), 1) AS pct_of_total_defaults
FROM dti_impact;


-- 4.2 Early intervention potential (revolving util > 75%)
SELECT
    'Total portfolio defaults'          AS cohort,
    SUM(default_flag)                   AS defaults,
    ROUND(SUM(CASE WHEN default_flag=1 THEN loan_amnt ELSE 0 END)/1000000.0, 1) AS capital_at_risk_m
FROM loans
UNION ALL
SELECT
    'High utilization defaults (util > 75%)',
    SUM(default_flag),
    ROUND(SUM(CASE WHEN default_flag=1 THEN loan_amnt ELSE 0 END)/1000000.0, 1)
FROM loans
WHERE revol_util >= 75
UNION ALL
SELECT
    'Recoverable via intervention (22% of util>75%)',
    ROUND(SUM(default_flag) * 0.22, 0),
    ROUND(SUM(CASE WHEN default_flag=1 THEN loan_amnt ELSE 0 END)*0.22/1000000.0, 1)
FROM loans
WHERE revol_util >= 75;


-- 4.3 Combined business case summary
SELECT
    'DTI Cap Policy (>43%)'            AS recommendation,
    ROUND(SUM(CASE WHEN dti > 43 AND default_flag=1 THEN loan_amnt ELSE 0 END)/1000000.0, 1) 
                                        AS potential_savings_m,
    'High impact — underwriting change' AS implementation
FROM loans
UNION ALL
SELECT
    'Dynamic Rate Repricing (Grade D-F)',
    ROUND(COUNT(*) * 0.018 * AVG(loan_amnt) / 1000000.0, 1),   -- 180bps × portfolio
    'Medium — pricing model update'
FROM loans WHERE grade IN ('D','E','F')
UNION ALL
SELECT
    'Early Intervention (util > 75%)',
    ROUND(SUM(CASE WHEN revol_util>=75 AND default_flag=1 THEN loan_amnt*0.22 ELSE 0 END)/1000000.0, 1),
    'High impact — ops program'
FROM loans
UNION ALL
SELECT
    'Secured Products for Thin Files (<3yr history)',
    ROUND(SUM(CASE WHEN credit_history_years<3 AND default_flag=1 THEN loan_amnt*0.40 ELSE 0 END)/1000000.0, 1),
    'Medium — product routing'
FROM loans;


-- ============================================================
-- SECTION 5: Cohort & Cross-Tabulation Analysis
-- ============================================================

-- 5.1 Default rate by grade × home ownership (cross-tab)
SELECT
    grade,
    home_ownership,
    COUNT(*)                            AS loans,
    ROUND(AVG(default_flag)*100, 1)    AS default_rate_pct
FROM loans
WHERE home_ownership IN ('RENT','MORTGAGE','OWN')
GROUP BY grade, home_ownership
ORDER BY grade, home_ownership;


-- 5.2 Average DTI and income by default outcome
SELECT
    CASE WHEN default_flag = 1 THEN 'Defaulted' ELSE 'Fully Paid' END AS outcome,
    COUNT(*)                            AS loans,
    ROUND(AVG(dti), 2)                 AS avg_dti,
    ROUND(AVG(annual_inc), 0)          AS avg_income,
    ROUND(AVG(loan_amnt), 0)           AS avg_loan_amnt,
    ROUND(AVG(int_rate), 2)            AS avg_interest_rate,
    ROUND(AVG(revol_util), 1)          AS avg_revol_util,
    ROUND(AVG(credit_history_years), 1) AS avg_credit_history_yrs
FROM loans
GROUP BY outcome;


-- 5.3 Month-over-month default velocity (requires issue_month + issue_year)
SELECT
    issue_year,
    issue_month,
    COUNT(*)                                    AS new_loans,
    SUM(default_flag)                           AS new_defaults,
    ROUND(AVG(default_flag)*100, 2)            AS default_rate_pct,
    ROUND(SUM(loan_amnt)/1000000.0, 1)         AS volume_m,
    ROUND(
        AVG(default_flag)*100 - LAG(AVG(default_flag)*100, 1)
        OVER (ORDER BY issue_year, issue_month), 2
    )                                            AS mom_default_change_pp
FROM loans
GROUP BY issue_year, issue_month
ORDER BY issue_year, issue_month;
