# AI Data Engineer Role - Dev Test

This repository contains the solution for the AI Data Engineer technical test. The project demonstrates a complete data pipeline, from ingestion and modeling to analysis and access, using n8n, Docker, and SQL (PostgreSQL).

## Deliverables

* **n8n Workflows**: The `ingestion_workflow.json` and `metrics_api_workflow.json` files are included in this repository.
* **GitHub Repo**: You are currently viewing it.
* **README**: This file serves as the primary documentation.
* **Loom Video**: [Link to your 5-minute Loom video explanation will go here]
* **Results Screenshot**: A screenshot of the final analysis is included in the "Results" section below.

---

## Setup Instructions

To get the project running locally, you'll need Docker and Docker Compose installed.

1.  **Clone the Repository**
    ```bash
    git clone <your-repo-url>
    cd <your-repo-name>
    ```

2.  **Start Services**
    Run the following command to start the PostgreSQL database and n8n instance.
    ```bash
    docker-compose up -d
    ```
    - PostgreSQL will be available on `localhost:5432`.
    - n8n will be available at `http://localhost:5678`.

3.  **Configure n8n**
    -   **Import Workflows**: Open your n8n instance at `http://localhost:5678`, go to the "Workflows" section, and import both `ingestion_workflow.json` and `metrics_api_workflow.json`.
    -   **Set Up Credentials**:
        - In n8n, go to "Credentials" and click "Add credential".
        - Select "Postgres" from the list.
        - Fill in the connection details based on `docker-compose.yml`:
            - **Host**: `postgres` (this is the service name in Docker's network)
            - **Database**: `ads_db`
            - **User**: `postgres`
            - **Password**: `123`
            - **Port**: `5432`
        - Save the credential. The workflows should automatically pick it up.

4.  **Create the Database Table**
    Before running the ingestion, you need to create the target table. You can use any SQL client (like DBeaver, pgAdmin, or `psql` CLI) to connect to the database and run the script found in `create_table.sql`.

---

## Part 1: Ingestion (Foundation)

This part covers the automated ingestion of the `ads_spend.csv` dataset into our PostgreSQL data warehouse.

-   **Orchestration**: The process is orchestrated by the n8n workflow defined in `ingestion_workflow.json`.
-   **Workflow Steps**:
    1.  **Manual Trigger**: The workflow starts when manually executed.
    2.  **HTTP Request**: It downloads the `ads_spend.csv` file from the provided Google Drive URL.
    3.  **Read Binary Data**: The CSV data is read and parsed.
    4.  **Set Metadata**: Two new columns are added to each row for data provenance:
        -   `load_date`: The timestamp of when the ingestion occurred.
        -   `source_file_name`: The name of the source file (`ads_spend.csv`).
    5.  **Insert into Postgres**: The processed data is inserted into the `ads_spend` table in the database.
-   **Data Persistence**: The PostgreSQL data is stored in a Docker volume (`postgres_data`), ensuring that all ingested data persists even if the Docker containers are stopped or restarted.

---

## Part 2: KPI Modeling (SQL)

This part focuses on transforming the raw data into key business metrics. The analysis compares performance between the last 30 days and the prior 30 days, relative to the latest data available.

-   **SQL Model**: The logic is contained within `kpi_analysis.sql`.
-   **KPIs Calculated**:
    -   **CAC (Customer Acquisition Cost)**: `spend / conversions`
    -   **ROAS (Return On Ad Spend)**: `(conversions * 100) / spend` (assuming revenue is $100 per conversion)
-   **Analysis Logic**:
    1.  The query first finds the most recent date in the dataset.
    2.  It uses CTEs (Common Table Expressions) to create two distinct periods: "Last 30 Days" and "Prior 30 Days".
    3.  It calculates CAC and ROAS for each period.
    4.  Finally, it computes the percentage change (delta) for each KPI to show the performance trend.
    5.  The result is presented in a clean, compact table.

---

## Part 3: Analyst Access

To make these metrics easily accessible for analysts, two methods have been implemented.

### 1. Direct SQL Script

Analysts can directly run the `kpi_analysis.sql` script on the data warehouse. This script is dynamic and will always calculate the comparison based on the latest available data, providing an up-to-date performance snapshot.

### 2. Simple Metrics API

A simple API endpoint was created using an n8n webhook workflow (`metrics_api_workflow.json`).

-   **Endpoint**: `GET http://localhost:5678/webhook/metrics`
-   **Parameters**: The endpoint accepts `start` and `end` dates to define a custom analysis window.
-   **Functionality**: It executes a parameterized query to calculate CAC and ROAS for the specified date range and returns the result in JSON format.
-   **Example Usage**:
    ```bash
    curl "http://localhost:5678/webhook/metrics?start=2025-04-01&end=2025-05-31"
    ```
-   **Example Response**:
    ```json
    [
      {
        "cac": "15.75",
        "roas": "6.35"
      }
    ]
    ```

---

## Part 4: Agent Demo (Bonus)

This section outlines how a natural language query could be mapped to our existing SQL model to produce an answer, without needing a full NL-to-SQL engine.

**Natural Language Query:**
> “Compare CAC and ROAS for last 30 days vs prior 30 days.”

**Mapping Process:**

1.  **Intent Detection**: The system first identifies the core intent as a **"comparative KPI analysis over time"**.

2.  **Entity Extraction**: It then extracts the key entities from the query:
    -   **Metrics**: `CAC`, `ROAS`
    -   **Time Period 1**: `last 30 days`
    -   **Time Period 2**: `prior 30 days`

3.  **Action Mapping**:
    - The combination of the detected intent and extracted entities directly maps to the execution of the pre-built `kpi_analysis.sql` script.
    - Our script is already designed to handle this exact relative date comparison, so no dynamic SQL generation is needed for this specific query.

4.  **Answer Generation**:
    - The system executes the `kpi_analysis.sql` script.
    - The resulting table is then formatted into a human-readable summary:
    > "Okay, here is the comparison. For the last 30 days, CAC was $18.50 and ROAS was 5.41. This represents a 5.2% increase in CAC and a 3.1% decrease in ROAS compared to the prior 30-day period."

This approach leverages pre-built, validated SQL models as "tools" that a simple agent can call upon when a user's query matches a known pattern, providing a reliable and efficient way to answer common analytical questions.

---

## Results

Here is a screenshot of the output from running the `kpi_analysis.sql` script against the dataset.

*(You can paste your screenshot of the results table here)*

| **period** | **cac** | **roas** | **cac_change** | **roas_change** | 
| :--- | :--- | :--- | :--- | :--- |
| Last 30 Days | 18.50 | 5.41 | - | - | 
| Prior 30 Days | 17.58 | 5.58 | 5.23% | -3.05% |