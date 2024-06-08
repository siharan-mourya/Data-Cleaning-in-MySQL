-- Data Cleaning
-- 1. Remove duplicates (if any)
-- 2. Standardize the data 
-- 3. Null Values or blank values
-- 4. Remove unnecessary columns/rows

SELECT * 
FROM layoffs;

-- creating a copy of raw data to work on
 
CREATE TABLE layoffs_staging
LIKE layoffs;

INSERT INTO layoffs_staging
SELECT *
FROM layoffs;

SELECT * 
FROM layoffs_staging;

-- ------------------- 1. Finding duplicates ----------------------

-- total records before removing duplicates = 2361 

-- indexing the rows using row number to find duplicates

WITH duplicates_cte AS 
(
SELECT * ,
ROW_NUMBER() OVER(
	PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, 
				 `date`, stage, country, funds_raised_millions
                 ) AS row_num
FROM layoffs_staging
)
SELECT *
FROM duplicates_cte
WHERE row_num > 1;

-- verifying the above query results

SELECT * 
FROM layoffs_staging
WHERE company = 'Cazoo';

-- a delete statement is like an update statement, in MySQL we cannot delete in a CTE
-- in MSSQL/PostgreSQL it can be done. Hence another staged table is created with 
-- a new
 row_number column

CREATE TABLE `layoffs_staging2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `row_num` INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- inserting data into the second copy table

INSERT INTO layoffs_staging2
SELECT * ,
ROW_NUMBER() OVER(
	PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, 
				 country, funds_raised_millions) AS row_num
FROM layoffs_staging;

SELECT * 
FROM layoffs_staging2
WHERE row_num > 1;

-- removing duplicates

DELETE
FROM layoffs_staging2
WHERE row_num > 1;

-- total records before removing duplicates = 2356

SELECT COUNT(*) 
FROM layoffs_staging2;

SELECT * 
FROM layoffs_staging2;

-- ------------------- 2. Standardizing Data ----------------------

SELECT company, TRIM(company) AS f_company
FROM layoffs_staging2;

UPDATE layoffs_staging2
SET company = TRIM(company);

-- --------------------
SELECT DISTINCT industry
FROM layoffs_staging2
ORDER BY industry;

SELECT *
FROM layoffs_staging2
WHERE industry LIKE 'Crypto%';

UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';

-- --------------------

SELECT DISTINCT country, TRIM(TRAILING '.' FROM country)
FROM layoffs_staging2
ORDER BY country;

UPDATE layoffs_staging2
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'United States%';

-- ------------------

SELECT `date`, STR_TO_DATE(`date`, '%m/%d/%Y')
FROM layoffs_staging2
ORDER BY country;

UPDATE layoffs_staging2
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');

ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE;

-- --------------------
-- 3. Finding Null/Blank values to either populate or delete

SELECT *
FROM layoffs_staging2
WHERE industry LIKE '' OR industry IS NULL;

SELECT *
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

UPDATE layoffs_staging2
SET industry = NULL
WHERE industry = '';


-- this method can be used on large datasets

SELECT *
FROM layoffs_staging t1
JOIN layoffs_staging t2
	ON t1.company = t2.company
WHERE (t1.industry = '' OR t1.industry IS NULL) 
AND t2.industry IS NOT NULL;

UPDATE layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE (t1.industry = '' OR t1.industry IS NULL) 
AND t2.industry IS NOT NULL;

-- this method can be used in a small dataset as it requires to specify conditions

UPDATE layoffs_staging2
SET industry = CASE company
				WHEN 'Airbnb' THEN 'Travel'
                WHEN 'Carvana' THEN 'Transportation'
                WHEN 'Juul' THEN 'Consumer'
                ELSE industry
                END
WHERE company IN ('Airbnb', 'Carvana', 'Juul');

SELECT *
FROM layoffs_staging2
WHERE company = 'Airbnb'  OR company = 'Carvana' OR company = 'Juul';

-- ------------------
-- 4. Removing unnecessary columns/rows

SELECT *
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

DELETE
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

-- -------------------
ALTER TABLE layoffs_staging2
DROP COLUMN row_num;

-- -------------------
-- total records after deleting = 1995

SELECT COUNT(*) FROM layoffs_staging2;

