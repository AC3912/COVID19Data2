-- Data obtained from ourworldindata.org

-- Select Data that we are going to be using
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM COVID..CovidDeaths$
WHERE continent IS NOT NULL
ORDER BY 1,2 

-- Total Cases versus Total Deaths
-- Initially was getting the following error:
-- Msg 8117, Level 16, State 1, Line 10
-- Operand data type nvarchar is invalid for divide operator.
-- Converted the data type of both operands to float
SELECT location, date, total_cases, total_deaths, (CONVERT(float, total_deaths)/CONVERT(float,total_cases))*100 AS death_percentage
FROM COVID..CovidDeaths$
WHERE continent IS NOT NULL
ORDER BY 1,2 

-- Shows likelihood of death if you contract COVID in a country
SELECT location, date, total_cases, total_deaths, (CONVERT(float, total_deaths)/CONVERT(float,total_cases))*100 AS death_percentage
FROM COVID..CovidDeaths$
WHERE location LIKE '%states%' AND continent IS NOT NULL
ORDER BY 1,2 

-- Total Cases versus Population
-- Shows what percentage of population contracted COVID
SELECT location, date, total_cases, population, (CONVERT(float, total_cases)/CONVERT(float,population))*100 AS infected_percentage
FROM COVID..CovidDeaths$
WHERE continent IS NOT NULL
--WHERE location LIKE '%states%'
ORDER BY 1,2 

-- Highest infection rate per country 
SELECT location, MAX(total_cases) AS highest_infection_count, population, MAX((CONVERT(float, total_cases)/CONVERT(float,population)))*100 AS infected_population_percentage
FROM COVID..CovidDeaths$
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY infected_population_percentage DESC

-- Highest death count per population per country
SELECT location, MAX(total_deaths) AS total_death_count
FROM COVID..CovidDeaths$
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY total_death_count DESC

-- Death count per population by continent
SELECT continent, MAX(total_deaths) AS total_death_count
FROM COVID..CovidDeaths$
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY total_death_count DESC

-- Checking to see if the total death count is different by filtering for location where continent is null
SELECT location, MAX(total_deaths) AS total_death_count
FROM COVID..CovidDeaths$
WHERE continent IS NULL
GROUP BY location
ORDER BY total_death_count DESC

-- Global death percentage
SELECT SUM(new_cases) AS total_cases, SUM(CAST(new_deaths AS INT)) AS total_deaths, SUM(CAST(new_deaths AS INT))/SUM(new_cases)*100 AS global_death_percentage
FROM COVID..CovidDeaths$
WHERE continent IS NOT NULL
ORDER BY 1,2 

-- Join the two tables - CovideDeaths and CovidVacs
SELECT *
FROM COVID..CovidDeaths$ dea
JOIN COVID..CovidVacs$ VAC
	ON dea.location = vac.location
	AND dea.date = vac.date

-- Total Population versus vaccinations
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
FROM COVID..CovidDeaths$ dea
JOIN COVID..CovidVacs$ VAC
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY  1,2,3

-- Create a new column that keeps a rolling count of the number of people vaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
,	SUM(CONVERT(bigint, vac.new_vaccinations))
	OVER(PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_ppl_vac
FROM COVID..CovidDeaths$ dea
JOIN COVID..CovidVacs$ VAC
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3

-- Use CTE (common table expression) to calculate percentage of population vaccinated per country per day
WITH PopvsVac (Continent, Location, Date, Population, New_vaccinations, Rolling_ppl_vac)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
,	SUM(CONVERT(bigint, vac.new_vaccinations))
	OVER(PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_ppl_vac
FROM COVID..CovidDeaths$ dea
JOIN COVID..CovidVacs$ VAC
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
)
SELECT*, (Rolling_ppl_vac/Population)*100 AS pop_vac_percentage
FROM PopvsVac

-- TEMP TABLE method to accomplish the same as CTE
DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
Rolling_ppl_vac numeric
)
INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
,	SUM(CONVERT(bigint, vac.new_vaccinations))
	OVER(PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_ppl_vac
FROM COVID..CovidDeaths$ dea
JOIN COVID..CovidVacs$ VAC
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL

SELECT*, (Rolling_ppl_vac/Population)*100
FROM #PercentPopulationVaccinated

-- Creating view to store data for later visualizations
CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
,	SUM(CONVERT(bigint, vac.new_vaccinations))
	OVER(PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_ppl_vac
FROM COVID..CovidDeaths$ dea
JOIN COVID..CovidVacs$ VAC
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
