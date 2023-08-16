SELECT *
FROM PortfolioProject..deaths
WHERE continent is not NULL
ORDER BY 2,3

--SELECT *
--FROM PortfolioProject..vaccinations
--ORDER BY 2,3

--Selecting the data to be used--

SELECT location, date, population, total_cases, new_cases, total_deaths
FROM PortfolioProject..deaths
ORDER BY 1,2


-- Total Cases vs deaths (percent_death)
SELECT location, date, total_cases, total_deaths, ROUND(((total_deaths/total_cases)*100),2 ) as percent_death
FROM PortfolioProject..deaths
ORDER BY 1,2

-- Cases vs population
SELECT location, date, total_cases, population, ROUND(((total_cases/population)*100),2) as infection_rate
FROM PortfolioProject..deaths
ORDER BY 1,2


-- Contries with higher infection rate
SELECT location, MAX(total_cases) as max_cases, population, MAX(ROUND(((total_cases/population)*100),2)) as infection_rate
FROM PortfolioProject..deaths
GROUP BY location, population
ORDER BY 4 DESC

-- Contries with highest death percentage
SELECT location,  MAX(total_deaths) as max_deaths
FROM PortfolioProject..deaths
WHERE continent is not NULL
GROUP BY location
ORDER BY 2 DESC

--Continent with higherst death rate
SELECT location, MAX(total_deaths) as total_deaths
FROM PortfolioProject..deaths
WHERE continent is NULL
GROUP BY location
ORDER BY 2 DESC;

-- Global numbers

-- Total new cases per day
SELECT date, SUM(new_cases) as total_new_cases
FROM PortfolioProject..deaths
GROUP BY date
ORDER BY 1,2


--Total new deaths per day
SELECT date, SUM(new_deaths) as total_new_deaths
FROM PortfolioProject..deaths
GROUP BY date
ORDER BY 1,2


-- Getting the percentage of new deaths to new cases
SELECT date, SUM(new_cases) as total_new_cases, SUM(new_deaths) as total_new_deaths, 
	ROUND((SUM(new_deaths)/SUM(new_cases))*100,2) as percent_new_deaths_to_cases
FROM PortfolioProject..deaths
WHERE new_cases != 0 
GROUP BY date
ORDER BY 1,2


-- Total new vaccinations per country per day

SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations, 
	ROUND((v.new_vaccinations/d.population)*100,2) as percent_pop_newly_vaccinated
FROM PortfolioProject..deaths d
JOIN PortfolioProject..vaccinations v
ON d.location = v.location and d.date = v.date
WHERE d.continent is not NULL
ORDER BY 1,2,3


-- Total population vaccinated
-- looks like a large portion of the world counted individuals more than once or reported their population incorrectly.
SELECT d.location, d.population, SUM(cast(v.new_vaccinations as float)) as total_vaccinations, 
	(ROUND((SUM(cast(v.new_vaccinations as float))/d.population)*100,2)) as percent_pop_vaccinated
FROM PortfolioProject..deaths d
JOIN PortfolioProject..vaccinations v
ON d.location = v.location and d.date = v.date
WHERE d.continent is not NULL and v.new_vaccinations is not NULL
GROUP BY d.location, d.population
ORDER BY 4 DESC


-- Rolling total vaccinated

SELECT d. continent, d.location, d.date, d.population, v.new_vaccinations, 
	SUM(CONVERT(float, v.new_vaccinations)) 
	OVER (Partition by d.location ORDER BY d.location, d.date) as total_vaccinated
FROM PortfolioProject..deaths d
JOIN PortfolioProject..vaccinations v
ON d.location = v.location and d.date = v.date
WHERE d.continent is not NULL and v.new_vaccinations is not NULL
ORDER BY 2,3


-- Rolling percent of people vaccinated using CTE
WITH PopvsVac (continent, location, date, population, new_vaccinations, total_vaccinated)
as
(
SELECT d. continent, d.location, d.date, d.population, v.new_vaccinations, 
	SUM(CONVERT(float, v.new_vaccinations)) 
	OVER (Partition by d.location ORDER BY d.location, d.date) as total_vaccinated
FROM PortfolioProject..deaths d
JOIN PortfolioProject..vaccinations v
ON d.location = v.location and d.date = v.date
WHERE d.continent is not NULL and v.new_vaccinations is not NULL
)
SELECT *, ROUND((total_vaccinated/population)*100,2) as percent_vaccinated
FROM PopvsVac


-- Rolling percent of people vaccinated using Temp Table

DROP TABLE IF EXISTS #percentpopvaccinated
CREATE TABLE #percentpopvaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population float,
new_vaccinations float,
total_vaccinated float
)

INSERT INTO #percentpopvaccinated
SELECT d. continent, d.location, d.date, d.population, v.new_vaccinations, 
	SUM(CONVERT(float, v.new_vaccinations)) 
	OVER (Partition by d.location ORDER BY d.location, d.date) as total_vaccinated
FROM PortfolioProject..deaths d
JOIN PortfolioProject..vaccinations v
ON d.location = v.location and d.date = v.date
WHERE d.continent is not NULL and v.new_vaccinations is not NULL


SELECT *, ROUND((total_vaccinated/population)*100,2) as percent_vaccinated
FROM #percentpopvaccinated
ORDER BY 2,3


-- Creating view to use data elsewhere

CREATE VIEW popvaccinated as 
SELECT d. continent, d.location, d.date, d.population, v.new_vaccinations, 
	SUM(CONVERT(float, v.new_vaccinations)) 
	OVER (Partition by d.location ORDER BY d.location, d.date) as total_vaccinated
FROM PortfolioProject..deaths d
JOIN PortfolioProject..vaccinations v
ON d.location = v.location and d.date = v.date
WHERE d.continent is not NULL and v.new_vaccinations is not NULL