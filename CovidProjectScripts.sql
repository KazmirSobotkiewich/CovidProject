--SELECT *
--FROM CovidProject..CovidDeaths
--ORDER BY location,date

--SELECT *
--FROM CovidProject..CovidVaccinations
--ORDER BY location,date

-- Select Data that we are going to be using

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM CovidProject..CovidDeaths
ORDER BY location, date


-- Looking at Total Cases vs Total Deaths
-- Shows likelyhood of dying if you contract covid in Canada
SELECT location, date, total_cases, total_deaths, (CONVERT(DECIMAL(18,2), total_deaths) / CONVERT(DECIMAL(18,2), total_cases) )*100 as DeathPercent
FROM CovidProject..CovidDeaths
WHERE location = 'Canada'
ORDER BY location, date DESC;


-- Looking at total Cases vs Population
SELECT location, date, population, total_cases, (CONVERT(DECIMAL(18,2), total_cases) / population )*100 as PercentPopulationInfectd
FROM CovidProject..CovidDeaths
WHERE location = 'Canada'
ORDER BY location, date DESC;


-- Looking at countries with highest infection rate compared to population
SELECT location, MAX(total_cases) as HighestInfectionCount, MAX((CONVERT(DECIMAL(18,2), total_cases) / population )*100) as PercentPopulationInfected
FROM CovidProject..CovidDeaths
GROUP BY location
ORDER BY PercentPopulationInfected DESC


-- Countries with highest death count per population
SELECT location, MAX(CONVERT(DECIMAL(18,2), total_deaths)) as TotalDeathCount
FROM CovidProject..CovidDeaths
WHERE continent IS NOT null
GROUP BY location
ORDER BY TotalDeathCount DESC


-- Continents with highest death count per population
SELECT location, MAX(CONVERT(DECIMAL(18,2), total_deaths)) as TotalDeathCount
FROM CovidProject..CovidDeaths
WHERE continent IS null AND location IN ('Europe', 'North America', 'Asia', 'South America', 'Africa', 'Oceania')
GROUP BY location
ORDER BY TotalDeathCount DESC


-- GLOBAL NUMBERS

--SELECT location, date, total_cases, new_cases, new_deaths
--FROM CovidProject..CovidDeaths
--WHERE continent IS NULL AND location IN ('Europe', 'North America', 'Asia', 'South America', 'Africa', 'Oceania')
----GROUP BY date
--ORDER BY 2,3

SELECT date, SUM(new_cases) AS Sum_New_Cases, SUM(new_deaths) AS Sum_New_Deaths, (SUM(new_deaths) / SUM(new_cases))*100 AS DeathPercent
FROM CovidProject..CovidDeaths
WHERE continent IS NULL AND location IN ('Europe', 'North America', 'Asia', 'South America', 'Africa', 'Oceania') AND new_cases != 0
GROUP BY date
ORDER BY 1,2

--Overall Covid Death rate estimate across the world
SELECT SUM(new_cases) AS Sum_New_Cases, SUM(new_deaths) AS Sum_New_Deaths, (SUM(new_deaths) / SUM(new_cases))*100 AS DeathPercent
FROM CovidProject..CovidDeaths
WHERE continent IS NULL AND location IN ('Europe', 'North America', 'Asia', 'South America', 'Africa', 'Oceania') AND new_cases != 0
ORDER BY 1,2


-- Look at total population vs vaccinations
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
 SUM(CONVERT(DECIMAL(18,2), vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
 --, (RollingPeopleVaccinated/dea.population)*100
FROM CovidProject..CovidDeaths dea
JOIN CovidProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3

-- USE CTE
WITH PopVersusVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
 SUM(CONVERT(DECIMAL(18,2), vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
 --, (RollingPeopleVaccinated/dea.population)*100
FROM CovidProject..CovidDeaths dea
JOIN CovidProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 2,3
)
SELECT *, (RollingPeopleVaccinated/population)*100 AS RollingPeopleVaccinatedPercent
FROM PopVersusVac


-- OR USE TEMP TABLE
DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
RollingPeopleVaccinated numeric
)
INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
 SUM(CONVERT(DECIMAL(18,2), vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
 --, (RollingPeopleVaccinated/dea.population)*100
FROM CovidProject..CovidDeaths dea
JOIN CovidProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
--WHERE dea.continent IS NOT NULL
--ORDER BY 2,3

SELECT *, (RollingPeopleVaccinated/population)*100 AS RollingPeopleVaccinatedPercent
FROM #PercentPopulationVaccinated


-- Creating view to store data for later visualizations
CREATE VIEW PercentPopulationVaccinated as 
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
 SUM(CONVERT(DECIMAL(18,2), vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
 --, (RollingPeopleVaccinated/dea.population)*100
FROM CovidProject..CovidDeaths dea
JOIN CovidProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 2,3

SELECT *
FROM PercentPopulationVaccinated