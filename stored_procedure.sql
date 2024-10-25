CREATE PROCEDURE GetCustomerSegments
    @EmploymentStatus NVARCHAR(50),  -- Employment status filter (e.g., 'student')
    @DateCriteria DATE,              -- The reference date for filtering transactions and calculating recency
    @Description NVARCHAR(50)        -- A keyword to filter transactions by description (e.g., 'salary')
AS
BEGIN
    SET NOCOUNT ON; -- Prevents extra result sets from being sent back to the client to improve performance

    -- Extract transactions from the past 12 months for students with a salary description
    WITH student_salary_credits AS (
        SELECT 
            c.accountnumber,  -- Customer account number
            c.email,          -- Customer email
            t.transactionid,  -- Transaction identifier
            t.transactiondate,-- Date of the transaction
            t.transactionamount, -- Amount involved in the transaction
            t.description     -- Description of the transaction (e.g., 'salary')
        FROM 
            customers AS c
        INNER JOIN 
            transactions AS t ON c.accountnumber = t.accountnumber -- Join customers to their transactions
        WHERE 
            LOWER(c.status) = LOWER(@EmploymentStatus)  -- Match the employment status with the input parameter
            AND LOWER(t.description) LIKE '%' + LOWER(@Description) + '%' -- Filter transactions containing the specified description
            AND t.transactiondate >= DATEADD(MONTH, -12, @DateCriteria) -- Consider transactions within the last 12 months from the given date
            AND LOWER(t.transactiontype) = 'credit' -- Only include transactions that are credits
    ),

    -- RFM Modeling: Calculate Recency, Frequency, and Monetary value for each customer
    rfm AS (
        SELECT 
            accountnumber,   -- Customer account number
            MAX(transactiondate) AS lasttransaction,  -- Date of the most recent transaction
            DATEDIFF(MONTH, MAX(transactiondate), @DateCriteria) AS recency, -- Number of months since the last transaction (Recency)
            COUNT(transactionid) AS frequency, -- Total number of transactions in the past year (Frequency)
            AVG(transactionamount) AS monetary -- Average transaction amount (Monetary value)
        FROM 
            student_salary_credits
        GROUP BY 
            accountnumber
        HAVING 
            AVG(transactionamount) >= 20000 -- Include only those with an average salary transaction amount of at least 20,000
    ),

    -- RFM Scoring: Assign scores to each customer based on Recency, Frequency, and Monetary values
    rfm_scores AS (
        SELECT 
            accountnumber,   -- Customer account number
            lasttransaction, -- Most recent transaction date
            frequency,       -- Number of transactions in the past year
            recency,         -- Months since the last transaction
            monetary,        -- Average transaction amount
            -- Calculate the recency score: higher scores for more recent transactions
            CASE 
                WHEN recency = 0 THEN 10 -- Most recent transactions get the highest score
                WHEN recency < 3 THEN 7  -- Recent transactions within 3 months
                WHEN recency < 5 THEN 4  -- Less recent transactions within 5 months
                ELSE 1                  -- Older transactions get the lowest score
            END AS r_score,
                
            -- Calculate the frequency score: higher scores for more frequent transactions
            CASE 
                WHEN frequency = 12 THEN 10 -- Monthly transactions get the highest score
                WHEN frequency >= 9 THEN 7  -- 9 or more transactions in the past year
                WHEN frequency >= 6 THEN 4  -- 6 or more transactions in the past year
                ELSE 1                     -- Fewer transactions get the lowest score
            END AS f_score,

            -- Calculate the monetary score: higher scores for higher average transaction amounts
            CASE 
                WHEN monetary > 60000 THEN 10 -- Highest scores for average amounts above 60,000
                WHEN monetary > 40000 THEN 7  -- Scores for amounts between 40,000 and 60,000
                WHEN monetary BETWEEN 30000 AND 40000 THEN 4 -- Scores for amounts between 30,000 and 40,000
                ELSE 1 -- Lowest scores for average amounts below 30,000
            END AS m_score
        FROM 
            rfm
    ),

    -- Customer Segmentation: Classify customers based on RFM scores
    segmentation AS (
        SELECT 
            s.accountnumber AS AccountNo,  -- Renaming the account number for output clarity
            c.email,                       -- Including email for communication or analysis
            lasttransaction AS LastTransactionDate, -- Most recent transaction date
            recency AS MonthSinceLastSalary,        -- Number of months since last salary transaction
            frequency AS SalariesReceived,          -- Total salary transactions in the past year
            monetary AS AverageSalary,              -- Average salary amount received
            -- Calculate the overall RFM score by averaging the individual scores
            CAST((r_score + f_score + m_score) AS FLOAT) / 30 AS RFM,
            -- Categorize customers into salary ranges based on average salary amount
            CASE
                WHEN monetary > 60000 THEN 'Above R60K' -- High salary range
                WHEN monetary BETWEEN 40000 AND 60000 THEN 'R40k-R60k' -- Medium-high range
                WHEN monetary BETWEEN 30000 AND 40000 THEN 'R30k-R40k' -- Medium range
                ELSE 'R20K-R30K' -- Lower range
            END AS SalaryRange,
            
            -- Assign customers to segments based on their RFM score
            CASE
                WHEN CAST((r_score + f_score + m_score) AS FLOAT) / 30 > 0.8 THEN 'Tier 1 Customer' -- Top tier
                WHEN CAST((r_score + f_score + m_score) AS FLOAT) / 30 >= 0.6 THEN 'Tier 2 Customer' -- Second tier
                WHEN CAST((r_score + f_score + m_score) AS FLOAT) / 30 >= 0.5 THEN 'Tier 3 Customer' -- Third tier
                ELSE 'Tier 4 Customer' -- Lowest tier
            END AS Segments
        FROM 
            rfm_scores AS s
        LEFT JOIN 
            customers AS c ON s.accountnumber = c.accountnumber -- Include email from customers table for each account
    )

    -- Final output: return the customer segmentation result
    SELECT *
    FROM segmentation;

END
GO
EXEC GetCustomerSegments 
    @EmploymentStatus = 'student', 
    @DateCriteria = '2023-08-31', 
    @Description = 'salary';

