#!/bin/bash
# 03_repmgr_setup.sh
# Run steps in order across the three nodes as indicated.
set -euo pipefail

NODE_ROLE="${1:-}"  # primary | standby | witness
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PRIMARY_IP="163.61.156.98"

install_postgres_packages() {
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -y
    apt-get install -y wget gnupg2 lsb-release ca-certificates
    echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list
    wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -
    apt-get update -y
    apt-get install -y postgresql-16 postgresql-16-repmgr
}

install_repmgr_conf() {
    local source_file="$1"
    install -o postgres -g postgres -m 0640 "$source_file" /etc/repmgr.conf
}

install_pgpass() {
    cat > /var/lib/postgresql/.pgpass <<'EOF'
163.61.156.98:5432:repmgr:repmgr:repmgr_pass
163.61.156.112:5432:repmgr:repmgr:repmgr_pass
163.61.156.56:5432:repmgr:repmgr:repmgr_pass
EOF
    chown postgres:postgres /var/lib/postgresql/.pgpass
    chmod 0600 /var/lib/postgresql/.pgpass
}

start_repmgrd() {
    if [ -f /etc/default/repmgrd ]; then
        sed -i 's/^REPMGRD_ENABLED=.*/REPMGRD_ENABLED=yes/' /etc/default/repmgrd
    fi
    systemctl enable repmgrd
    systemctl restart repmgrd
}

case "$NODE_ROLE" in
  primary)
    echo "Registering primary node..."
    install_repmgr_conf "$REPO_ROOT/config/repmgr/repmgr_primary.conf"
    install_pgpass
    sudo -u postgres createdb repmgr -O repmgr 2>/dev/null || true
    sudo -u postgres repmgr -f /etc/repmgr.conf primary register --force
    start_repmgrd
    sudo -u postgres repmgr -f /etc/repmgr.conf cluster show
    ;;

  standby)
    echo "Cloning and registering standby..."
    install_repmgr_conf "$REPO_ROOT/config/repmgr/repmgr_standby.conf"
    install_pgpass
    install -o root -g root -m 0755 "$REPO_ROOT/executables/failover_pgbouncer.sh" /usr/local/bin/failover_pgbouncer.sh
    systemctl stop postgresql || true
    sudo -u postgres rm -rf /var/lib/postgresql/16/main
    sudo -u postgres repmgr -h "$PRIMARY_IP" -U repmgr -d repmgr \
      -f /etc/repmgr.conf standby clone --fast-checkpoint --force
    systemctl start postgresql
    sudo -u postgres repmgr -f /etc/repmgr.conf standby register --force
    systemctl enable postgresql
    start_repmgrd
    sudo -u postgres repmgr -f /etc/repmgr.conf cluster show
    ;;

  witness)
    echo "Registering witness node..."
    # Witness needs a local PostgreSQL instance (metadata only)
    install_postgres_packages
    install_repmgr_conf "$REPO_ROOT/config/repmgr/repmgr_witness.conf"
    install_pgpass
    systemctl start postgresql
    systemctl enable postgresql
    sudo -u postgres createuser -s repmgr 2>/dev/null || true
    sudo -u postgres createdb repmgr -O repmgr 2>/dev/null || true
    sudo -u postgres repmgr -h "$PRIMARY_IP" -U repmgr -d repmgr \
      -f /etc/repmgr.conf witness register --force
    start_repmgrd
    sudo -u postgres repmgr -f /etc/repmgr.conf cluster show
    ;;

  *)
    echo "Usage: $0 {primary|standby|witness}"
    exit 1
    ;;
esac

echo "Repmgr $NODE_ROLE setup complete."
