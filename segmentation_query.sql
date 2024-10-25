-- EXTRACTING DATA INTO TEMP TABLE
WITH student_salary_credits AS(
SELECT c.accountnumber,
		c.email,
		t.transactionid,
		t.transactiondate,
		t.transactionamount,
		t.description
FROM customers AS c
INNER JOIN transactions AS t
ON c.accountnumber = t.accountnumber
WHERE LOWER(c.status) = 'student'
AND LOWER(t.description) LIKE '%salary%'
AND t.transactiondate >= DATEADD(MONTH, -12, '2023-08-31')
AND LOWER(t.transactiontype) = 'credit'
),

-- RFM MODELING
rfm AS(
SELECT accountnumber,
		MAX(transactiondate) AS lasttransaction, 
		DATEDIFF(MONTH, MAX(transactiondate), '2023-08-31') AS recency, --recency
		COUNT(transactionid) AS frequency, -- frequency
		AVG(transactionamount) AS monetary -- monetary
FROM student_salary_credits
GROUP BY accountnumber
HAVING AVG(transactionamount) >= 20000
),

-- RFM SCORING
rfm_scores AS(
SELECT accountnumber,
		lasttransaction,
		frequency,
		recency,
		monetary,
		-- Score customers based on recency
		CASE 
			WHEN recency = 0 THEN 10
			WHEN recency < 3 THEN 7
			WHEN recency < 5 THEN 4
			ELSE 1
		END AS r_score,
				
		-- Score customers based on recency
		CASE 
			WHEN frequency = 12 THEN 10
			WHEN frequency >= 9 THEN 7
			WHEN frequency >= 6 THEN 4
			ELSE 1
		END AS f_score,

		-- Score customers based on monetary value
		CASE 
			WHEN monetary > 60000 THEN 10
			WHEN monetary > 40000 THEN 7
			WHEN monetary BETWEEN 30000 AND 40000 THEN 4
			ELSE 1
		END AS m_score
FROM rfm
),

-- Customer Segmentation
segmentation AS(
SELECT	s.accountnumber AS AccountNo,
		c.email,
		lasttransaction AS LastTransactionDate,
		recency AS MonthSinceLastSalary,
		frequency AS SalariesReceived,
		monetary AS AverageSalary,
		CAST((r_score + f_score + m_score) AS FLOAT)/30 AS RFM,
		 -- group salaries based on monetary value
		CASE
			WHEN monetary > 60000 THEN 'Above R60K'
			WHEN monetary BETWEEN 40000 AND 60000 THEN 'R40k-R60k'
			WHEN monetary BETWEEN 30000 AND 40000 THEN 'R30k-R40k'
			ELSE 'R20K-R30K'
		END AS SalaryRange,

		CASE
			WHEN CAST((r_score + f_score + m_score) AS FLOAT)/30 >  0.8 THEN 'Tier 1 Customer'
			WHEN CAST((r_score + f_score + m_score) AS FLOAT)/30 >= 0.6 THEN 'Tier 2 Customer'
			WHEN CAST((r_score + f_score + m_score) AS FLOAT)/30 >= 0.5 THEN 'Tier 3 Customer'
			ELSE 'Tier 4 Customer'
		END AS Segments
FROM	rfm_scores AS s
LEFT JOIN customers AS c 
ON s.accountnumber = c.accountnumber
)

SELECT *
FROM segmentation