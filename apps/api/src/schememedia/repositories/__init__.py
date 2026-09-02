"""Repositories: SQL data access, one module per aggregate.

Routers validate and delegate; business logic lives in services; SQL lives
here. Nothing skips a layer -- see the layering rule in the project README.
"""

from __future__ import annotations
