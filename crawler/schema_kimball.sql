-- Kimball dimensional model for platform-manager crawl data warehouse.
-- Neon project: sweet-lake-21496014
--
-- Star schema: fact_crawl_events at center, surrounded by dimensions.
-- SCD Type 2 on dim_page for tracking content changes over time.

-- ╔══════════════════════════════════════╗
-- ║  DIMENSIONS                         ║
-- ╚══════════════════════════════════════╝

-- dim_source: conformed dimension for crawl sources
CREATE TABLE IF NOT EXISTS dim_source (
    source_key      SERIAL PRIMARY KEY,
    source_id       TEXT NOT NULL UNIQUE,     -- 'claude_docs', 'neon_docs', etc.
    source_name     TEXT NOT NULL,
    index_url       TEXT,
    base_url        TEXT,
    page_count      INTEGER DEFAULT 0,
    rate_strategy   TEXT,                     -- 'polite', 'standard', 'aggressive'
    plugin_name     TEXT,                     -- installed plugin, if any
    github_org      TEXT,
    github_repo     TEXT,
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    updated_at      TIMESTAMPTZ DEFAULT NOW()
);

-- dim_page: SCD Type 2 — new row when content changes
CREATE TABLE IF NOT EXISTS dim_page (
    page_key        BIGSERIAL PRIMARY KEY,
    url             TEXT NOT NULL,
    source_key      INTEGER REFERENCES dim_source(source_key),
    title           TEXT,
    section         TEXT,
    content_hash    TEXT NOT NULL,
    content_length  INTEGER DEFAULT 0,
    -- SCD Type 2 fields
    effective_from  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    effective_to    TIMESTAMPTZ DEFAULT '9999-12-31'::TIMESTAMPTZ,
    is_current      BOOLEAN DEFAULT TRUE,
    version         INTEGER DEFAULT 1
);

CREATE INDEX IF NOT EXISTS idx_dim_page_url ON dim_page(url) WHERE is_current = TRUE;
CREATE INDEX IF NOT EXISTS idx_dim_page_source ON dim_page(source_key) WHERE is_current = TRUE;

-- dim_date: date dimension (pre-populated or generated)
CREATE TABLE IF NOT EXISTS dim_date (
    date_key        INTEGER PRIMARY KEY,      -- YYYYMMDD format
    full_date       DATE NOT NULL UNIQUE,
    year            SMALLINT,
    month           SMALLINT,
    day             SMALLINT,
    day_of_week     SMALLINT,                 -- 0=Mon, 6=Sun
    week_of_year    SMALLINT,
    is_weekend      BOOLEAN
);

-- Populate dim_date for 2026
INSERT INTO dim_date (date_key, full_date, year, month, day, day_of_week, week_of_year, is_weekend)
SELECT
    TO_CHAR(d, 'YYYYMMDD')::INTEGER,
    d,
    EXTRACT(YEAR FROM d)::SMALLINT,
    EXTRACT(MONTH FROM d)::SMALLINT,
    EXTRACT(DAY FROM d)::SMALLINT,
    EXTRACT(ISODOW FROM d)::SMALLINT - 1,
    EXTRACT(WEEK FROM d)::SMALLINT,
    EXTRACT(ISODOW FROM d) IN (6, 7)
FROM generate_series('2026-01-01'::DATE, '2026-12-31'::DATE, '1 day') AS d
ON CONFLICT (date_key) DO NOTHING;

-- dim_crawl_run: degenerate dimension for crawl execution metadata
CREATE TABLE IF NOT EXISTS dim_crawl_run (
    run_key         BIGSERIAL PRIMARY KEY,
    spider          TEXT NOT NULL,
    started_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    finished_at     TIMESTAMPTZ,
    reason          TEXT,
    is_test         BOOLEAN DEFAULT FALSE,
    items_scraped   INTEGER DEFAULT 0,
    requests_sent   INTEGER DEFAULT 0,
    cache_hits      INTEGER DEFAULT 0,
    cache_misses    INTEGER DEFAULT 0,
    elapsed_seconds REAL DEFAULT 0
);

-- ╔══════════════════════════════════════╗
-- ║  FACT TABLES                        ║
-- ╚══════════════════════════════════════╝

-- fact_crawl_events: grain = one page visit per crawl run
CREATE TABLE IF NOT EXISTS fact_crawl_events (
    event_id        BIGSERIAL PRIMARY KEY,
    -- Dimension keys
    date_key        INTEGER REFERENCES dim_date(date_key),
    source_key      INTEGER REFERENCES dim_source(source_key),
    page_key        BIGINT REFERENCES dim_page(page_key),
    run_key         BIGINT REFERENCES dim_crawl_run(run_key),
    -- Measures
    content_length  INTEGER DEFAULT 0,
    response_time_ms INTEGER DEFAULT 0,
    http_status     SMALLINT,
    changed         BOOLEAN DEFAULT FALSE,
    from_cache      BOOLEAN DEFAULT FALSE,
    crawled_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_fact_date ON fact_crawl_events(date_key);
CREATE INDEX IF NOT EXISTS idx_fact_source ON fact_crawl_events(source_key);
CREATE INDEX IF NOT EXISTS idx_fact_changed ON fact_crawl_events(changed) WHERE changed = TRUE;

-- fact_claude_usage: grain = one Claude API call per operation
CREATE TABLE IF NOT EXISTS fact_claude_usage (
    usage_id        BIGSERIAL PRIMARY KEY,
    date_key        INTEGER REFERENCES dim_date(date_key),
    source_key      INTEGER REFERENCES dim_source(source_key),
    run_key         BIGINT REFERENCES dim_crawl_run(run_key),
    -- Measures
    operation       TEXT NOT NULL,
    model           TEXT,
    input_tokens    INTEGER DEFAULT 0,
    output_tokens   INTEGER DEFAULT 0,
    total_tokens    INTEGER DEFAULT 0,
    tool_calls      INTEGER DEFAULT 0,
    duration_ms     INTEGER DEFAULT 0,
    cost_usd        REAL DEFAULT 0,
    surface         TEXT,
    recorded_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ╔══════════════════════════════════════╗
-- ║  HTTP CACHE (for NeonCacheStorage)  ║
-- ╚══════════════════════════════════════╝

CREATE TABLE IF NOT EXISTS http_cache (
    fingerprint TEXT PRIMARY KEY,
    url         TEXT NOT NULL,
    method      TEXT DEFAULT 'GET',
    status      INTEGER,
    headers     BYTEA,
    body        BYTEA,
    time        TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_http_cache_url ON http_cache(url);

-- ╔══════════════════════════════════════╗
-- ║  SEED DATA                          ║
-- ╚══════════════════════════════════════╝

INSERT INTO dim_source (source_id, source_name, index_url, base_url, page_count, rate_strategy, plugin_name, github_org)
VALUES
    ('claude_docs', 'Claude Code Documentation', 'https://code.claude.com/docs/llms.txt', 'https://code.claude.com/docs/en/', 84, 'polite', NULL, 'anthropics'),
    ('neon_docs', 'Neon Postgres Documentation', 'https://neon.com/llms.txt', 'https://neon.com/docs/', 244, 'standard', 'neon-postgres', 'neondatabase'),
    ('platform_docs', 'Anthropic Platform Documentation', 'https://platform.claude.com/llms.txt', 'https://platform.claude.com/docs/en/', 607, 'standard', NULL, 'anthropics'),
    ('netlify_docs', 'Netlify Documentation', 'https://docs.netlify.com/llms.txt', 'https://docs.netlify.com/', 78, 'polite', 'netlify-skills', 'netlify')
ON CONFLICT (source_id) DO UPDATE SET
    page_count = EXCLUDED.page_count,
    updated_at = NOW();
