#!/bin/bash
# 01_postgres_primary.sh
# Run this on VM-2 (Primary)
set -e

echo "Provisioning PostgreSQL Primary..."

# 1. Install PostgreSQL 16 & Repmgr
apt-get install -y wget gnupg2
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
sudo -u postgres psql -c "CREATE USER repmgr WITH SUPERUSER REPLICATION LOGIN ENCRYPTED PASSWORD 'repmgr_pass';"
sudo -u postgres psql -c "CREATE USER laravel_db WITH LOGIN ENCRYPTED PASSWORD 'laravel_pass';"
sudo -u postgres psql -c "CREATE DATABASE laravel_app OWNER laravel_db;"

# 4. Inject Optimized postgresql.conf parameters for 100K/s
cat <<EOF >> /etc/postgresql/16/main/postgresql.conf
listen_addresses = '*'
max_connections = 500
shared_buffers = 4GB
wal_level = replica
wal_buffers = 16MB
max_wal_size = 4GB
checkpoint_timeout = 15min
synchronous_commit = off
commit_delay = 1000
commit_siblings = 5
shared_preload_libraries = 'repmgr'
EOF

# 5. Allow Network Access in pg_hba.conf
cat <<EOF >> /etc/postgresql/16/main/pg_hba.conf
host    all             all             163.61.156.0/24         md5
host    replication     repmgr          163.61.156.0/24         md5
EOF

systemctl restart postgresql

echo "Primary Database Provisioned."
