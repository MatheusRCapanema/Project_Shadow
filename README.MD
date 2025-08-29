# Marketing KPI Analysis Project

This repository contains a data pipeline and an API for analyzing marketing metrics (CAC and ROAS), built with n8n, PostgreSQL, and Docker.

## 🚀 Setup and Instructions

1.  **Prerequisites:** Ensure you have Docker and Docker Compose installed.
2.  **Clone the Repository:** `git clone <REPO_URL>`
3.  **Start the Services:** In the project's root directory, run the following command:
    ```bash
    docker-compose up -d
    ```
    This will start the PostgreSQL and n8n containers.
4.  **Access n8n:** Open your browser and go to `http://localhost:5678`. Create your admin account.
5.  **Configure the Database Connection:**
    * Navigate to the "Credentials" section and add a new credential for "Postgres".
    * Use the following settings:
        * **Host:** `postgres` (the service name in docker-compose)
        * **Database:** `ads_db`
        * **User:** `postgres`
        * **Password:** `123`
        * **Port:** `5432`
6.  **Import the Workflows:**
    * Go to the "Workflows" section and import the `ingestion_workflow.json` and `metrics_api_workflow.json` files.
    * Assign the Postgres credential created in the previous step to the Postgres nodes in both workflows.
7.  **Run the Ingestion:**
    * Open the ingestion workflow and execute it manually. This will download the CSV, create the `ads_spend` table (if it doesn't exist), and populate it with data.

---

## Part 4 – Agent Demo (Bonus)

This section demonstrates how a natural language question can be mapped to an SQL query to produce an analytical answer. This is a foundational concept for building BI (Business Intelligence) agents and analytical chat systems.

### Natural Language Question:

> “Compare CAC and ROAS for the last 30 days vs the prior 30 days.”

### Mapping to an Action

An AI agent or a simple mapping system would process this question in three steps:

1.  **Intent Recognition:** The system identifies that the user's primary intent is to **compare performance** across two time periods. Keywords like "compare" and "vs" trigger this intent.

2.  **Entity Extraction:** The system extracts the specific "entities" or parameters from the question:
    * **Metrics:** `CAC` (Customer Acquisition Cost), `ROAS` (Return on Ad Spend).
    * **Period 1:** `last 30 days`.
    * **Period 2:** `prior 30 days`.

3.  **Action Mapping:** With the "compare performance" intent and the extracted entities, the system maps this request to the execution of a pre-defined SQL query designed specifically for this analysis. The query used is `kpi_analysis.sql`.

### Mapped SQL Query (`kpi_analysis.sql`)

The user's question is translated directly into the following SQL query, which calculates the metrics for both periods and the percentage change between them.

```sql
WITH max_date_cte AS (
    SELECT MAX(date) AS max_date FROM ads_spend
),

last_30 AS (
    SELECT 
        SUM(spend) AS spend_last,
        SUM(conversions) AS conv_last
    FROM ads_spend, max_date_cte
    WHERE date BETWEEN max_date - INTERVAL '29 days' AND max_date
),

prior_30 AS (
    SELECT 
        SUM(spend) AS spend_prior,
        SUM(conversions) AS conv_prior
    FROM ads_spend, max_date_cte
    WHERE date BETWEEN max_date - INTERVAL '59 days' AND max_date - INTERVAL '30 days'
)

SELECT 
    'Last 30 Days' AS period,
    ROUND(l.spend_last / NULLIF(l.conv_last, 0), 2) AS cac,
    ROUND((l.conv_last * 100) / NULLIF(l.spend_last, 0), 2) AS roas,
    ROUND(100 * ((l.spend_last / NULLIF(l.conv_last, 0) - p.spend_prior / NULLIF(p.conv_prior, 0)) / NULLIF(p.spend_prior / NULLIF(p.conv_prior, 0), 0)), 2) || '%' AS cac_change,
    ROUND(100 * (((l.conv_last * 100) / NULLIF(l.spend_last, 0) - (p.conv_prior * 100) / NULLIF(p.spend_prior, 0)) / NULLIF((p.conv_prior * 100) / NULLIF(p.spend_prior, 0), 0)), 2) || '%' AS roas_change
FROM last_30 l, prior_30 p
UNION ALL
SELECT 
    'Prior 30 Days' AS period,
    ROUND(p.spend_prior / NULLIF(p.conv_prior, 0), 2) AS cac,
    ROUND((p.conv_prior * 100) / NULLIF(p.spend_prior, 0), 2) AS roas,
    '-' AS cac_change,
    '-' AS roas_change
FROM prior_30 p;