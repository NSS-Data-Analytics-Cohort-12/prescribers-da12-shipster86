-- ## Prescribers Database

-- For this exericse, you'll be working with a database derived from the [Medicare Part D Prescriber Public Use File](https://www.hhs.gov/guidance/document/medicare-provider-utilization-and-payment-data-part-d-prescriber-0). More information about the data is contained in the Methodology PDF file. See also the included entity-relationship diagram.

-- 1. 
--     a. Which prescriber had the highest total number of claims (totaled over all drugs)? Report the npi and the total number of claims.

SELECT SUM(prescription.total_claim_count), prescription.npi
FROM prescription
	GROUP BY prescription.total_claim_count, prescription.npi
	ORDER BY prescription.total_claim_count DESC;
--npi - 1912011792 - 4538 claims

    
--     b. Repeat the above, but this time report the nppes_provider_first_name, nppes_provider_last_org_name,  specialty_description, and the total number of claims.
SELECT SUM(prescription.total_claim_count), prescription.npi, prescriber.nppes_provider_first_name, prescriber.nppes_provider_last_org_name, prescriber.specialty_description
FROM prescription
	LEFT JOIN prescriber
	USING (npi)
	GROUP BY prescription.total_claim_count, prescription.npi,prescriber.nppes_provider_first_name, prescriber.nppes_provider_last_org_name, prescriber.specialty_description
	ORDER BY prescription.total_claim_count DESC;
--David Coffey, Family Practice, 4538 claims

-- 2.
--     a. Which specialty had the most total number of claims (totaled over all drugs)?
SELECT SUM(prescription.total_claim_count), prescription.npi, prescriber.specialty_description
FROM prescription
	LEFT JOIN prescriber
	USING (npi)
	GROUP BY prescription.total_claim_count, prescription.npi, prescriber.specialty_description
	ORDER BY prescription.total_claim_count DESC;
-- Family Practice

--     b. Which specialty had the most total number of claims for opioids?

SELECT SUM(prescription.total_claim_count) AS total_claims_count, prescriber.specialty_description
FROM prescription
	LEFT JOIN prescriber
	USING (npi)
	LEFT JOIN drug
	USING (drug_name)
	WHERE opioid_drug_flag = 'Y'
	GROUP BY prescriber.specialty_description
	ORDER BY total_claims_count DESC;

--     c. **Challenge Question:** Are there any specialties that appear in the prescriber table that have no associated prescriptions in the prescription table?

-- SELECT prescriber.specialty_description, npi,
-- FROM prescriber
-- FULL JOIN prescription
-- USING (npi)
-- WHERE drug_name IS NULL;

SELECT prescriber.npi, prescriber.specialty_description
FROM prescriber
	LEFT JOIN prescription
	USING (npi)
EXCEPT
SELECT prescription.npi, prescriber.specialty_description
FROM prescription
	LEFT JOIN prescriber
	USING (npi);
--YES
--     d. **Difficult Bonus:** *Do not attempt until you have solved all other problems!* For each specialty, report the percentage of total claims by that specialty which are for opioids. Which specialties have a high percentage of opioids?

-- 3. 
--     a. Which drug (generic_name) had the highest total drug cost?

SELECT SUM(prescription.total_drug_cost) AS total_price, drug.generic_name
FROM drug
	LEFT JOIN prescription
	USING (drug_name)
	WHERE prescription.total_drug_cost IS NOT NULL
	GROUP BY drug.generic_name
	ORDER BY total_price DESC;
--INSULIN GLARGINE, HUM.REC.ANLOG
--     b. Which drug (generic_name) has the hightest total cost per day? **Bonus: Round your cost per day column to 2 decimal places. Google ROUND to see how this works.**
SELECT (total_drug_cost/total_day_supply) AS cost_per_day, drug.generic_name
FROM prescription
	FULL JOIN drug
	USING (drug_name)
	WHERE total_drug_cost IS NOT NULL
	ORDER BY cost_per_day DESC;
-- IMMUN GLOB G(IGG)/GLY/IGA OV50

-- 4. 
--     a. For each drug in the drug table, return the drug name and then a column named 'drug_type' which says 'opioid' for drugs which have opioid_drug_flag = 'Y', says 'antibiotic' for those drugs which have antibiotic_drug_flag = 'Y', and says 'neither' for all other drugs. **Hint:** You may want to use a CASE expression for this. See https://www.postgresqltutorial.com/postgresql-tutorial/postgresql-case/ 
SELECT 
    drug.drug_name,
    CASE 
        WHEN opioid_drug_flag = 'Y' THEN 'opioid'
        WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
        ELSE 'neither'
    END AS drug_type
FROM 
    drug;

--     b. Building off of the query you wrote for part a, determine whether more was spent (total_drug_cost) on opioids or on antibiotics. Hint: Format the total costs as MONEY for easier comparision.
SELECT SUM(prescription.total_drug_cost) AS total_price,
    CASE 
        WHEN opioid_drug_flag = 'Y' THEN 'opioid'
        WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
        ELSE 'neither'
    END AS drug_type
FROM 
    drug
	LEFT JOIN prescription
	USING (drug_name)
	WHERE prescription.total_drug_cost IS NOT NULL
	GROUP BY drug_type
	ORDER BY total_price DESC;

WITH total_costs AS (
    SELECT 
        SUM(prescription.total_drug_cost) AS total_price,
        CASE 
            WHEN opioid_drug_flag = 'Y' THEN 'opioid'
            WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
            ELSE 'neither'
        END AS drug_type
    FROM 
        drug
        LEFT JOIN prescription
        USING (drug_name)
    WHERE 
        prescription.total_drug_cost IS NOT NULL
    GROUP BY 
        drug_type
)
SELECT 
    total_price,
    CAST(total_price AS MONEY) AS total_price_money,
    drug_type
FROM 
    total_costs
ORDER BY 
    total_price DESC;
-- OPIODS

-- 5. 
--     a. How many CBSAs are in Tennessee? **Warning:** The cbsa table contains information for all states, not just Tennessee.
SELECT COUNT(*)
FROM cbsa
	WHERE cbsaname LIKE '%TN';
	--33



--     b. Which cbsa has the largest combined population? Which has the smallest? Report the CBSA name and total population.
-- SELECT population, cbsaname 
-- FROM cbsa
-- LEFT JOIN 
-- ON fipscounty
-- ORDER BY population DESC;




--     c. What is the largest (in terms of population) county which is not included in a CBSA? Report the county name and population.

-- 6. 
--     a. Find all rows in the prescription table where total_claims is at least 3000. Report the drug_name and the total_claim_count.

--     b. For each instance that you found in part a, add a column that indicates whether the drug is an opioid.

--     c. Add another column to you answer from the previous part which gives the prescriber first and last name associated with each row.

-- 7. The goal of this exercise is to generate a full list of all pain management specialists in Nashville and the number of claims they had for each opioid. **Hint:** The results from all 3 parts will have 637 rows.

--     a. First, create a list of all npi/drug_name combinations for pain management specialists (specialty_description = 'Pain Management) in the city of Nashville (nppes_provider_city = 'NASHVILLE'), where the drug is an opioid (opiod_drug_flag = 'Y'). **Warning:** Double-check your query before running it. You will only need to use the prescriber and drug tables since you don't need the claims numbers yet.

--     b. Next, report the number of claims per drug per prescriber. Be sure to include all combinations, whether or not the prescriber had any claims. You should report the npi, the drug name, and the number of claims (total_claim_count).
    
--     c. Finally, if you have not done so already, fill in any missing values for total_claim_count with 0. Hint - Google the COALESCE function.
