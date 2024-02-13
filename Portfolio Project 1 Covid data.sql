--SELECT *
--FROM PortfolioProject1..['covid-vaccines$']

--SELECT *
--FROM PortfolioProject1..['covid-deaths$']

SELECT location, date, new_cases, total_cases, total_deaths, population
FROM PortfolioProject1..['covid-deaths$']
WHERE continent is not null
order by 1,2

-- Total Cases vs total Deaths
SELECT location, date, total_cases, total_deaths, (cast(total_deaths as float)/cast(total_cases as float))*100 as DeathPercentage
FROM PortfolioProject1..['covid-deaths$']
WHERE location like '%india' AND continent is not NULL
order by 1,2

--The Death percentage (for India) as of February 04th, 2024 stands to approximately 1.184%, that's still alot!
--And, that's the likelihood of dying if one contacts Covid.

--Total cases vs Population
--Percentage of the crowd that got covid
SELECT location, date, total_cases, population, (cast(total_cases as float)/cast(population as float))*100 as InfectedPopulationPercentage
FROM PortfolioProject1..['covid-deaths$']
WHERE location like '%india' AND continent is not NULL
order by 1,2

--Countries with highest infection rate as compared to Population
SELECT location, population, MAX(total_cases) as HighestInfectionCount,  MAX(cast(total_cases as float)/cast(population as float))*100 as InfectedPopulationPercentage
FROM PortfolioProject1..['covid-deaths$']
WHERE continent is not NULL
GROUP by location, population
order by InfectedPopulationPercentage desc


--Countries with highest deaths as compared to Population
SELECT location, MAX(total_deaths) as TotalDeathCount
FROM PortfolioProject1..['covid-deaths$']
WHERE continent is not null
GROUP by location
order by TotalDeathCount desc


--Breaking this down by continent


--Countries with highest deaths as compared to Population
SELECT location, MAX(total_deaths) as TotalDeathCount
FROM PortfolioProject1..['covid-deaths$']
WHERE continent is null
GROUP by location
order by TotalDeathCount desc

-- Showing continents with the highest death count
--Countries with highest deaths as compared to Population
SELECT continent, MAX(total_deaths) as TotalDeathCount
FROM PortfolioProject1..['covid-deaths$']
WHERE continent is not NULL
GROUP by continent
order by TotalDeathCount desc



-- Global Numbers

SELECT 
	date,
    SUM(new_cases) AS total_cases,
    SUM(CAST(new_deaths AS FLOAT)) AS total_deaths,
    (SUM(CAST(new_deaths AS FLOAT)) / NULLIF(SUM(CAST(new_cases AS FLOAT)), 0)) * 100 AS DeathPercentage
FROM 
    PortfolioProject1..['covid-deaths$']
WHERE 
    continent is not NULL
GROUP BY 
    date
ORDER BY 
    1, 2;


-- Joining the tables for ease of access

SELECT *
FROM PortfolioProject1..['covid-deaths$'] dth
JOIN PortfolioProject1..['covid-vaccines$'] vac
	On dth.location = vac.location
	and dth.date = vac.date


--Looking at Total Population vs Vaccination
SELECT dth.continent, dth.location, dth.population, vac.new_vaccinations, SUM(cast(vac.new_vaccinations as float)) OVER (Partition By dth.location Order by dth.location, dth.date)
as RollingPeopleVaccinated
FROM PortfolioProject1..['covid-deaths$'] dth
JOIN PortfolioProject1..['covid-vaccines$'] vac
	On dth.location = vac.location
	and dth.date = vac.date
WHERE dth.continent is not null
order by 2,3


--Use CTE
WITH PopulationvsVaccination (Continent, location, date, population, new_vaccinations, RollingPeoplVaccinated) as
(
    SELECT 
        dth.continent, 
        dth.location, 
        dth.date, 
        dth.population, 
        vac.new_vaccinations, 
        SUM(CAST(vac.new_vaccinations AS FLOAT)) OVER (
            PARTITION BY dth.location 
            ORDER BY dth.location, dth.date
        ) AS RollingPeoplVaccinated
    FROM 
        PortfolioProject1..['covid-deaths$'] dth
        JOIN PortfolioProject1..['covid-vaccines$'] vac 
		ON dth.location = vac.location 
		AND dth.date = vac.date
    WHERE 
        dth.continent IS NOT NULL
)
Select *, (RollingPeoplVaccinated/population)*100
FROM PopulationvsVaccination


-- Temp Table
IF OBJECT_ID('tempdb..#PercentPeopleVaccinated', 'U') IS NOT NULL
    DROP TABLE #PercentPeopleVaccinated;
CREATE TABLE #PercentPeopleVaccinated
(
    Continent nvarchar(255),
    Location nvarchar(255),
    Data datetime,
    Population Numeric,
    New_vaccinations numeric,
    RollingPeoplVaccinated numeric
)

INSERT INTO #PercentPeopleVaccinated (Continent, Location, Data, Population, New_vaccinations, RollingPeoplVaccinated)
    SELECT 
        dth.continent, 
        dth.location, 
        dth.date, 
        dth.population, 
        vac.new_vaccinations, 
        SUM(CAST(vac.new_vaccinations AS FLOAT)) OVER (
            PARTITION BY dth.location 
            ORDER BY dth.date
        ) AS RollingPeoplVaccinated -- This column name should match the one in table creation
    FROM 
        PortfolioProject1..['covid-deaths$'] dth
        JOIN PortfolioProject1..['covid-vaccines$'] vac 
		ON dth.location = vac.location 
		AND dth.date = vac.date
--  WHERE dth.continent IS NOT NULL;

SELECT *, (RollingPeoplVaccinated / population) * 100 -- PercentPeopleVaccinated
FROM #PercentPeopleVaccinated;



-- Creating view, for data visualization
Create View PercentPeopleVaccinated as
    SELECT 
        dth.continent, 
        dth.location, 
        dth.date, 
        dth.population, 
        vac.new_vaccinations, 
        SUM(CAST(vac.new_vaccinations AS FLOAT)) OVER (
            PARTITION BY dth.location 
            ORDER BY dth.date
        ) AS RollingPeoplVaccinated -- This column name should match the one in table creation
    FROM 
        PortfolioProject1..['covid-deaths$'] dth
        JOIN PortfolioProject1..['covid-vaccines$'] vac 
		ON dth.location = vac.location 
		AND dth.date = vac.date
		WHERE dth.continent IS NOT NULL
	
