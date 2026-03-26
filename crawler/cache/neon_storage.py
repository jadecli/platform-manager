"""Neon Postgres cache storage backend for Scrapy's HttpCacheMiddleware.

Replaces FilesystemCacheStorage. Stores raw response bodies + headers in Neon
so cached pages persist across machines and sessions. Uses RFC2616Policy for
proper ETag/Last-Modified/304 handling — Scrapy natively skips unchanged pages.

Enable in settings:
  HTTPCACHE_ENABLED = True
  HTTPCACHE_POLICY = "scrapy.extensions.httpcache.RFC2616Policy"
  HTTPCACHE_STORAGE = "crawler.cache.neon_storage.NeonCacheStorage"
  HTTPCACHE_EXPIRATION_SECS = 86400  # 24h — refetch daily
  DATABASE_URL = "postgresql://..."

Schema (auto-created on first use):
  CREATE TABLE IF NOT EXISTS http_cache (
      fingerprint TEXT PRIMARY KEY,
      url         TEXT NOT NULL,
      method      TEXT DEFAULT 'GET',
      status      INTEGER,
      headers     BYTEA,
      body        BYTEA,
      time        TIMESTAMPTZ DEFAULT NOW()
  );
"""

from __future__ import annotations

import logging
import os
import pickle
from time import time
from typing import TYPE_CHECKING

import psycopg2
from scrapy.http import Headers, Response
from scrapy.responsetypes import responsetypes

if TYPE_CHECKING:
    from scrapy.http.request import Request
    from scrapy.settings import BaseSettings
    from scrapy.spiders import Spider

logger = logging.getLogger(__name__)

SCHEMA = """
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
"""


class NeonCacheStorage:
    """Scrapy CacheStorage backed by Neon Postgres."""

    def __init__(self, settings: BaseSettings):
        self.db_url = settings.get("DATABASE_URL") or os.environ.get("DATABASE_URL", "")
        self.expiration_secs = settings.getint("HTTPCACHE_EXPIRATION_SECS", 86400)

    def open_spider(self, spider: Spider) -> None:
        self.conn = psycopg2.connect(self.db_url)
        self.conn.autocommit = True
        with self.conn.cursor() as cur:
            cur.execute(SCHEMA)
        logger.info("NeonCacheStorage opened for %s", spider.name)

    def close_spider(self, spider: Spider) -> None:
        self.conn.close()

    def retrieve_response(self, spider: Spider, request: Request) -> Response | None:
        fp = self._fingerprint(request)
        with self.conn.cursor() as cur:
            cur.execute(
                "SELECT url, status, headers, body, time FROM http_cache WHERE fingerprint = %s",
                (fp,),
            )
            row = cur.fetchone()

        if row is None:
            return None

        url, status, headers_bytes, body, cached_time = row

        # Check expiration
        if self.expiration_secs > 0:
            age = time() - cached_time.timestamp()
            if age > self.expiration_secs:
                logger.debug("Cache expired for %s (%.0fs old)", url, age)
                return None

        headers = Headers(pickle.loads(bytes(headers_bytes)))
        body = bytes(body) if body else b""
        respcls = responsetypes.from_args(headers=headers, url=url)
        return respcls(url=url, headers=headers, status=status, body=body)

    def store_response(
        self, spider: Spider, request: Request, response: Response
    ) -> None:
        fp = self._fingerprint(request)
        headers_bytes = pickle.dumps(dict(response.headers))

        with self.conn.cursor() as cur:
            cur.execute(
                """INSERT INTO http_cache (fingerprint, url, method, status, headers, body)
                   VALUES (%s, %s, %s, %s, %s, %s)
                   ON CONFLICT (fingerprint) DO UPDATE SET
                     status = EXCLUDED.status,
                     headers = EXCLUDED.headers,
                     body = EXCLUDED.body,
                     time = NOW()""",
                (fp, response.url, request.method, response.status,
                 psycopg2.Binary(headers_bytes), psycopg2.Binary(response.body)),
            )

    def _fingerprint(self, request: Request) -> str:
        from scrapy.utils.request import fingerprint
        return fingerprint(request).hex()
