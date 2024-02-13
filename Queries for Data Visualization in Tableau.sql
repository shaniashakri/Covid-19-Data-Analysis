-- Data visualization queries for Tableau
-- https://public.tableau.com/app/profile/shania.shakri/viz/Book1_17078045963330/Dashboard1?publish=yes
    
-- Query 1: Total Cases, Total Deaths, and Death Percentage by Continent:
SELECT 
    SUM(new_cases) AS total_cases, 
    SUM(CAST(new_deaths AS INT)) AS total_deaths, 
    SUM(CAST(new_deaths AS INT)) / SUM(new_cases) * 100 AS death_percentage
FROM 
    PortfolioProject1..['covid-deaths$']
WHERE 
    continent IS NOT NULL
ORDER BY 
    total_cases, total_deaths;


-- Query 2: Total Deaths by Country (Excluding World, European Union, and International)
SELECT 
    location, 
    SUM(CAST(new_deaths AS INT)) AS total_death_count
FROM 
    PortfolioProject1..['covid-deaths$']
WHERE 
    continent IS NULL 
    AND location NOT IN ('World', 'European Union', 'International')
GROUP BY 
    location
ORDER BY 
    total_death_count DESC;


-- Query 3: Countries with Highest Infection Count and Percentage of Population Infected:
SELECT 
    location, 
    population, 
    MAX(total_cases) AS highest_infection_count,  
    MAX((total_cases / population)) * 100 AS percent_population_infected
FROM 
    PortfolioProject1..['covid-deaths$']
GROUP BY 
    location, population
ORDER BY 
    percent_population_infected DESC;



--Query 4: Infection Count and Percentage of Population Infected by Country and Date:
SELECT 
    location, 
    population, 
    date, 
    MAX(total_cases) AS highest_infection_count,  
    MAX((total_cases / population)) * 100 AS percent_population_infected
FROM 
    PortfolioProject1..['covid-deaths$']
GROUP BY 
    location, population, date
ORDER BY 
    percent_population_infected DESC;
