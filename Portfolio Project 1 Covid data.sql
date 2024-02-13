-- Data downloaded from https://ourworldindata.org/covid-deaths
-- Query 1: Retrieving COVID death data for locations with continents specified
SELECT 
    location, 
    date, 
    new_cases, 
    total_cases, 
    total_deaths, 
    population
FROM 
    PortfolioProject1..['covid-deaths$']
WHERE 
    continent IS NOT NULL
ORDER BY 
    location, date;

-- Query 2: Calculating death percentage for India
SELECT 
    location, 
    date, 
    total_cases, 
    total_deaths, 
    (CAST(total_deaths AS FLOAT) / CAST(total_cases AS FLOAT)) * 100 AS DeathPercentage
FROM 
    PortfolioProject1..['covid-deaths$']
WHERE 
    location LIKE '%india' 
    AND continent IS NOT NULL
ORDER BY 
    location, date;

-- Query 3: Calculating percentage of the population infected in India
SELECT 
    location, 
    date, 
    total_cases, 
    population, 
    (CAST(total_cases AS FLOAT) / CAST(population AS FLOAT)) * 100 AS InfectedPopulationPercentage
FROM 
    PortfolioProject1..['covid-deaths$']
WHERE 
    location LIKE '%india' 
    AND continent IS NOT NULL
ORDER BY 
    location, date;

-- Query 4: Countries with the highest infection rate compared to population
SELECT 
    location, 
    population, 
    MAX(total_cases) AS HighestInfectionCount,  
    MAX(CAST(total_cases AS FLOAT) / CAST(population AS FLOAT)) * 100 AS InfectedPopulationPercentage
FROM 
    PortfolioProject1..['covid-deaths$']
WHERE 
    continent IS NOT NULL
GROUP BY 
    location, population
ORDER BY 
    InfectedPopulationPercentage DESC;

-- Query 5: Countries with the highest death count
SELECT 
    location, 
    MAX(total_deaths) AS TotalDeathCount
FROM 
    PortfolioProject1..['covid-deaths$']
WHERE 
    continent IS NOT NULL
GROUP BY 
    location
ORDER BY 
    TotalDeathCount DESC;

-- Query 6: Continents with the highest death count
SELECT 
    continent, 
    MAX(total_deaths) AS TotalDeathCount
FROM 
    PortfolioProject1..['covid-deaths$']
WHERE 
    continent IS NOT NULL
GROUP BY 
    continent
ORDER BY 
    TotalDeathCount DESC;

-- Query 7: Global COVID statistics
SELECT 
    date,
    SUM(new_cases) AS total_cases,
    SUM(CAST(new_deaths AS FLOAT)) AS total_deaths,
    (SUM(CAST(new_deaths AS FLOAT)) / NULLIF(SUM(CAST(new_cases AS FLOAT)), 0)) * 100 AS DeathPercentage
FROM 
    PortfolioProject1..['covid-deaths$']
WHERE 
    continent IS NOT NULL
GROUP BY 
    date
ORDER BY 
    date;


--Query 8: Countries with Highest Cases per Million Population:
SELECT 
    location AS country,
    MAX(date) AS latest_date,
    MAX(total_cases) AS total_cases,
    MAX(total_cases) / MAX(population) * 1000000 AS cases_per_million
FROM 
    PortfolioProject1..['covid-deaths$']
WHERE 
    continent IS NOT NULL
GROUP BY 
    location
ORDER BY 
    cases_per_million DESC;



-- Quesry 9: Top 10 Countries by Vaccination Rate Increase:
SELECT TOP 10
    location AS country,
    MAX(date) AS latest_date,
    MAX(CAST(new_vaccinations AS FLOAT)) AS max_daily_vaccinations,
    (MAX(CAST(new_vaccinations AS FLOAT)) - MIN(CAST(new_vaccinations AS FLOAT))) AS vaccination_rate_increase
FROM 
    PortfolioProject1..['covid-vaccines$']
WHERE 
    continent IS NOT NULL
GROUP BY 
    location
ORDER BY 
    vaccination_rate_increase DESC;


-- Query 10: Joining COVID death and vaccine tables
SELECT *
FROM 
    PortfolioProject1..['covid-deaths$'] dth
JOIN 
    PortfolioProject1..['covid-vaccines$'] vac
ON 
    dth.location = vac.location
    AND dth.date = vac.date;

-- Query 11: Percentage of population vaccinated over time
WITH PopulationvsVaccination (Continent, location, date, population, new_vaccinations, RollingPeopleVaccinated) AS
(
    -- Subquery to calculate rolling vaccination count
    SELECT 
        dth.continent, 
        dth.location, 
        dth.date, 
        dth.population, 
        vac.new_vaccinations, 
        SUM(CAST(vac.new_vaccinations AS FLOAT)) OVER (
            PARTITION BY dth.location 
            ORDER BY dth.date
        ) AS RollingPeopleVaccinated
    FROM 
        PortfolioProject1..['covid-deaths$'] dth
        JOIN PortfolioProject1..['covid-vaccines$'] vac 
        ON dth.location = vac.location 
        AND dth.date = vac.date
    WHERE 
        dth.continent IS NOT NULL
)
-- Final query to calculate percentage of population vaccinated
SELECT 
    *, 
    (RollingPeopleVaccinated / population) * 100 AS PercentPeopleVaccinated
FROM 
    PopulationvsVaccination;


-- Query 12: Creating temp table to store intermediate results
IF OBJECT_ID('tempdb..#PopulationvsVaccination', 'U') IS NOT NULL
    DROP TABLE #PopulationvsVaccination;

CREATE TABLE #PopulationvsVaccination (
    continent NVARCHAR(255),
    location NVARCHAR(255),
    date DATE,
    population NUMERIC,
    new_vaccinations NUMERIC,
    RollingPeopleVaccinated NUMERIC
);

-- Populating the temp table
INSERT INTO #PopulationvsVaccination (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
SELECT 
    dth.continent, 
    dth.location, 
    dth.date, 
    dth.population, 
    vac.new_vaccinations, 
    SUM(CAST(vac.new_vaccinations AS FLOAT)) OVER (
        PARTITION BY dth.location 
        ORDER BY dth.date
    ) AS RollingPeopleVaccinated
FROM 
    PortfolioProject1..['covid-deaths$'] dth
JOIN 
    PortfolioProject1..['covid-vaccines$'] vac 
ON 
    dth.location = vac.location 
    AND dth.date = vac.date
WHERE 
    dth.continent IS NOT NULL;

-- Final query to calculate percentage of population vaccinated
SELECT 
    *, 
    (RollingPeopleVaccinated / population) * 100 AS PercentPeopleVaccinated
FROM 
    #PopulationvsVaccination;
