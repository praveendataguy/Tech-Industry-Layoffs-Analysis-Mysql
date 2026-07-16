# TECH industry global Layoffs Data Cleaning & Exploratory Data Analysis (EDA)

This repository contains a two-part SQL portfolio project focused on cleaning and analyzing a real-world tech industry layoffs dataset. Using **MySQL 8.0**, the raw data was transformed from a highly inconsistent, messy state into a structured, validated dataset ready to drive meaningful analytical insights.

---

## 📁 Dataset Information

* **Key Fields:** `company`, `location`, `industry`, `total_laid_off`, `percentage_laid_off`, `date`, `stage`, `country`, `funds_raised_millions`

---

## 🧹 Phase 1: Data Cleaning (Data Wrangling)
Raw databases are notoriously messy. The primary objective of this phase was to construct an active pipeline to standardize the schema and eliminate redundant noise without risking the original raw dataset.

### Key Steps Performed:
1. **Staging Environment:** Created a staging table (`layoffs_staging`) to safely clean data while keeping the raw backup intact.
2. **Duplicate Detection & Removal:** Built partitions utilizing `ROW_NUMBER()` across all fields. Created a physical `layoffs_staging2` table to safely bypass MySQL's read-only CTE limitations, successfully pruning duplicate rows.
3. **Data Standardization:**
   * Consolidated duplicate industry terms (e.g., merging variants like `Crypto Currency` and `CryptoCurrency` into a single `'Crypto'` value).
   * Fixed trailing punctuation from geographic fields (e.g., trimming `'United States.'` to `'United States'`).
   * Cleaned and unified empty or blank records to standard `NULL` database values.
   * Populated missing properties using a self-join to infer data where identical company profiles existed.
4. **Time Series Formatting:** Converted the string-typed `date` column into a validated standard SQL `DATE` format (`YYYY-MM-DD`).
5. **Schema Pruning:** Removed columns (like temporary row indexes) and deleted records lacking critical metrics (where both `total_laid_off` and `percentage_laid_off` were completely null).

---

## 📊 Phase 2: Exploratory Data Analysis (EDA)
With a reliable, clean foundation, analytical queries were run to discover industry trends, company vulnerabilities, and macro patterns during this phase of layoffs.

### Key Discoveries & Queries:
* **Outliers & Failures:** Identified companies that underwent a 100% workforce reduction, sorting them by capital raised to spotlight high-profile startup failures (such as Quibi and BritishVolt).
* **Macro Aggregations:** Aggregated total layoffs grouped by company, geographical locations, country, date-year, industry sectors, and funding stages.
* **Rolling Monthly Totals:** Used Window Functions over Date CTEs to generate month-over-month rolling totals of tech layoffs globally.
* **Top Annual Ranks:** Utilized complex CTE combinations alongside `DENSE_RANK()` partitions to isolate and identify the top 3 companies with the highest layoffs for each year.

---

## 💻 Tech Stack Used
* **SQL Dialect:** MySQL 8.0
* **Environment:** MySQL Workbench 
* **Core Concepts:** Windows Functions (`ROW_NUMBER()`, `DENSE_RANK()`, rolling `SUM()`), Common Table Expressions (CTEs), Joins (Self-Joins), Data DDL/DML, and Database Constraints.

---

## 🚀 How to Run this Project
1. Clone this repository to your local system.
2. Load and run the setup commands to import `layoffs.csv` into your schema.
3. Run the scripts sequentially:
   * Execute `Layoffs_mysql_Data_Cleaning.sql` to construct the staging tables and clean the data.
   * Run `Layoffs_mysql_EDA.sql` to execute the analytical queries.