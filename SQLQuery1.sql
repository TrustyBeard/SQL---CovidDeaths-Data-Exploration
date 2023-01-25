-- Checking to make sure data populated upon import of the files.

SELECT *
FROM CovidDeaths


SELECT * 
FROM CovidVaccinations
ORDER BY 3,4

SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM CovidDeaths
ORDER BY 1


SELECT Location, date, total_cases, total_deaths, total_deaths / NULLIF(total_cases, 0) AS MortRate
FROM CovidDeaths
ORDER BY 5


SELECT * from INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME='CovidDeaths'

-- All data types in table CovidDeaths that was imported to this project were varchar.
-- A conversion to a different data type is needed to apply a divide operator
-- and since the import as varchar data type was erroneous altering the table is warranted

ALTER TABLE CovidDeaths
ALTER COLUMN total_cases float;
ALTER TABLE CovidDeaths
ALTER COLUMN total_deaths float;


--Dates must also be updated for sensible ordering

ALTER TABLE CovidDeaths
ALTER COLUMN date date;

SELECT Location, date, total_cases, total_deaths, total_deaths / NULLIF(total_cases, 0) * 100 AS MortalityRate
FROM CovidDeaths
WHERE location like '%states%'
ORDER BY 1, 2

ALTER TABLE CovidDeaths
ALTER COLUMN population bigint;

SELECT Location, date, population, total_cases, (total_cases/population) * 100 AS InfectionRate
FROM CovidDeaths
WHERE location like '%states%'
ORDER BY 1, 2

SELECT Location, population, MAX(total_cases) AS InfectionCount, MAX((total_cases/NULLIF(population, 0))) * 100 AS InfectionRate
FROM CovidDeaths
GROUP BY Location, population
ORDER BY InfectionRate DESC

SELECT Location, MAX(total_deaths) AS DeathCount
FROM CovidDeaths
WHERE continent = ''
GROUP BY Location
ORDER BY DeathCount DESC


SELECT date, SUM(CAST(new_cases AS int)) AS Cases, SUM(Cast(new_deaths AS int)) AS Deaths
, SUM(Cast(new_deaths AS float))/NULLIF(SUM(CAST(new_cases AS float)),0) * 100 AS MortRate
FROM CovidDeaths
WHERE continent <> ''
GROUP BY date
ORDER BY 1

CREATE PROC RollingVacCount @location nvarchar(30)
AS
SELECT dea.continent, dea.location, dea.date, vac.new_vaccinations,
SUM(CONVERT(int, vac.new_vaccinations)) OVER (PARTITION BY dea.location
ORDER BY dea.location, dea.date) AS RollingVacCnt
FROM CovidDeaths dea
JOIN CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent <> '' and dea.location = @location
ORDER BY 2,3

EXEC RollingVacCount @location = 'Japan'

WITH PopvsVac (Continent, Location, Date, Population, new_vaccinations, RollingVacCnt)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(int, vac.new_vaccinations)) OVER (PARTITION BY dea.location
ORDER BY dea.location, dea.date) AS RollingVacCnt
FROM CovidDeaths dea
JOIN CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent <> ''
)
SELECT *, (CONVERT(int, RollingVacCnt)/CONVERT(float, NULLIF(Population, 0))) * 100 AS PercentVaccinated
FROM PopvsVac
WHERE location like '%States%'
ORDER BY 2,3

DROP TABLE IF exists #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
RollingVacCnt numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, TRY_CAST(vac.new_vaccinations as numeric),
SUM(CONVERT(int, vac.new_vaccinations)) OVER (PARTITION BY dea.location
ORDER BY dea.location, dea.date) AS RollingVacCnt
FROM CovidDeaths dea
JOIN CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent <> ''
ORDER BY 2,3

SELECT *, (CONVERT(int, RollingVacCnt)/CONVERT(float, NULLIF(Population, 0))) * 100 AS PercentVaccinated
FROM #PercentPopulationVaccinated
WHERE location like '%Emirates%'

CREATE VIEW PercentPopulationVaccinated as
SELECT dea.continent, dea.location, dea.date, dea.population, TRY_CAST(vac.new_vaccinations as numeric) AS new_vaccinations,
	SUM(CONVERT(int, vac.new_vaccinations)) OVER (PARTITION BY dea.location
ORDER BY dea.location, dea.date) AS RollingVacCnt
FROM CovidDeaths dea
JOIN CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent <> ''

SELECT *
FROM PercentPopulationVaccinated