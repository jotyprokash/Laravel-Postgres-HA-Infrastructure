#!/bin/bash
# 01_postgres_primary.sh
# Run this on VM-2 (Primary)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PG_CONF_DIR="/etc/postgresql/16/main"

echo "Provisioning PostgreSQL Primary..."

# 1. Install PostgreSQL 16 & Repmgr
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y wget gnupg2 lsb-release ca-certificates
echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -
apt-get update -y
apt-get install -y postgresql-16 postgresql-16-repmgr

# 2. Kernel Tuning for High Write Throughput
cat <<EOF > /etc/sysctl.d/99-postgres.conf
net.core.somaxconn = 65535
fs.file-max = 2097152
net.ipv4.tcp_tw_reuse = 1
EOF
sysctl -p /etc/sysctl.d/99-postgres.conf

# 3. Setup Users
sudo -u postgres psql <<'SQL'
DO $$
BEGIN
   IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'repmgr') THEN
      CREATE ROLE repmgr WITH SUPERUSER REPLICATION LOGIN ENCRYPTED PASSWORD 'repmgr_pass';
   ELSE
      ALTER ROLE repmgr WITH SUPERUSER REPLICATION LOGIN ENCRYPTED PASSWORD 'repmgr_pass';
   END IF;

   IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'laravel_db') THEN
      CREATE ROLE laravel_db WITH LOGIN ENCRYPTED PASSWORD 'laravel_pass';
   ELSE
      ALTER ROLE laravel_db WITH LOGIN ENCRYPTED PASSWORD 'laravel_pass';
   END IF;
END
$$;
SQL

if ! sudo -u postgres psql -tAc "SELECT 1 FROM pg_database WHERE datname = 'laravel_app'" | grep -q 1; then
    sudo -u postgres createdb -O laravel_db laravel_app
fi

if ! sudo -u postgres psql -tAc "SELECT 1 FROM pg_database WHERE datname = 'repmgr'" | grep -q 1; then
    sudo -u postgres createdb -O repmgr repmgr
fi

# 4. Inject optimized PostgreSQL parameters idempotently
sed -i '/# BEGIN assessment-postgresql-tuning/,/# END assessment-postgresql-tuning/d' "$PG_CONF_DIR/postgresql.conf"
{
    echo "# BEGIN assessment-postgresql-tuning"
    grep -vE '^[[:space:]]*#|^[[:space:]]*$' "$REPO_ROOT/config/postgresql.conf"
    echo "# END assessment-postgresql-tuning"
} >> "$PG_CONF_DIR/postgresql.conf"

# 5. Allow network access in pg_hba.conf idempotently
sed -i '/# BEGIN assessment-pg-hba/,/# END assessment-pg-hba/d' "$PG_CONF_DIR/pg_hba.conf"
{
    echo "# BEGIN assessment-pg-hba"
    grep -vE '^[[:space:]]*#|^[[:space:]]*$' "$REPO_ROOT/config/pg_hba.conf"
    echo "# END assessment-pg-hba"
} >> "$PG_CONF_DIR/pg_hba.conf"

cat > /var/lib/postgresql/.pgpass <<'EOF'
163.61.156.98:5432:repmgr:repmgr:repmgr_pass
163.61.156.112:5432:repmgr:repmgr:repmgr_pass
163.61.156.56:5432:repmgr:repmgr:repmgr_pass
EOF
chown postgres:postgres /var/lib/postgresql/.pgpass
chmod 0600 /var/lib/postgresql/.pgpass

systemctl restart postgresql
systemctl enable postgresql

echo "Primary Database Provisioned."
