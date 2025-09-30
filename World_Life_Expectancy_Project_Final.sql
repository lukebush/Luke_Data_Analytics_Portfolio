-- This data is from World Health Organization (WHO) Global Health Observatory (GHO). The goal of this project is to demonstrate data cleaning, search for insights, and form action steps based off of those insights.

-- Summary of data insights and action steps:
	-- This data showed that the 300 GDP difference between the High GDP of 1326 vs. the Low GDP of 1612, results in a 10 year difference in the average life expectancy.
	-- This data shows that normatively, there is a correlation between low BMI and low life expectancy. Area for further investigation is to compare the life expectancy of countries that have high BMI high GDP (which are most prone to obesity, yet have higher quality food) with the countries who have low GDP and low BMI (which are not prone to obesity, but are prone to starvation.)
	-- For further study, we would want to import data on the total population of each country (which isn't contained in this dataset), so that he can compare that with the adult mortality rate of each year.


-- Data Cleaning

Select Country, Year, Concat(Country, Year), Count(Concat(Country, Year)) -- Identify duplicates by looking for repeat Countries within same year
From world_life_expectancy
Group By Country, Year, Concat(Country, Year)
Having Count(Concat(Country, Year)) > 1;
Select *
From (
	Select Row_ID, Concat(Country, Year),
	row_number() Over (Partition By Concat(Country, Year) Order By Concat(Country, Year)) as  Row_Num
	From world_life_expectancy) AS Row_table
Where Row_Num > 1; -- This shows that duplicates are found with Row_ID's of 1252, 2265, & 2929.


Delete From world_life_expectancy
Where
	Row_ID IN (Select Row_ID 
From (
	Select Row_ID, 
    Concat (Country, Year), 
    Row_Number() Over( Partition By Concat(Country, Year) Order By Concat (Country, Year)) as Row_Num
    From world_life_expectancy
		)AS Row_table
    Where Row_Num > 1); -- Now we will identify rows where the Status column is blank. Then we will impute data based off data from that same country in the other years.

    
Select Country, Year
From world_life_expectancy
Where Status = "";    -- This shows the rows that need imputed data.

Select Distinct(Status)
From world_life_expectancy
Where Status <> ''; -- This confirms that the only blanks in this column are those that don't say Developed or Developing.

Select Distinct(Country)
From world_life_expectancy
Where Status = 'Developing';

UPDATE world_life_expectancy
SET Status = 'Developing'
Where Country IN (Select Distinct(Country)
	FROM world_life_expectancy
    Where Status = 'Developing'; -- Since this failed due to inability to update from subqueries in the FROM clause, we will do a self join.
    
UPDATE world_life_expectancy t1
Join world_life_expectancy t2
	ON t1.Country = t2. Country
SET t1.Status = 'Developing'
Where t1.Status = ''
AND t2.Status <> ''
AND t2.Status = 'Developing';

UPDATE world_life_expectancy t1
Join world_life_expectancy t2
	ON t1.Country = t2. Country
SET t1.Status = 'Developed'
Where t1.Status = ''
AND t2.Status <> ''
AND t2.Status = 'Developed'; -- Now that the blanks for this column are filled, we will identify and fill in missing data in the 'Life expectancy column' by leveraging the average from the previous and following year. We can do this in confidence because each previous year shows a consistent pattern of growth.

Select Country, Year, 'Life expectancy'
From world_life_expectancy;
#Where 'Life expectancy = ''
;


SELECT 
    t1.Country, 
    t1.Year, 
    t1.`Life expectancy`, 
    t2.Country, 
    t2.Year, 
    t2.`Life expectancy`,
    t3.Country, 
    t3.Year, 
    t3.`Life expectancy`,
    ROUND((t2.`Life expectancy` + t3.`Life expectancy`) / 2, 1) AS avg_neighbors
FROM world_life_expectancy t1
JOIN world_life_expectancy t2
    ON t1.Country = t2.Country
   AND t1.Year = t2.Year - 1
JOIN world_life_expectancy t3
    ON t1.Country = t3.Country
   AND t1.Year = t3.Year + 1
WHERE t1.`Life expectancy` = ''; -- The averages which will be imputed to the missing data are now ready.

Update world_life_expectancy t1
JOIN world_life_expectancy t2
    ON t1.Country = t2.Country
   AND t1.Year = t2.Year - 1
JOIN world_life_expectancy t3
    ON t1.Country = t3.Country
   AND t1.Year = t3.Year + 1
Set t1.`Life expectancy` = ROUND((t2.`Life expectancy` + t3.`Life expectancy`) / 2, 1)
Where t1.`Life expectancy` = '';

-- Exploratory Data Analysis


Select Country, MIN(`Life expectancy`), MAX(`Life expectancy`)
FROM world_life_expectancy
GROUP BY Country
HAVING MIN(`Life expectancy`) <> 0
AND MAX(`Life expectancy`) <> 0
ORDER BY Country DESC
; -- This shows the min and max life expectancy for each country.


SELECT Year, ROUND(AVG(`Life expectancy`), 2)
FROM world_life_expectancy
WHERE `Life expectancy` <> 0 AND `Life expectancy` <> 0
GROUP BY Year
ORDER BY Year
; -- This shows the average life expectancy worldwide throughout the years.

SELECT Country, ROUND(AVG(`Life expectancy`),1) AS Life_Exp, Round(AVG(GDP),1) AS GDP
FROM world_life_expectancy
Group By Country
Having Life_Exp > 0 And GDP > 0
Order By Life_Exp ASC
; -- This shows that there is a strong correlation between life expectancy and GDP.

Select
Sum(Case When GDP >= 1500 THEN 1 Else 0 End) High_GDP_Count,
Avg(Case When GDP >= 1500 THEN `Life expectancy` Else NULL End) High_GDP_Life_Expectancy,
Sum(Case When GDP <= 1500 THEN 1 Else 0 End) Low_GDP_Count,
Avg(Case When GDP <= 1500 THEN `Life expectancy` Else NULL End) Low_GDP_Life_Expectancy
From world_life_expectancy
;
-- This query just showed that the 300 GDP difference between the High GDP of 1326 vs. the Low GDP of 1612, showed a 10 year difference in the average life expectancy.

Select Status, Round(Avg(`Life expectancy`),1), Count(Distinct Country)
From world_life_expectancy
Group By Status
; -- The average life expectancy in the "developed" versus "developing" countries are skewed due to vast difference in Count. 

SELECT Country, ROUND(AVG(`Life expectancy`),1) AS Life_Exp, Round(AVG(BMI),1) AS BMI
FROM world_life_expectancy
Group By Country
Having Life_Exp > 0 And BMI > 0
Order By BMI Asc
; -- This shows that normatively, there is a correlation between low BMI and low life expectancy. Area for further investigation is to see if there is a correlation between countries with both high GDP and high BMI, and high life expectancy. This could show that countries that are prospering and eating very well, are likely to live longer. 

Select Country, Year, `Life expectancy`, `Adult Mortality`, Sum(`Adult Mortality`) Over(Partition By Country Order By Year) As Rolling_Total
From world_life_expectancy
;
-- Potential data quality issue in Afghanistan 2009 (only 3 in Adult Mortality?)
-- For further study, compare the adult mortality with data containing total population of the country.

Select *
From world_life_expectancy