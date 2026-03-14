# 📊 Power BI Dashboard Setup Guide
## Bank Loan Default Risk Analysis

---

## 📁 Files in This Package

| File | Purpose |
|------|---------|
| `loan_data.csv` | Sample dataset — 1,000 loans with 27 columns |
| `DAX_Measures.dax` | All 40+ DAX measures — copy-paste into Power BI |
| `PowerQuery_Transformations.m` | Power Query M code — auto-transforms your data |
| `PowerBI_Setup_Guide.md` | This file — step-by-step build instructions |

---

## 🚀 STEP-BY-STEP SETUP

---

### STEP 1 — Open Power BI Desktop
Download free from: https://powerbi.microsoft.com/desktop

---

### STEP 2 — Load the Data

1. Click **Home → Get Data → Text/CSV**
2. Browse to `loan_data.csv` and click **Open**
3. Click **Transform Data** (do NOT click Load yet)

---

### STEP 3 — Apply Power Query Transformations

1. In Power Query Editor, click **Home → Advanced Editor**
2. Delete all existing code
3. Open `PowerQuery_Transformations.m` in a text editor
4. **Update line 10** — change the file path to match where you saved `loan_data.csv`:
   ```
   File.Contents("C:\YOUR\ACTUAL\PATH\loan_data.csv")
   ```
5. Paste the full M code into Advanced Editor
6. Click **Done**
7. Click **Close & Apply**

---

### STEP 4 — Create a Measures Table

1. Click **Home → Enter Data**
2. Create a blank table with one column named `Placeholder`
3. Name the table `_Measures`
4. Click **Load**
5. In the Fields pane, right-click `_Measures` → **Hide in report view** (optional — keeps it tidy)

---

### STEP 5 — Add All DAX Measures

Open `DAX_Measures.dax` in a text editor.

For **each measure block**:
1. In Power BI, click **Modeling → New Measure**
2. Copy the measure name and formula
3. Paste into the formula bar
4. Press **Enter**
5. In the Properties pane, set the Home Table to `_Measures`

**Priority order — add these first (used by most visuals):**
1. `Total Loans`
2. `Total Defaults`
3. `Default Rate %`
4. `Total Portfolio $`
5. `Capital at Risk $`
6. `Avg DTI`
7. `Avg Interest Rate`

Then add the rest as you build each page.

---

### STEP 6 — Build the Dashboard (4 Pages)

---

#### PAGE 1 — Executive Overview

**Background color:** White | **Canvas size:** 1280 × 720

**Row 1 — KPI Cards (4 across the top)**

| Card | Measure | Format |
|------|---------|--------|
| Total Loans | `Total Loans` | Whole number |
| Default Rate | `Default Rate %` | Percentage 1 decimal |
| Capital at Risk | `Capital at Risk $` | Currency, 0 decimals |
| Total Portfolio | `Total Portfolio $` | Currency, 0 decimals |

Steps:
- Insert → Card visual
- Drag measure into **Fields**
- Format → Data label → Font size 28, Bold
- Format → Category label → Font size 11, color #888780

**Row 2 — Main Visuals**

*Left (60% width) — Line + Clustered Column Chart:*
- X-axis: `IssueYear`
- Column Y-axis: `Total Portfolio $`
- Line Y-axis: `Default Rate %`
- Title: "Default Rate & Loan Volume Trend (2019–2024)"
- Column color: #B5D4F4 | Line color: #E24B4A | Line width: 2.5px

*Right (40% width) — Donut Chart:*
- Legend: `DefaultLabel`
- Values: `Total Loans`
- Colors: Fully Paid = #1D9E75 | Defaulted = #E24B4A
- Title: "Loan Outcome Distribution"

**Row 3 — Secondary Visuals**

*Left — Clustered Bar Chart:*
- Y-axis: `Purpose`
- X-axis: `Default Rate %`
- Sort by Default Rate descending
- Color: Use conditional formatting — red for >25%, amber for 15-25%, green <15%
- Title: "Default Rate by Loan Purpose"

*Right — Clustered Bar Chart:*
- Y-axis: `Grade` (sort by GradeSort)
- X-axis: `Default Rate %`
- Color: #E24B4A for grades E/F, #EF9F27 for C/D, #1D9E75 for A/B
- Title: "Default Rate by Loan Grade"

**Slicers (top right corner):**
- Slicer 1: `IssueYear` — Dropdown style
- Slicer 2: `Grade` — Tile/button style
- Slicer 3: `Purpose` — Dropdown style

---

#### PAGE 2 — Risk Segmentation

**Row 1 — Risk KPI Cards**

| Card | Measure |
|------|---------|
| DTI Breach Rate | `DTI Breach Default Rate` |
| High Revol Util Default Rate | `High Revol Util Default Rate` |
| Thin File Count | `Thin File Count` |
| Debt Consol Default Rate | `Debt Consol Default Rate` |

**Main Visual — Matrix Table:**
- Rows: `Grade`
- Columns: `DTI_Segment`
- Values: `Default Rate %`
- Conditional formatting: Background color scale (green=low, red=high)
- Title: "Default Rate Heatmap — Grade × DTI Segment"

**Secondary Visual — Stacked Bar:**
- Y-axis: `RiskTier`
- X-axis: `Total Loans`
- Legend: `DefaultLabel`
- Title: "Loan Count by Risk Tier"

**Scatter Plot:**
- X-axis: `DTI` (average)
- Y-axis: `Default Rate %`
- Size: `Total Portfolio $`
- Legend: `Grade`
- Title: "DTI vs Default Rate by Grade"

**Slicers:**
- `HomeOwnership` (tile buttons)
- `EmploymentLength` (dropdown, sort by EmpLengthSort)

---

#### PAGE 3 — Business Impact

**Row 1 — Impact Cards**

| Card | Measure | Border color |
|------|---------|--------------|
| DTI Cap Saves | `DTI Cap Savings $` | Red |
| Intervention Saves | `Early Intervention Savings $` | Amber |
| Repricing Gains | `Repricing NIM Gain $` | Blue |
| Secured Products Save | `Secured Product Savings $` | Green |

**Add Total Impact Card:**
- Measure: `Total Business Impact $`
- Font size: 36
- Label: "Combined Annual Impact"

**Visual — Waterfall Chart:**
- Category: manually enter the 4 recommendation names
- Y-axis: savings values from each measure
- Title: "Business Case — Recommendations Impact ($)"

**Visual — 100% Stacked Bar:**
- Y-axis: `DTI_Risk_Flag`
- X-axis: `Total Loans`
- Legend: `DefaultLabel`
- Title: "Default Distribution by DTI Risk Flag"

**What-If Scenario — DTI Threshold Slicer:**
1. Go to **Modeling → New Parameter**
2. Name: `DTI_Threshold`
3. Data type: Whole number
4. Minimum: 20, Maximum: 60, Default: 43
5. Add **Card visuals** showing:
   - `Loans Rejected at Threshold`
   - `Defaults Prevented at Threshold`
   - `Savings at Threshold $`

---

#### PAGE 4 — Deep Dive / Drillthrough

**Set up Drillthrough:**
1. On this page, drag `Grade` to **Drillthrough filters**
2. Users can right-click any Grade bar on Page 1 → Drillthrough → Deep Dive

**Visuals on this page:**

*Top row:*
- Card: `Default Rate %` (for selected grade)
- Card: `Capital at Risk $`
- Card: `Total Loans`

*Middle row:*
- Bar: Default rate by `Purpose` (filtered to selected grade)
- Bar: Default rate by `EmploymentLength`
- Line: `Default Rate %` by `IssueYear`

*Bottom row:*
- Table with columns: `Purpose`, `Total Loans`, `Total Defaults`, `Default Rate %`, `Capital at Risk $`
- Sort by Default Rate descending

**Back button:** Insert → Buttons → Back (top-left corner)

---

### STEP 7 — Format & Polish

**Consistent colors (use these exactly):**
```
Default / High Risk:    #E24B4A  (Red)
Warning / Medium Risk:  #EF9F27  (Amber)
Safe / Low Risk:        #1D9E75  (Teal/Green)
Informational / Volume: #3B8BD4  (Blue)
Neutral / Background:   #888780  (Gray)
Card backgrounds:       #F5F5F0  (Light gray surface)
```

**Typography:**
- Titles: Segoe UI, 12pt, Bold, color #2C2C2A
- Axis labels: Segoe UI, 10pt, color #888780
- Card values: Segoe UI, 24-28pt, Bold
- Card labels: Segoe UI, 11pt, color #888780

**Page navigation (optional):**
1. Insert → Buttons → Blank
2. Add icon or text label (Overview / Risk / Impact / Deep Dive)
3. In Action settings → Type: Page navigation → Destination: target page

---

### STEP 8 — Publish to Power BI Service

1. Click **File → Publish → Publish to Power BI**
2. Select your workspace
3. After publishing, go to app.powerbi.com
4. Click **Share** to get a public link for your LinkedIn/GitHub

---

## 🎨 Dashboard Page Summary

| Page | Purpose | Key Visual |
|------|---------|-----------|
| 1 – Executive Overview | Top-level KPIs + trends | Line+Column combo, Donut |
| 2 – Risk Segmentation | Segment analysis | Matrix heatmap, Scatter |
| 3 – Business Impact | $ value of recommendations | Waterfall, What-If slider |
| 4 – Deep Dive | Drillthrough by grade | Filtered table + bar charts |

---

## ❓ Troubleshooting

**"Cannot find column" error:**
→ Check column names in Power Query match exactly (case-sensitive in DAX)

**Measures showing blank:**
→ Make sure the measures table `_Measures` exists and measures are assigned to it

**Date axis showing wrong order:**
→ Sort `MonthName` column by `MonthSort` column:
   Fields pane → MonthName → Column Tools → Sort by Column → MonthSort

**Drillthrough not working:**
→ Ensure the drillthrough field on Page 4 matches exactly what's used on Page 1

---

## 📤 Sharing on LinkedIn & GitHub

**For GitHub:**
- Export PDF: File → Export → Export to PDF → save as `dashboard_preview.pdf`
- Screenshot each page → save as PNG → add to GitHub README

**For LinkedIn:**
- Publish to Power BI Service → Share → Get Link
- Post the public link in your LinkedIn post comments
- Use a screenshot of Page 1 as the post image

---

*Project: Bank Loan Default Risk Analysis | Tools: Power BI Desktop, DAX, Power Query M*
