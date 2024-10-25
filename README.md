# Customer Segmentation Analysis

## Project Background and Overview

NedCap Bank serves a large student client base, many of whom open their accounts during their college years. As these students transition into the workforce, their financial needs evolve. Recognizing an opportunity to better serve these clients, NedCap Bank seeks to identify former student account holders who have become employed and are now regularly receiving salary deposits. This project focuses on segmenting these clients to offer tailored services such as loans, credit cards, and account upgrades. The analysis aims to identify the most valuable clients and provide data-driven recommendations for targeted marketing campaigns.

## Data Structure Overview

The analysis was conducted using two main datasets:

- **Customers Table**: Includes customer identifiers, personal details, account information, and employment status.
- **Transactions Table**: Contains transaction records for all customers between 2021 and 2023, detailing transaction types, amounts, and timestamps.

The data was cleaned and integrated using SQL Server, and an RFM (Recency, Frequency, Monetary) analysis was performed to segment clients based on their salary deposits.

## Executive Summary

This analysis identifies NedCap Bank's former student clients who are now regular salary earners, focusing on those with consistent salary inflows over the past year. Customers were segmented into tiers based on their RFM scores, highlighting their engagement and potential value to the bank. The findings suggest that around 20% of these clients fall into the highest-value segment, making them ideal targets for premium financial products and services. The detailed insights provide a roadmap for enhancing client engagement through tailored marketing strategies.

## Insights Deep Dive

1. **Customer Segmentation Using RFM Model**:
   - **Recency**: Measures the time since a customer's last salary deposit.
   - **Frequency**: Indicates the number of salary deposits in the past year.
   - **Monetary**: Reflects the average salary amount received.

   Each of these metrics was scored, combined into an overall RFM score, and then used to categorize clients into four tiers:
   - **Tier 1**: High-value customers (RFM score ≥ 80%)
   - **Tier 2**: Growing potential (RFM score 60-80%)
   - **Tier 3**: Average engagement (RFM score 50-60%)
   - **Tier 4**: Low engagement (RFM score < 50%)

2. **Key Findings**:
   - About 20% of the identified customers have an RFM score of 80% or above, indicating high engagement and consistent salary deposits.
   - Customers in the Tier 2 segment show potential for growth, with slightly lower frequency or monetary scores.
   - Tiers 3 and 4 consist of customers who might benefit from additional engagement and support to increase their banking activity.

## Recommendations

Based on the analysis, the following recommendations are proposed to enhance client retention and engagement:

- **Tier 1 Customers**: Focus on premium offerings like high-value loans, exclusive credit cards, and investment accounts. Personalized marketing campaigns can reinforce loyalty and promote further engagement.
- **Tier 2 Customers**: Introduce tailored loan products and salary advance options, encouraging these clients to utilize more of NedCap's services. Incentives for referrals could help drive new customer acquisition.
- **Tier 3 Customers**: Provide a welcome package highlighting services for working professionals. Educational content on financial management could increase product adoption.
- **Tier 4 Customers**: Develop personalized financial plans and offer access to affordable banking services. Support these clients with tools to manage their finances effectively, potentially improving their RFM scores.

## Technical Details

- **Data Cleaning & Preparation**: Managed missing values, duplicates, and normalized date features for consistency.
- **Database Setup**: Imported customer and transaction data into SQL Server and created stored procedures to automate the RFM analysis process.
- **RFM Calculation**: A custom scoring system was implemented to assign values to recency, frequency, and monetary metrics, with a maximum RFM score of 30. The results were normalized to percentages for easier interpretation.
- **Visualization**: Segmentation results were visualized using Excel, featuring charts to display the distribution of RFM scores across different customer tiers.

### Tech Stack

- **SQL Server Express 2022**: Data manipulation, cleaning, and segmentation.
- **Excel**: Visualization of RFM analysis results.
- **PowerPoint**: Presentation of insights and recommendations.

## Caveats and Assumptions

- The analysis assumes that all salary transactions are accurately labeled in the transaction records.
- The focus on customers with average salaries exceeding R20,000 may exclude valuable clients who earn slightly less but demonstrate high engagement.
- Potential data biases may exist due to incomplete transaction histories for some clients, which could affect their RFM scores.

## Conclusion

This project successfully segments NedCap Bank’s former student clients into meaningful categories using RFM analysis, providing a strategic approach to targeted marketing. The insights generated enable NedCap Bank to tailor its offerings to different client needs, fostering long-term relationships and maximizing customer lifetime value. Future efforts could expand this analysis to include additional client behaviors and further refine the segmentation strategy.
