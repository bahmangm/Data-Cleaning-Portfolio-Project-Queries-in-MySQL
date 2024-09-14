SELECT * 
FROM portfolio.house;
--------------------------------------------------------------------------------------------------------------------------


# The values in the SaleDate field are in the format 'April 9, 2013'. 
# We use the format string '%M %d, %Y' in the STR_TO_DATE function to convert this string into a valid DATE format.
SELECT SaleDate, 
STR_TO_DATE(SaleDate, '%M %d, %Y') AS saleDateConverted 
FROM portfolio.house;
--------------------------------------------------------------------------------------------------------------------------


# Replace the date string like 'April 9, 2013' with valid DATE format (2013-04-09).
update portfolio.house
set SaleDate = STR_TO_DATE(SaleDate, '%M %d, %Y');
--------------------------------------------------------------------------------------------------------------------------


# We find out that 18 records don't have address with the help of below query.
SELECT count(*)
FROM portfolio.house
WHERE PropertyAddress IS NULL OR PropertyAddress = ''
ORDER BY ParcelID;


# The query below displays all records with an empty PropertyAddress, along with 
# their expected address retrieved from other records with the same ParcelID.
SELECT a.ParcelID, 
       a.PropertyAddress as FirstAddress,
       b.ParcelID, 
       b.PropertyAddress as secondAddress
FROM portfolio.house a
JOIN portfolio.house b
    ON a.ParcelID = b.ParcelID
    AND a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress IS NULL OR a.PropertyAddress = '';


# The below query updates 18 records
UPDATE 
	portfolio.house a JOIN portfolio.house b
    ON a.ParcelID = b.ParcelID
    AND a.UniqueID <> b.UniqueID
SET a.PropertyAddress = b.PropertyAddress
WHERE a.PropertyAddress IS NULL OR a.PropertyAddress = '';
--------------------------------------------------------------------------------------------------------------------------


# The query below splits the PropertyAddress into two fields. 
# For example, '1808 FOX CHASE DR, GOODLETTSVILLE' is split into '1808 FOX CHASE DR' and 'GOODLETTSVILLE'.
SELECT
	PropertyAddress,
    SUBSTRING(PropertyAddress, 1, LOCATE(',', PropertyAddress) - 1) AS Address,
    SUBSTRING(PropertyAddress, LOCATE(',', PropertyAddress) + 1, LENGTH(PropertyAddress)) AS RemainingAddress
FROM portfolio.house;


# Displays the schema of the portfolio.house table, including information about all columns.
describe portfolio.house;


# Add a new field
ALTER TABLE portfolio.house
ADD PropertySplitAddress VARCHAR(255);


# Extract the first part of PropertyAddress (from the beginning to the first comma) 
# and store it in PropertySplitAddress.
UPDATE  portfolio.house
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, LOCATE(',', PropertyAddress) - 1);


# Add a new field
ALTER TABLE portfolio.house
ADD PropertySplitCity VARCHAR(255);


# Extract the second part of PropertyAddress (from the first comma to the end of the string) 
# and store it in PropertySplitCity.
UPDATE  portfolio.house
SET PropertySplitCity = SUBSTRING(PropertyAddress, LOCATE(',', PropertyAddress) + 1, LENGTH(PropertyAddress));

select PropertyAddress, PropertySplitAddress, PropertySplitCity
from portfolio.house;
--------------------------------------------------------------------------------------------------------------------------


# The query below counts the occurrence of each unique value in the SoldAsVacant column.
# There are 21 'Y' values that need to be changed to 'Yes' and 151 'N' values that need to be changed to 'No'.
SELECT SoldAsVacant, count(SoldAsVacant) as Count
FROM portfolio.house
GROUP BY SoldAsVacant
ORDER BY Count;


SELECT SoldAsVacant, count(SoldAsVacant) as Count,
CASE 
    WHEN SoldAsVacant = 'Y' THEN 'Yes'
    WHEN SoldAsVacant = 'N' THEN 'No'
    ELSE SoldAsVacant
END AS SoldAsVacantFormatted
FROM portfolio.house
GROUP BY SoldAsVacant;


# Update the SoldAsVacant field, changing 'Y' to 'Yes' and 'N' to 'No'
UPDATE portfolio.house
SET SoldAsVacant =
CASE 
    WHEN SoldAsVacant = 'Y' THEN 'Yes'
    WHEN SoldAsVacant = 'N' THEN 'No'
    ELSE SoldAsVacant
END;
--------------------------------------------------------------------------------------------------------------------------


# This query partitions the table based on the following fields: ParcelID, PropertyAddress, SalePrice, SaleDate, and LegalReference.
# All records with the same values for these five fields are placed into the same partition (similar to grouping people in a country by their city).
# Within each partition, records are sorted by UniqueID, and a row number is assigned to each record, starting from 1.
SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference
               ORDER BY UniqueID
           ) AS row_num
FROM portfolio.house;


# The below query can be used to find duplicate records in the table based on a combination of 
# columns (ParcelID, PropertyAddress, SalePrice, SaleDate, and LegalReference).
WITH RowNumCTE AS (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference
               ORDER BY UniqueID
           ) AS row_num
    FROM portfolio.house
)
SELECT *
FROM RowNumCTE
WHERE row_num > 1
ORDER BY PropertyAddress;
--------------------------------------------------------------------------------------------------------------------------


# This query finds the top three houses with the highest SalePrice in each city, grouped by an equal number of bedrooms.
WITH RowNumCTE AS (
    SELECT 
        PropertySplitCity, 
        Bedrooms, 
        SalePrice,
        ROW_NUMBER() OVER (PARTITION BY PropertySplitCity, Bedrooms ORDER BY SalePrice DESC) AS row_num
    FROM portfolio.house
)
SELECT * 
FROM RowNumCTE
WHERE row_num <= 3;
--------------------------------------------------------------------------------------------------------------------------


# Delete Unused Columns
ALTER TABLE portfolio.house
DROP COLUMN PropertyAddress;

SELECT * 
FROM portfolio.house;
--------------------------------------------------------------------------------------------------------------------------
