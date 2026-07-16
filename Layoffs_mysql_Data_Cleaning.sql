-- =============================================================================
-- PORTFOLIO PROJECT: DATA CLEANING IN MYSQL
-- Database: world_layoffs
-- =============================================================================

-- -----------------------------------------------------------------------------
-- STEP 0: INITIAL INSPECTION & STAGING TABLE CREATION
-- -----------------------------------------------------------------------------

-- Preview raw data
SELECT * 
FROM world_layoffs.layoffs;

-- Create a staging table matching the structure of the raw table
CREATE TABLE world_layoffs.layoffs_staging 
LIKE world_layoffs.layoffs;

-- Verify staging table structure
SELECT * 
FROM world_layoffs.layoffs_staging;

-- Insert raw data into our staging table to preserve original data
INSERT INTO world_layoffs.layoffs_staging 
SELECT * 
FROM world_layoffs.layoffs;


-- -----------------------------------------------------------------------------
-- DATA CLEANING WORKFLOW:
-- 1. Identify & Remove Duplicates
-- 2. Standardize Data & Fix Errors
-- 3. Address Null / Blank Values
-- 4. Drop Unnecessary Rows & Columns
-- -----------------------------------------------------------------------------


-- =============================================================================
-- PHASE 1: REMOVE DUPLICATES
-- =============================================================================

-- Preliminary check: Identify row counts per unique partition (using subset columns)
SELECT 
    company, 
    industry, 
    total_laid_off,
    `date`,
    ROW_NUMBER() OVER (
        PARTITION BY company, industry, total_laid_off, `date`
    ) AS row_num
FROM world_layoffs.layoffs_staging;

-- Subquery to filter potential duplicates
SELECT *
FROM (
    SELECT 
        company, 
        industry, 
        total_laid_off,
        `date`,
        ROW_NUMBER() OVER (
            PARTITION BY company, industry, total_laid_off, `date`
        ) AS row_num
    FROM world_layoffs.layoffs_staging
) duplicates
WHERE row_num > 1;

-- Spot-check a specific company (e.g., 'Oda') to confirm duplicates are genuine
SELECT *
FROM world_layoffs.layoffs_staging
WHERE company = 'Oda';

-- Rigorous check: Partition by ALL columns to find exact row duplicates
SELECT *
FROM (
    SELECT 
        company, 
        location, 
        industry, 
        total_laid_off,
        percentage_laid_off,
        `date`, 
        stage, 
        country, 
        funds_raised_millions,
        ROW_NUMBER() OVER (
            PARTITION BY company, location, industry, total_laid_off, 
                         percentage_laid_off, `date`, stage, country, 
                         funds_raised_millions
        ) AS row_num
    FROM world_layoffs.layoffs_staging
) duplicates
WHERE row_num > 1;

-- Attempting CTE deletion (Note: MySQL does not support direct DELETE on CTEs)
WITH DELETE_CTE AS (
    SELECT *
    FROM (
        SELECT 
            company, location, industry, total_laid_off, percentage_laid_off, 
            `date`, stage, country, funds_raised_millions,
            ROW_NUMBER() OVER (
                PARTITION BY company, location, industry, total_laid_off, 
                             percentage_laid_off, `date`, stage, country, 
                             funds_raised_millions
            ) AS row_num
        FROM world_layoffs.layoffs_staging
    ) duplicates
    WHERE row_num > 1
)
DELETE FROM DELETE_CTE;

-- Alternative tuple-matching deletion approach
WITH DELETE_CTE AS (
    SELECT 
        company, location, industry, total_laid_off, percentage_laid_off, 
        `date`, stage, country, funds_raised_millions, 
        ROW_NUMBER() OVER (
            PARTITION BY company, location, industry, total_laid_off, 
                         percentage_laid_off, `date`, stage, country, 
                         funds_raised_millions
        ) AS row_num
    FROM world_layoffs.layoffs_staging
)
DELETE FROM world_layoffs.layoffs_staging
WHERE (
    company, location, industry, total_laid_off, percentage_laid_off, 
    `date`, stage, country, funds_raised_millions, row_num
) IN (
    SELECT 
        company, location, industry, total_laid_off, percentage_laid_off, 
        `date`, stage, country, funds_raised_millions, row_num
    FROM DELETE_CTE
) 
AND row_num > 1;

-- Optimized Solution: Create a secondary staging table with a dedicated row_num column
ALTER TABLE world_layoffs.layoffs_staging ADD row_num INT;

SELECT *
FROM world_layoffs.layoffs_staging;

-- Create layoffs_staging2 to safely filter and hold clean records
CREATE TABLE `world_layoffs`.`layoffs_staging2` (
    `company` TEXT,
    `location` TEXT,
    `industry` TEXT,
    `total_laid_off` INT,
    `percentage_laid_off` TEXT,
    `date` TEXT,
    `stage` TEXT,
    `country` TEXT,
    `funds_raised_millions` INT,
    row_num INT
);

-- Insert data while generating the analytical partition row numbers
INSERT INTO `world_layoffs`.`layoffs_staging2` (
    `company`,
    `location`,
    `industry`,
    `total_laid_off`,
    `percentage_laid_off`,
    `date`,
    `stage`,
    `country`,
    `funds_raised_millions`,
    `row_num`
)
SELECT 
    `company`,
    `location`,
    `industry`,
    `total_laid_off`,
    `percentage_laid_off`,
    `date`,
    `stage`,
    `country`,
    `funds_raised_millions`,
    ROW_NUMBER() OVER (
        PARTITION BY company, location, industry, total_laid_off, 
                     percentage_laid_off, `date`, stage, country, 
                     funds_raised_millions
    ) AS row_num
FROM world_layoffs.layoffs_staging;

-- Disable safe updates for your session
SET SQL_SAFE_UPDATES = 0;

-- Run your delete query (it will now execute perfectly!)
DELETE FROM world_layoffs.layoffs_staging2
WHERE row_num >= 2;

-- Optionally, turn safe updates back on to keep your database protected
SET SQL_SAFE_UPDATES = 1;


-- =============================================================================
-- PHASE 2: STANDARDIZE DATA
-- =============================================================================

-- Check distinct values in industry to identify inconsistencies
SELECT DISTINCT industry
FROM world_layoffs.layoffs_staging2
ORDER BY industry;

-- Check for missing or blank industries
SELECT *
FROM world_layoffs.layoffs_staging2
WHERE industry IS NULL 
   OR industry = ''
ORDER BY industry;

-- Check specific examples to evaluate industry mapping
SELECT *
FROM world_layoffs.layoffs_staging2
WHERE company LIKE 'Bally%';

SELECT *
FROM world_layoffs.layoffs_staging2
WHERE company LIKE 'airbnb%';

-- Disable safe updates for your session
SET SQL_SAFE_UPDATES = 0;

-- Standardize: Convert empty strings to NULLs for consistency
UPDATE world_layoffs.layoffs_staging2
SET industry = NULL
WHERE industry = '';

-- Optionally, turn safe updates back on to keep your database protected
SET SQL_SAFE_UPDATES = 1;


-- Re-verify updated blanks
SELECT *
FROM world_layoffs.layoffs_staging2
WHERE industry IS NULL 
   OR industry = ''
ORDER BY industry;

-- Disable safe updates for your session
SET SQL_SAFE_UPDATES = 0;

-- Self-join update: Populate null industries using matching records from the same company
UPDATE layoffs_staging2 t1
JOIN layoffs_staging2 t2
    ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL
  AND t2.industry IS NOT NULL;
  
-- Optionally, turn safe updates back on to keep your database protected
SET SQL_SAFE_UPDATES = 1;


-- Verify the remaining nulls (e.g., companies like Bally's with no existing records)
SELECT *
FROM world_layoffs.layoffs_staging2
WHERE industry IS NULL 
   OR industry = ''
ORDER BY industry;

-- Standardize Industry: Consolidate variations of 'Crypto'
SELECT DISTINCT industry
FROM world_layoffs.layoffs_staging2
ORDER BY industry;

-- Disable safe updates for your session
SET SQL_SAFE_UPDATES = 0;

UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry IN ('Crypto Currency', 'CryptoCurrency');

-- Optionally, turn safe updates back on to keep your database protected
SET SQL_SAFE_UPDATES = 1;

-- Verify Crypto consolidation
SELECT DISTINCT industry
FROM world_layoffs.layoffs_staging2
ORDER BY industry;

-- Standardize Country: Clean up trailing punctuation (e.g., 'United States.')
SELECT DISTINCT country
FROM world_layoffs.layoffs_staging2
ORDER BY country;

-- Disable safe updates for your session
SET SQL_SAFE_UPDATES = 0;

UPDATE layoffs_staging2
SET country = TRIM(TRAILING '.' FROM country);

-- Optionally, turn safe updates back on to keep your database protected
SET SQL_SAFE_UPDATES = 1;

-- Verify country fixes
SELECT DISTINCT country
FROM world_layoffs.layoffs_staging2
ORDER BY country;

-- Standardize Dates: Convert text date column to proper Date format
SELECT *
FROM world_layoffs.layoffs_staging2;

-- Disable safe updates for your session
SET SQL_SAFE_UPDATES = 0;

UPDATE layoffs_staging2
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');

-- Optionally, turn safe updates back on to keep your database protected
SET SQL_SAFE_UPDATES = 1;

-- Modify column definition to a proper DATE datatype
ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE;

-- Verify final date conversion
SELECT *
FROM world_layoffs.layoffs_staging2;


-- =============================================================================
-- PHASE 3: ADDRESS NULL VALUES
-- =============================================================================

-- Quantitative Nulls (total_laid_off, percentage_laid_off, funds_raised_millions)
-- will remain NULL to maintain calculations integrity during Exploratory Data Analysis (EDA).


-- =============================================================================
-- PHASE 4: DROP UNNECESSARY ROWS & COLUMNS
-- =============================================================================

-- Identify rows that lack any significant layoff metrics
SELECT *
FROM world_layoffs.layoffs_staging2
WHERE total_laid_off IS NULL;

SELECT *
FROM world_layoffs.layoffs_staging2
WHERE total_laid_off IS NULL
  AND percentage_laid_off IS NULL;
  
-- Disable safe updates for your session
SET SQL_SAFE_UPDATES = 0;

-- Remove records missing both crucial metrics
DELETE FROM world_layoffs.layoffs_staging2
WHERE total_laid_off IS NULL
  AND percentage_laid_off IS NULL;
  
-- Optionally, turn safe updates back on to keep your database protected
SET SQL_SAFE_UPDATES = 1;  

-- Drop the temporary helper row_num column
ALTER TABLE layoffs_staging2
DROP COLUMN row_num;

-- Final data preview
SELECT * 
FROM world_layoffs.layoffs_staging2;