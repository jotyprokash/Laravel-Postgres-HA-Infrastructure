#!/bin/bash
# 02_postgres_standby.sh
# Run this on VM-3 (Standby)
set -euo pipefail

echo "Provisioning PostgreSQL Standby prerequisites..."

# 1. Install PostgreSQL 16 & Repmgr
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y wget gnupg2 lsb-release ca-certificates
echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -
apt-get update -y
apt-get install -y postgresql-16 postgresql-16-repmgr

# 2. Kernel Tuning
cat <<EOF > /etc/sysctl.d/99-postgres.conf
net.core.somaxconn = 65535
fs.file-max = 2097152
net.ipv4.tcp_tw_reuse = 1
EOF
sysctl -p /etc/sysctl.d/99-postgres.conf

# 3. Store replication credentials for repmgr standby clone
cat > /var/lib/postgresql/.pgpass <<'EOF'
163.61.156.98:5432:repmgr:repmgr:repmgr_pass
163.61.156.112:5432:repmgr:repmgr:repmgr_pass
163.61.156.56:5432:repmgr:repmgr:repmgr_pass
EOF
chown postgres:postgres /var/lib/postgresql/.pgpass
chmod 0600 /var/lib/postgresql/.pgpass

# 4. Stop running postgres; 03_repmgr_setup.sh performs the controlled clone/register
systemctl stop postgresql

echo "Standby prerequisites complete. Run 03_repmgr_setup.sh standby to clone and register."
