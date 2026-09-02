"""Batch data ingestion: schemes.json -> database.

Sync SQLAlchemy throughout (see pipeline.sync_database_url) -- these are
one-shot batch jobs, not request-serving code, so they don't need the app's
async engine.
"""

from __future__ import annotations
