#!/usr/bin/env bash
set -euo pipefail

# Ensure correct permissions
chown -R postgres:postgres /var/lib/postgresql
mkdir -p /tmp/cuprite-profile
chmod 777 /tmp/cuprite-profile

# Set additional ENV variables
export CHROME_HEADLESS=1

# Start PostgreSQL
echo "Starting PostgreSQL..."

# Clean stale PID if present (it may remain after crashes)
rm -f /var/lib/postgresql/17/main/postmaster.pid

mkdir -p /run/postgresql
chown postgres:postgres /run/postgresql
chmod 775 /run/postgresql

su postgres -c "/usr/lib/postgresql/17/bin/pg_ctl \
  -D /var/lib/postgresql/17/main \
  -l /var/lib/postgresql/17/main/logfile \
  start"

# Poll for readiness
for i in {1..30}; do
  pg_isready -q && break
  echo "Waiting for postgres..."
  sleep 1
done

pg_isready || { echo "Postgres failed to start"; exit 1; }
echo "PostgreSQL ready."
