# ------------------------------ Data Cleaning ------------------------------


SELECT * FROM portfolio.layoffs;

# Create a new table with the same structure
create table layoffs_staging
like layoffs;

# Display an empty table
SELECT * FROM layoffs_staging;

# Insert all data from the main table into the newly created table
insert into layoffs_staging
select * from layoffs;

# Remove duplicate records (considering the desired fields) by creating a new, similar table
create table layoffs_staging2
like layoffs;

ALTER TABLE layoffs_staging2
ADD COLUMN row_num INT;

SELECT * FROM layoffs_staging2;

insert into layoffs_staging2
select *,
row_number() over(partition by company, location, industry, total_laid_off, 
percentage_laid_off, `date`, stage, country, funds_raised_millions) as row_num
from layoffs_staging;

delete FROM layoffs_staging2
where row_num > 1;


# Standardizing data
select company, trim(company)
from layoffs_staging2;

update layoffs_staging2
set company = trim(company);

# Various forms of 'Crypto' can be seen
select distinct industry
from layoffs_staging2
order by industry;

# Check all records with different forms of 'Crypto'
select  *
from layoffs_staging2
where industry like 'Crypto%';

update layoffs_staging2
set industry = 'Crypto'
where industry like 'Crypto%';

# Various forms of 'United States' can be seen
select distinct country
from layoffs_staging2
order by country;

# Check all records with different forms of 'United States'
select  *
from layoffs_staging2
where country like '%United States%'
order by country desc;

select  country, trim(trailing '.' from country)
from layoffs_staging2
where country like '%United States%'
order by country desc;

update layoffs_staging2
set country = trim(trailing '.' from country)
where country like '%United States%';

# Fill null values with the help of similar records
select t1.company, t1.industry, t2.industry, t2.company
from layoffs_staging2 t1
join layoffs_staging2 t2
on t1.company = t2.company
where (t1.industry is null or t1.industry = '')
and t2.industry is not null;

update layoffs_staging2 t1
join layoffs_staging2 t2
on t1.company = t2.company
set t1.industry = t2.industry
where (t1.industry is null or t1.industry = '')
and t2.industry is not null;

update layoffs_staging2
set industry = null
where industry = '';

# There is only one record so it cannot be filled
select *
from layoffs_staging2
where company like 'Bally%';

# 361 records where both important fields are null
select count(*)
from layoffs_staging2
where total_laid_off is null
and percentage_laid_off is null;

# Delete all records in above query
delete 
from layoffs_staging2
where total_laid_off is null
and percentage_laid_off is null;

select *
from layoffs_staging2;

# Remove the extra columns
alter table layoffs_staging2
drop column row_num;


# ------------------------------ EDA ------------------------------


# Total layoffs by month
select DATE_FORMAT(`date`, '%Y-%m') AS year_months, sum(total_laid_off) as total_layoff
from layoffs_staging2
where `date` is not null
group by year_months
order by year_months;


# Calculate a rolling total by month
with monthly_list as 
(select DATE_FORMAT(`date`, '%Y-%m') AS year_months, sum(total_laid_off) as total_layoffs
from layoffs_staging2
where `date` is not null
group by year_months
)
select *,
sum(total_layoffs) over(order by year_months) as rolling_total
from monthly_list;


# List the top 5 companies with the most layoffs each year
with yearly_list as
(select company, year(`date`) as years, sum(total_laid_off) as total_layoff
from layoffs_staging2
group by company, years
), year_based_sorted_list as
(select *,
rank() over(partition by years order by total_layoff desc) as ranking
from yearly_list
where years is not null
)
select * from year_based_sorted_list
where ranking <= 5;








