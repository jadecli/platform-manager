-- Platform-manager crawl data schema
-- Neon project: sweet-lake-21496014 (us-east-1)
-- Database: neondb

-- Crawled pages — the core index
CREATE TABLE IF NOT EXISTS pages (
    id              BIGSERIAL PRIMARY KEY,
    url             TEXT NOT NULL,
    source          TEXT NOT NULL,  -- 'claude_docs', 'neon_docs', 'platform_docs', 'local_files'
    title           TEXT,
    content_hash    TEXT NOT NULL,
    content_length  INTEGER DEFAULT 0,
    doc_type        TEXT DEFAULT 'doc',  -- 'index', 'doc', 'local'
    section         TEXT,
    crawled_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    changed         BOOLEAN DEFAULT FALSE,
    previous_hash   TEXT,
    UNIQUE(url, source)
);

CREATE INDEX IF NOT EXISTS idx_pages_source ON pages(source);
CREATE INDEX IF NOT EXISTS idx_pages_changed ON pages(changed) WHERE changed = TRUE;
CREATE INDEX IF NOT EXISTS idx_pages_crawled ON pages(crawled_at DESC);

-- Changelog — append-only log of detected changes
CREATE TABLE IF NOT EXISTS changelog (
    id              BIGSERIAL PRIMARY KEY,
    url             TEXT NOT NULL,
    source          TEXT NOT NULL,
    title           TEXT,
    content_hash    TEXT NOT NULL,
    previous_hash   TEXT,
    content_length  INTEGER DEFAULT 0,
    detected_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_changelog_source ON changelog(source);
CREATE INDEX IF NOT EXISTS idx_changelog_detected ON changelog(detected_at DESC);

-- Crawl runs — one row per spider execution
CREATE TABLE IF NOT EXISTS crawl_runs (
    id              BIGSERIAL PRIMARY KEY,
    spider          TEXT NOT NULL,
    started_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    finished_at     TIMESTAMPTZ,
    reason          TEXT,  -- 'finished', 'closespider_itemcount', 'closespider_timeout'
    items_scraped   INTEGER DEFAULT 0,
    requests_sent   INTEGER DEFAULT 0,
    response_bytes  BIGINT DEFAULT 0,
    errors          JSONB DEFAULT '{}',
    elapsed_seconds REAL DEFAULT 0,
    is_test         BOOLEAN DEFAULT FALSE
);

-- Claude usage telemetry — tracks token spend per operation
CREATE TABLE IF NOT EXISTS claude_usage (
    id              BIGSERIAL PRIMARY KEY,
    operation       TEXT NOT NULL,  -- 'crawl', 'understand', 'create', etc.
    spider          TEXT,
    model           TEXT,
    tokens          INTEGER DEFAULT 0,
    tool_calls      INTEGER DEFAULT 0,
    duration_ms     INTEGER DEFAULT 0,
    cost_usd        REAL DEFAULT 0,
    surface         TEXT,
    email           TEXT,
    metadata        JSONB DEFAULT '{}',
    recorded_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_claude_usage_op ON claude_usage(operation);
CREATE INDEX IF NOT EXISTS idx_claude_usage_recorded ON claude_usage(recorded_at DESC);

-- llms.txt snapshots — stores the full llms.txt content for diff comparison
CREATE TABLE IF NOT EXISTS llms_snapshots (
    id              BIGSERIAL PRIMARY KEY,
    source          TEXT NOT NULL,  -- 'code.claude.com', 'neon.com', 'platform.claude.com'
    content         TEXT NOT NULL,
    content_hash    TEXT NOT NULL,
    page_count      INTEGER DEFAULT 0,
    captured_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_llms_source ON llms_snapshots(source, captured_at DESC);
