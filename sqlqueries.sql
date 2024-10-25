-- DATA CLEANING 
-- Check Null Values
SELECT *
FROM customers
WHERE customerid IS NULL
OR firstname IS NULL
OR lastname IS NULL
OR dateofbirth IS NULL
OR email IS NULL
OR phonenumber IS NULL
OR accounttype IS NULL
OR opendate IS NULL
OR accountnumber IS NULL
OR status IS NULL

-- Check Duplicates
SELECT customerid,
		accountnumber,
		COUNT(*) AS counts
FROM customers
GROUP BY customerid,
		accountnumber
HAVING COUNT(*) > 1

-- EXPLORE CUSTOMERS TABLE
-- Number of customers - 10000
SELECT COUNT(accountnumber) AS count
FROM customers

-- Different Employment Statuses - student/employed
SELECT DISTINCT(status)
FROM customers

-- Count of different statuses - student(7013)/employed(2987)
SELECT status,
		COUNT(*)
FROM customers
GROUP BY status

-- EXPLORE TRANSACTIONS TABLES
-- Number of transactions - 283041
SELECT COUNT(*) AS count
FROM transactions

-- Most recent and oldest transaction - 29 Sept 2023 & 23 Jan 2021
SELECT MAX(transactiondate) AS recent,
		MIN(transactiondate) AS oldest 
FROM transactions

-- Highest & lowest transaction amount - 69989 & 5
SELECT MAX(transactionamount) AS highest,
		MIN(transactionamount) AS lowest 
FROM transactions

-- Number of transaction types - credit(157667)/debit(125374)
SELECT transactiontype,
		COUNT(*)
FROM transactions
GROUP BY transactiontype;

-- Extracting data into a temporary table (CTE) for student salary-related transactions.
WITH student_salary_credits AS (
    SELECT 
        c.accountnumber,       -- Customer's account number
        c.email,               -- Customer's email for contact/reference
        t.transactionid,       -- Unique ID for each transaction
        t.transactiondate,     -- Date of the transaction
        t.transactionamount,   -- Amount involved in the transaction
        t.description          -- Description of the transaction (e.g., 'salary')
    FROM 
        customers AS c
    INNER JOIN 
        transactions AS t ON c.accountnumber = t.accountnumber -- Joining customers with their transactions
    WHERE 
        LOWER(c.status) = 'student' -- Filtering customers with 'student' status
        AND LOWER(t.description) LIKE '%salary%' -- Including transactions that mention 'salary' in their description
        AND t.transactiondate >= DATEADD(MONTH, -12, '2023-08-31') -- Transactions from the last 12 months up to '2023-08-31'
        AND LOWER(t.transactiontype) = 'credit' -- Considering only credit transactions
),

-- RFM Modeling: Calculate Recency, Frequency, and Monetary values for each customer.
rfm AS (
    SELECT 
        accountnumber,                              -- Customer's account number
        MAX(transactiondate) AS lasttransaction,    -- Date of the most recent transaction
        DATEDIFF(MONTH, MAX(transactiondate), '2023-08-31') AS recency, -- Months since the last transaction
        COUNT(transactionid) AS frequency,          -- Total number of transactions in the past year (Frequency)
        AVG(transactionamount) AS monetary          -- Average transaction amount (Monetary value)
    FROM 
        student_salary_credits
    GROUP BY 
        accountnumber
    HAVING 
        AVG(transactionamount) >= 20000 -- Filter customers with an average transaction amount of at least 20,000
),

-- RFM Scoring: Assign scores based on Recency, Frequency, and Monetary values.
rfm_scores AS (
    SELECT 
        accountnumber,  -- Customer's account number
        lasttransaction, -- Date of the most recent transaction
        frequency,       -- Number of transactions in the past year
        recency,         -- Months since the last transaction
        monetary,        -- Average transaction amount
        
        -- Scoring based on Recency: recent transactions get higher scores.
        CASE 
            WHEN recency = 0 THEN 10 -- Most recent transactions get the highest score.
            WHEN recency < 3 THEN 7  -- Transactions within 3 months get a slightly lower score.
            WHEN recency < 5 THEN 4  -- Transactions within 5 months get a medium score.
            ELSE 1                  -- Older transactions get the lowest score.
        END AS r_score,

        -- Scoring based on Frequency: more frequent transactions get higher scores.
        CASE 
            WHEN frequency = 12 THEN 10 -- Monthly transactions get the highest score.
            WHEN frequency >= 9 THEN 7  -- 9 or more transactions get a high score.
            WHEN frequency >= 6 THEN 4  -- 6 or more transactions get a medium score.
            ELSE 1                     -- Fewer transactions get the lowest score.
        END AS f_score,

        -- Scoring based on Monetary value: higher transaction amounts get higher scores.
        CASE 
            WHEN monetary > 60000 THEN 10 -- High average salary gets the highest score.
            WHEN monetary > 40000 THEN 7  -- Medium-high salary range.
            WHEN monetary BETWEEN 30000 AND 40000 THEN 4 -- Medium salary range.
            ELSE 1 -- Low average salary gets the lowest score.
        END AS m_score
    FROM 
        rfm
),

-- Customer Segmentation: Classify customers based on their RFM scores.
segmentation AS (
    SELECT 
        s.accountnumber AS AccountNo,     -- Customer's account number for output
        c.email,                          -- Customer's email for output
        lasttransaction AS LastTransactionDate, -- Most recent transaction date
        recency AS MonthSinceLastSalary,        -- Months since the last salary transaction
        frequency AS SalariesReceived,          -- Total number of salary transactions
        monetary AS AverageSalary,              -- Average salary amount received
        -- Calculate overall RFM score as an average of individual scores.
        CAST((r_score + f_score + m_score) AS FLOAT) / 30 AS RFM,

        -- Group customers into salary ranges based on average salary.
        CASE
            WHEN monetary > 60000 THEN 'Above R60K' -- High salary range
            WHEN monetary BETWEEN 40000 AND 60000 THEN 'R40k-R60k' -- Medium-high salary range
            WHEN monetary BETWEEN 30000 AND 40000 THEN 'R30k-R40k' -- Medium salary range
            ELSE 'R20K-R30K' -- Lower salary range
        END AS SalaryRange,

        -- Segment customers into tiers based on their overall RFM score.
        CASE
            WHEN CAST((r_score + f_score + m_score) AS FLOAT) / 30 > 0.8 THEN 'Tier 1 Customer' -- Top-tier customers
            WHEN CAST((r_score + f_score + m_score) AS FLOAT) / 30 >= 0.6 THEN 'Tier 2 Customer' -- Second-tier customers
            WHEN CAST((r_score + f_score + m_score) AS FLOAT) / 30 >= 0.5 THEN 'Tier 3 Customer' -- Third-tier customers
            ELSE 'Tier 4 Customer' -- Lowest-tier customers
        END AS Segments
    FROM 
        rfm_scores AS s
    LEFT JOIN 
        customers AS c ON s.accountnumber = c.accountnumber -- Join to get the email of each customer.
)

-- Output the final customer segmentation data.
SELECT *
FROM segmentation;
 