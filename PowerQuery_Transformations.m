// ============================================================
// POWER QUERY M CODE — Bank Loan Default Risk Dashboard
// In Power BI: Transform Data > Advanced Editor
// Paste this code to apply all transformations automatically
// ============================================================

let
    // --------------------------------------------------------
    // STEP 1: Load CSV source
    // Change the file path to match your local file location
    // --------------------------------------------------------
    Source = Csv.Document(
        File.Contents("C:\PowerBI\BankLoanRisk\loan_data.csv"),
        [
            Delimiter = ",",
            Columns = 27,
            Encoding = 65001,
            QuoteStyle = QuoteStyle.None
        ]
    ),

    // --------------------------------------------------------
    // STEP 2: Promote first row to headers
    // --------------------------------------------------------
    PromotedHeaders = Table.PromoteHeaders(Source, [PromoteAllScalars = true]),

    // --------------------------------------------------------
    // STEP 3: Set correct data types for all columns
    // --------------------------------------------------------
    TypedTable = Table.TransformColumnTypes(PromotedHeaders, {
        {"LoanID",               type text},
        {"IssueDate",            type date},
        {"IssueYear",            Int64.Type},
        {"IssueMonth",           Int64.Type},
        {"LoanAmount",           Int64.Type},
        {"Term_Months",          Int64.Type},
        {"InterestRate",         type number},
        {"Grade",                type text},
        {"Purpose",              type text},
        {"HomeOwnership",        type text},
        {"EmploymentLength",     type text},
        {"AnnualIncome",         Int64.Type},
        {"DTI",                  type number},
        {"RevolvingUtilization", type number},
        {"CreditHistoryYears",   type number},
        {"Delinquencies2Yrs",    Int64.Type},
        {"OpenAccounts",         Int64.Type},
        {"DefaultFlag",          Int64.Type},
        {"LoanStatus",           type text},
        {"DTI_Segment",          type text},
        {"RiskTier",             type text},
        {"HighRevolvingUtil",    Int64.Type},
        {"ThinFile",             Int64.Type},
        {"HighDTI",              Int64.Type},
        {"LoanToIncome",         type number},
        {"DefaultProbability",   type number},
        {"CapitalAtRisk",        Int64.Type}
    }),

    // --------------------------------------------------------
    // STEP 4: Add Month Name column (for time series axis)
    // --------------------------------------------------------
    AddMonthName = Table.AddColumn(
        TypedTable,
        "MonthName",
        each Date.ToText([IssueDate], "MMM yyyy"),
        type text
    ),

    // --------------------------------------------------------
    // STEP 5: Add Month Sort column (for correct time ordering)
    // --------------------------------------------------------
    AddMonthSort = Table.AddColumn(
        AddMonthName,
        "MonthSort",
        each [IssueYear] * 100 + [IssueMonth],
        Int64.Type
    ),

    // --------------------------------------------------------
    // STEP 6: Add DTI Risk Flag (plain text for slicers)
    // --------------------------------------------------------
    AddDTIFlag = Table.AddColumn(
        AddMonthSort,
        "DTI_Risk_Flag",
        each if [DTI] > 43 then "Breach (>43%)"
             else if [DTI] > 30 then "Elevated (30-43%)"
             else "Acceptable (<30%)",
        type text
    ),

    // --------------------------------------------------------
    // STEP 7: Add Loan Size Bucket (for distribution visuals)
    // --------------------------------------------------------
    AddLoanBucket = Table.AddColumn(
        AddDTIFlag,
        "LoanSizeBucket",
        each if [LoanAmount] >= 35000 then "$35K+"
             else if [LoanAmount] >= 25000 then "$25K-$35K"
             else if [LoanAmount] >= 15000 then "$15K-$25K"
             else if [LoanAmount] >= 5000  then "$5K-$15K"
             else "Under $5K",
        type text
    ),

    // --------------------------------------------------------
    // STEP 8: Add Interest Rate Tier
    // --------------------------------------------------------
    AddRateTier = Table.AddColumn(
        AddLoanBucket,
        "InterestRateTier",
        each if [InterestRate] >= 25    then "Very High (25%+)"
             else if [InterestRate] >= 18 then "High (18-25%)"
             else if [InterestRate] >= 12 then "Moderate (12-18%)"
             else if [InterestRate] >= 7  then "Low (7-12%)"
             else "Very Low (<7%)",
        type text
    ),

    // --------------------------------------------------------
    // STEP 9: Add Credit History Bucket
    // --------------------------------------------------------
    AddCreditBucket = Table.AddColumn(
        AddRateTier,
        "CreditHistoryBucket",
        each if [CreditHistoryYears] < 3   then "< 3 years (Thin File)"
             else if [CreditHistoryYears] < 7  then "3-7 years"
             else if [CreditHistoryYears] < 15 then "7-15 years"
             else "15+ years (Seasoned)",
        type text
    ),

    // --------------------------------------------------------
    // STEP 10: Add Employment Length Sort Order
    // --------------------------------------------------------
    AddEmpSort = Table.AddColumn(
        AddCreditBucket,
        "EmpLengthSort",
        each if [EmploymentLength] = "< 1 year"  then 0
             else if [EmploymentLength] = "1 year"    then 1
             else if [EmploymentLength] = "2 years"   then 2
             else if [EmploymentLength] = "3 years"   then 3
             else if [EmploymentLength] = "4 years"   then 4
             else if [EmploymentLength] = "5 years"   then 5
             else if [EmploymentLength] = "6 years"   then 6
             else if [EmploymentLength] = "7 years"   then 7
             else if [EmploymentLength] = "8 years"   then 8
             else if [EmploymentLength] = "9 years"   then 9
             else if [EmploymentLength] = "10+ years" then 10
             else -1,
        Int64.Type
    ),

    // --------------------------------------------------------
    // STEP 11: Add Grade Sort Order (A=1, F=6)
    // --------------------------------------------------------
    AddGradeSort = Table.AddColumn(
        AddEmpSort,
        "GradeSort",
        each if [Grade] = "A" then 1
             else if [Grade] = "B" then 2
             else if [Grade] = "C" then 3
             else if [Grade] = "D" then 4
             else if [Grade] = "E" then 5
             else if [Grade] = "F" then 6
             else 7,
        Int64.Type
    ),

    // --------------------------------------------------------
    // STEP 12: Add Quarter column
    // --------------------------------------------------------
    AddQuarter = Table.AddColumn(
        AddGradeSort,
        "Quarter",
        each "Q" & Text.From(Date.QuarterOfYear([IssueDate])) & " " & Text.From([IssueYear]),
        type text
    ),

    // --------------------------------------------------------
    // STEP 13: Add Default Label (for donut chart)
    // --------------------------------------------------------
    AddDefaultLabel = Table.AddColumn(
        AddQuarter,
        "DefaultLabel",
        each if [DefaultFlag] = 1 then "Defaulted" else "Fully Paid",
        type text
    ),

    // --------------------------------------------------------
    // STEP 14: Replace HomeOwnership blanks
    // --------------------------------------------------------
    CleanHomeOwnership = Table.ReplaceValue(
        AddDefaultLabel,
        "",
        "Unknown",
        Replacer.ReplaceValue,
        {"HomeOwnership"}
    ),

    // --------------------------------------------------------
    // STEP 15: Remove any rows with null LoanID (data quality)
    // --------------------------------------------------------
    RemoveNullIDs = Table.SelectRows(
        CleanHomeOwnership,
        each [LoanID] <> null and [LoanID] <> ""
    ),

    // --------------------------------------------------------
    // STEP 16: Sort by IssueDate descending (most recent first)
    // --------------------------------------------------------
    SortedTable = Table.Sort(
        RemoveNullIDs,
        {{"IssueDate", Order.Descending}}
    )

in
    SortedTable
