CREATE TABLE IF NOT EXISTS ads_spend (
    date DATE,
    platform VARCHAR(50),
    account VARCHAR(50),
    campaign VARCHAR(100),
    country VARCHAR(50),
    device VARCHAR(50),
    spend NUMERIC,
    clicks INTEGER,
    impressions INTEGER,
    conversions INTEGER,
    load_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    source_file_name VARCHAR(100)
);