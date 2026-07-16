-- =============================================================================
-- PORTFOLIO PROJECT: EXPLORATORY DATA ANALYSIS (EDA)
-- Database: world_layoffs
-- =============================================================================

-- Preliminary look at the cleaned dataset
SELECT * 
FROM world_layoffs.layoffs_staging2;


-- -----------------------------------------------------------------------------
-- SECTION 1: EASIER QUERIES & OUTLIERS
-- -----------------------------------------------------------------------------

-- Find the maximum number of layoffs in a single day
SELECT MAX(total_laid_off)
FROM world_layoffs.layoffs_staging2;

-- Look at the maximum and minimum percentage of company laid off
SELECT 
    MAX(percentage_laid_off), 
    MIN(percentage_laid_off)
FROM world_layoffs.layoffs_staging2
WHERE percentage_laid_off IS NOT NULL;

-- Identify companies that laid off 100% of their workforce (percentage_laid_off = 1)
SELECT *
FROM world_layoffs.layoffs_staging2
WHERE percentage_laid_off = 1;

-- Order those 100% layoff companies by funds raised to see the largest startups that failed
SELECT *
FROM world_layoffs.layoffs_staging2
WHERE percentage_laid_off = 1
ORDER BY funds_raised_millions DESC;


-- -----------------------------------------------------------------------------
-- SECTION 2: SUMMARIES & PATTERNS USING GROUP BY
-- -----------------------------------------------------------------------------

-- Top 5 companies with the single largest layoff event (on a single day)
SELECT 
    company, 
    total_laid_off
FROM world_layoffs.layoffs_staging
ORDER BY 2 DESC
LIMIT 5;

-- Top 10 companies with the most total layoffs across the entire dataset
SELECT 
    company, 
    SUM(total_laid_off) AS total_laid_off
FROM world_layoffs.layoffs_staging2
GROUP BY company
ORDER BY 2 DESC
LIMIT 10;

-- Top 10 locations with the most total layoffs
SELECT 
    location, 
    SUM(total_laid_off) AS total_laid_off
FROM world_layoffs.layoffs_staging2
GROUP BY location
ORDER BY 2 DESC
LIMIT 10;

-- Total layoffs by country
SELECT 
    country, 
    SUM(total_laid_off) AS total_laid_off
FROM world_layoffs.layoffs_staging2
GROUP BY country
ORDER BY 2 DESC;

-- Total layoffs aggregated by year
SELECT 
    YEAR(`date`) AS layoff_year, 
    SUM(total_laid_off) AS total_laid_off
FROM world_layoffs.layoffs_staging2
GROUP BY YEAR(`date`)
ORDER BY 1 ASC;

-- Total layoffs aggregated by industry
SELECT 
    industry, 
    SUM(total_laid_off) AS total_laid_off
FROM world_layoffs.layoffs_staging2
GROUP BY industry
ORDER BY 2 DESC;

-- Total layoffs aggregated by company funding stage
SELECT 
    stage, 
    SUM(total_laid_off) AS total_laid_off
FROM world_layoffs.layoffs_staging2
GROUP BY stage
ORDER BY 2 DESC;


-- -----------------------------------------------------------------------------
-- SECTION 3: ADVANCED ANALYTICAL QUERIES (CTEs & WINDOW FUNCTIONS)
-- -----------------------------------------------------------------------------

-- Query 1: Top 3 companies with the most layoffs per year (using CTEs and DENSE_RANK)
WITH Company_Year AS (
    SELECT 
        company, 
        YEAR(`date`) AS years, 
        SUM(total_laid_off) AS total_laid_off
    FROM world_layoffs.layoffs_staging2
    GROUP BY company, YEAR(`date`)
),
Company_Year_Rank AS (
    SELECT 
        company, 
        years, 
        total_laid_off, 
        DENSE_RANK() OVER (
            PARTITION BY years 
            ORDER BY total_laid_off DESC
        ) AS ranking
    FROM Company_Year
)
SELECT 
    company, 
    years, 
    total_laid_off, 
    ranking
FROM Company_Year_Rank
WHERE ranking <= 3
  AND years IS NOT NULL
ORDER BY years ASC, total_laid_off DESC;


-- Query 2: Layoffs breakdown by year-month (preparation for rolling sum)
SELECT 
    SUBSTRING(`date`, 1, 7) AS dates, 
    SUM(total_laid_off) AS total_laid_off
FROM world_layoffs.layoffs_staging2
GROUP BY dates
ORDER BY dates ASC;

-- Query 3: Rolling total of layoffs month-over-month (using CTE and Window Function)
WITH DATE_CTE AS (
    SELECT 
        SUBSTRING(`date`, 1, 7) AS dates, 
        SUM(total_laid_off) AS total_laid_off
    FROM world_layoffs.layoffs_staging2
    GROUP BY dates
    ORDER BY dates ASC
)
SELECT 
    dates, 
    SUM(total_laid_off) OVER (
        ORDER BY dates ASC
    ) AS rolling_total_layoffs
FROM DATE_CTE
ORDER BY dates ASC;