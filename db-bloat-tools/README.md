# Database Bloat Detection

## The Problem

Database bloat is a problem because it degrades database performance and increases storage requirements and cost. Also, bloat creeps up gradually and then suddenly, reaches a tipping point where production applications are suddenly cripplied.

## Prerequisites

- PostgreSQL client tools (`psql`)
- Access to the target database
- Standard PostgreSQL connection environment variables (optional):
  | Variable   | Description        |
  |------------|--------------------|
  | `PGHOST`   | Database host      |
  | `PGPORT`   | Port (default 5432)|
  | `PGUSER`   | Username           |
  | `PGPASSWORD` | Password         |

If unset, `psql` uses local socket authentication and your OS user.

## The Tools

### DB Bloat Basic Report

./db-bloat-report.sh <dbname>

* What it reports *

Largest tables (public schema) — Top 10 tables by total relation size (table + indexes + TOAST), with human-readable and byte sizes.

Largest schemas — Total table data size per schema, as absolute size and percentage of the whole database. 

Largest indexes — All user indexes (excluding pg_* system names), ordered by on-disk size.
1. db-bloat-report
2. redundant-db-objects
