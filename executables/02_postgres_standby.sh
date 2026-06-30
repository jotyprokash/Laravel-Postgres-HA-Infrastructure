#!/bin/bash
# 02_postgres_standby.sh
# Run this on VM-3 (Standby)
set -e

echo "Provisioning PostgreSQL Standby..."

# 1. Install PostgreSQL 16 & Repmgr
apt-get install -y wget gnupg2
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

# 3. Stop running postgres to prepare for cloning
systemctl stop postgresql

# 4. Clone from Primary
# Assuming VM-2 IP is 163.61.156.98
sudo -u postgres rm -rf /var/lib/postgresql/16/main/*
sudo -u postgres PGPASSWORD=repmgr_pass pg_basebackup -h 163.61.156.98 -D /var/lib/postgresql/16/main -U repmgr -vP -W

systemctl start postgresql

echo "Standby Database Provisioned and Cloning Complete."
