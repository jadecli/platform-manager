-- Plugin ecosystem dimensional model (extends schema_kimball.sql)
-- Tracks 660+ Claude plugins across 4 Anthropic marketplaces.

-- ════════════════════════════════════════════════════════════════
-- DIMENSION: dim_marketplace
-- ════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS dim_marketplace (
    marketplace_id   TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    name             TEXT NOT NULL UNIQUE,  -- 'community', 'official', 'knowledge-work', 'skills'
    repo             TEXT NOT NULL,         -- 'anthropics/claude-plugins-community'
    owner            TEXT,                  -- 'Anthropic'
    plugin_count     INT,
    last_crawled_at  TIMESTAMPTZ
);

-- ════════════════════════════════════════════════════════════════
-- DIMENSION: dim_plugin (SCD Type 2 — tracks version changes via SHA)
-- ════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS dim_plugin (
    plugin_key       BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    plugin_id        TEXT NOT NULL,         -- natural key: marketplace_name/plugin_name
    marketplace_id   TEXT REFERENCES dim_marketplace(marketplace_id),
    name             TEXT NOT NULL,
    description      TEXT,
    source_type      TEXT,                  -- 'url', 'git-subdir', 'string'
    source_url       TEXT,                  -- GitHub org/repo or full URL
    source_path      TEXT,                  -- subdir path (if git-subdir)
    source_ref       TEXT,                  -- branch ref
    source_sha       TEXT,                  -- pinned commit SHA
    homepage         TEXT,
    -- SCD Type 2 fields
    effective_from   TIMESTAMPTZ NOT NULL DEFAULT now(),
    effective_to     TIMESTAMPTZ,           -- NULL = current version
    is_current       BOOLEAN NOT NULL DEFAULT true,
    UNIQUE (plugin_id, source_sha)
);

CREATE INDEX IF NOT EXISTS idx_dim_plugin_current ON dim_plugin (plugin_id) WHERE is_current;
CREATE INDEX IF NOT EXISTS idx_dim_plugin_marketplace ON dim_plugin (marketplace_id) WHERE is_current;

-- ════════════════════════════════════════════════════════════════
-- DIMENSION: dim_plugin_metadata (extracted from source repo)
-- ════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS dim_plugin_metadata (
    plugin_key       BIGINT REFERENCES dim_plugin(plugin_key),
    -- From plugin.json manifest
    has_skills       BOOLEAN DEFAULT false,
    has_hooks        BOOLEAN DEFAULT false,
    has_commands      BOOLEAN DEFAULT false,
    has_agents       BOOLEAN DEFAULT false,
    has_mcp_servers  BOOLEAN DEFAULT false,
    -- From source repo
    readme_excerpt   TEXT,                  -- first 500 chars of README
    license          TEXT,
    language         TEXT,                  -- primary language
    dependencies     JSONB,                 -- {npm: [...], pip: [...]}
    tool_count       INT DEFAULT 0,
    skill_count      INT DEFAULT 0,
    -- Categorization (inferred from description + manifest)
    categories       TEXT[],                -- ['agent', 'mcp', 'security', ...]
    PRIMARY KEY (plugin_key)
);

-- ════════════════════════════════════════════════════════════════
-- FACT: fact_plugin_crawl (one row per plugin per crawl run)
-- ════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS fact_plugin_crawl (
    crawl_id         TEXT NOT NULL,         -- FK to dim_crawl_run
    plugin_key       BIGINT REFERENCES dim_plugin(plugin_key),
    crawled_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
    sha_changed      BOOLEAN NOT NULL,      -- did the SHA change since last crawl?
    clone_duration_ms INT,
    manifest_valid   BOOLEAN,
    error            TEXT,
    PRIMARY KEY (crawl_id, plugin_key)
);

-- ════════════════════════════════════════════════════════════════
-- VIEWS
-- ════════════════════════════════════════════════════════════════

-- Current plugin catalog with metadata
CREATE OR REPLACE VIEW v_plugin_catalog AS
SELECT
    p.plugin_id,
    p.name,
    p.description,
    m.name AS marketplace,
    p.source_type,
    p.source_url,
    p.source_sha,
    p.homepage,
    pm.categories,
    pm.tool_count,
    pm.skill_count,
    pm.has_mcp_servers,
    pm.language,
    pm.license
FROM dim_plugin p
JOIN dim_marketplace m ON m.marketplace_id = p.marketplace_id
LEFT JOIN dim_plugin_metadata pm ON pm.plugin_key = p.plugin_key
WHERE p.is_current;

-- Plugin change velocity (how often each plugin updates)
CREATE OR REPLACE VIEW v_plugin_velocity AS
SELECT
    plugin_id,
    name,
    COUNT(*) AS version_count,
    MIN(effective_from) AS first_seen,
    MAX(effective_from) AS last_updated,
    MAX(effective_from) - MIN(effective_from) AS active_period
FROM dim_plugin
GROUP BY plugin_id, name
HAVING COUNT(*) > 1
ORDER BY version_count DESC;
