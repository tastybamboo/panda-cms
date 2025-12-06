#!/usr/bin/env bash
set -euo pipefail

echo "Stopping PostgreSQL..."
su postgres -c "/usr/lib/postgresql/17/bin/pg_ctl -D /var/lib/postgresql/17/main stop"
