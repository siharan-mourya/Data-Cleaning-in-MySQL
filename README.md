### World Layoffs (Data Cleaning Project):

#### source: https://www.kaggle.com/datasets/swaptr/layoffs-2022

#### Steps taken to clean data: 

1. Remove duplicates (if any)
2. Standardize the data 
3. Null Values or blank values
4. Remove unnecessary columns/rows

- Checking out the data:

```bash
SELECT * 
FROM layoffs;
```

- Creating a copy of raw data to work on:

```bash 
CREATE TABLE layoffs_staging
LIKE layoffs;

INSERT INTO layoffs_staging
SELECT *
FROM layoffs;

SELECT * 
FROM layoffs_staging;
```

#### 1. Finding duplicates:

- Total records before removing duplicates = 2361 
- Indexing the rows using ROW_NUMBER to find duplicates.

```bash
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
```

- Verifying the above query results:

```bash
SELECT * 
FROM layoffs_staging
WHERE company = 'Cazoo';
```

- A DELETE statement is like an UPDATE statement. Unlike MSSQL/PostgreSQL, MySQl doesn't support DELETE in a CTE. Hence another staged table is created with a new row_number column.

```bash
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
```

- Inserting data into the second staged table:
```bash
INSERT INTO layoffs_staging2
SELECT * ,
ROW_NUMBER() OVER(
	PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, 
				`date`, stage, country, funds_raised_millions
                 ) AS row_num
FROM layoffs_staging;

```

- Removing duplicates from the second staged table:

```bash
SELECT * 
FROM layoffs_staging2
WHERE row_num > 1;

DELETE
FROM layoffs_staging2
WHERE row_num > 1;
```

- Total records after removing duplicates = 2356

```bash
SELECT COUNT(*) 
FROM layoffs_staging2;
```

#### 2. Standardizing Data:

- Removing any leading/trailing spaces:

```bash
SELECT company, TRIM(company) AS company_name
FROM layoffs_staging2;

UPDATE layoffs_staging2
SET company = TRIM(company);

SELECT DISTINCT industry
FROM layoffs_staging2
ORDER BY industry;
```
- Merging industries with same functions:

```bash
SELECT *
FROM layoffs_staging2
WHERE industry LIKE 'Crypto%';

UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';
```
- Removing any leading/trailing characters:

```bash
SELECT DISTINCT country, TRIM(TRAILING '.' FROM country)
FROM layoffs_staging2
ORDER BY country;

UPDATE layoffs_staging2
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'United States%';
```
- Extracting date from string and updating to date data type:

```bash
SELECT `date`, STR_TO_DATE(`date`, '%m/%d/%Y')
FROM layoffs_staging2
ORDER BY country;

UPDATE layoffs_staging2
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');

ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE;
```

#### 3. Finding Null/Blank values to either populate or delete:

```bash
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
```

- This method can be used on large datasets:

```bash
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
```

- This method can be used in a small dataset as it requires to specify conditions

```bash
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
```

#### 4. Removing unnecessary columns/rows:

```bash
SELECT *
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;


DELETE
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;


ALTER TABLE layoffs_staging2
DROP COLUMN row_num;
```

- Total records after deleting = 1995

```bash
SELECT COUNT(*) FROM layoffs_staging2;
```

### Acknowledgement: 
Thank you to [Alex freberg](https://youtu.be/4UltKCnnnTA?si=zHnfOLTztzYiaKEh) for creating and guiding through this project.



