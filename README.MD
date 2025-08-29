# AI Data Engineer Challenge - 8 Figure Agency

## Dev Test – AI Data Engineer Role

We want to see how you approach data ingestion, modeling, and making metrics accessible. The goal is not a production system, but a clear demonstration of your thinking, SQL skills, and ability to use automation (n8n).

## Project Structure

├── workflows/
│   ├── ingestion_workflow.json
│   └── metrics_api_workflow.json
├── sql/
│   ├── create_table.sql
│   └── kpi_analysis.sql
├── docker-compose.yml
└── README.md

## Prerequisites
- Docker and Docker Compose installed.
- Git.
- n8n installed locally (optional, for workflow execution; otherwise, use exported JSON).

## Setup Instructions

1.  **Clone the Repository**
    ```bash
    git clone <repo-url>
    cd <repo-folder>
    ```
2.  **Start Services**
    ```bash
    docker-compose up -d
    ```
    This command starts the PostgreSQL and n8n services as defined in the configuration file. PostgreSQL will be available on `localhost:5432`.

3.  **Initialize the Database**
    ```bash
    docker exec -i project_shadow-postgres-1 psql -U postgres -d ads_db < sql/create_table.sql
    ```
    This command executes the `create_table.sql` script to create the `ads_spend` table in the `ads_db` database.

4.  **Run Ingestion Workflow (Part 1 – Ingestion)**
    * Import `workflows/ingestion_workflow.json` into n8n (accessible at `http://localhost:5678` if running locally).
    * The workflow downloads the `ads_spend.csv` dataset from the specified Google Drive URL.
    * Execute the workflow. It orchestrates the ingestion into the PostgreSQL `ads_spend` table.
    * **Requirements Met:**
        * The workflow uses n8n to manage the ingestion process.
        * It adds `load_date` and `source_file_name` as metadata for data provenance.

5.  **KPI Modeling (Part 2 – KPI Modeling)**
    * The project requires building queries to compute key performance indicators:
        * CAC (Customer Acquisition Cost) = $spend \ / \ conversions$
        * ROAS (Return on Ad Spend) = $(conversions \ * \ 100) \ / \ spend$
    * The analysis comparing the last 30 days versus the prior 30 days is performed by `sql/kpi_analysis.sql`. Run it with the following command:
        ```bash
        docker exec -i project_shadow-postgres-1 psql -U postgres -d ads_db -f sql/kpi_analysis.sql
        ```
    * The query's output is a compact table showing absolute values for each period and the percentage change.

6.  **Analyst Access (Part 3 – Analyst Access)**
    * To provide simple access to the metrics, import and activate the `workflows/metrics_api_workflow.json` in n8n.
    * This creates an API endpoint at `/metrics` that accepts `start` and `end` query parameters.
    * **Test the API** by navigating to a URL like this in your browser (adjust dates as needed):
        `http://localhost:5678/webhook/metrics?start=2025-04-01&end=2023-05-01`
    * **Expected Output:** A JSON object with the calculated metrics.
        ```json
        {"cac": 50.00, "roas": 2.00}
        ```

7.  **Agent Demo (Part 4 – Agent Demo, Bonus, Optional)**

    This section demonstrates how a natural-language question could be mapped to the project's existing SQL query to produce an answer.

    **Natural Language Question:**
    > "Compare CAC and ROAS for the last 30 days vs the prior 30 days."

    **Simple Mapping Approach:**
    * **Parsing:** A basic system would parse the question to identify intent and entities.
        * **Intent:** The word "Compare" signals a *comparison* intent.
        * **Entities:** "CAC", "ROAS", "last 30 days", "prior 30 days".
    * **Mapping to Query:** The combination of this intent and entities maps directly to the execution of the `sql/kpi_analysis.sql` script. The script is already designed to dynamically calculate these metrics for these specific timeframes based on the latest date in the data.
    * **Execution & Output:** Running the query produces a comparison table, directly answering the user's question.

    **How to Test the Concept:**
    The mapping itself is conceptual. However, you can manually trigger the underlying SQL query to see the result that the agent would produce:
    ```bash
    docker exec -i project_shadow-postgres-1 psql -U postgres -d ads_db -f sql/kpi_analysis.sql
    ```

## Part 4 – Agent Demo (Bonus, Optional)

Demonstra como uma pergunta em linguagem natural como:
"Compare CAC e ROAS dos últimos 30 dias versus os 30 dias anteriores."
poderia ser mapeada para sua consulta e produzir uma resposta.

### Abordagem de Mapeamento Simples

* **Análise (Parsing):** Use um padrão básico para detectar a intenção e os parâmetros.
    * **Padrão:** Procurar por "compare" + métricas ("CAC" e/ou "ROAS") + períodos de tempo ("últimos X dias vs Y dias anteriores").
    * **Exemplo de correspondência:** "compare CAC e ROAS dos últimos 30 dias vs 30 dias anteriores" → Extrair X=30, Y=30.

* **Mapeamento para Consulta:** Mapeie a entrada analisada para o script `sql/kpi_analysis.sql`, que usa dinamicamente `MAX(date)` e `INTERVAL` para lidar com os períodos de 30 dias.
    * O SQL já calcula o CAC (`spend / conversions`) e o ROAS (`(conversions * 100) / spend`), comparando os últimos 30 dias com os 30 dias anteriores.

* **Execução:** Execute a consulta no PostgreSQL para produzir a tabela.

* **Exemplo de Saída (com base em dados de amostra):**

| Period        | CAC   | ROAS | CAC Change | ROAS Change |
|---------------|-------|------|------------|-------------|
| Last 30 Days  | 50.00 | 2.00 | -          | -           |
| Prior 30 Days | 60.00 | 1.67 | -16.67%    | 19.76%      |

### Como Testar

Execute manualmente `sql/kpi_analysis.sql` no PostgreSQL para ver o resultado:

```bash
docker exec -i project_shadow-postgres-1 psql -U postgres -d ads_db -f sql/kpi_analysis.sql
 