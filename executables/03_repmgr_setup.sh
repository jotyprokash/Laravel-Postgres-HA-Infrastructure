#!/bin/bash
# 03_repmgr_setup.sh
# Run steps in order across the three nodes as indicated.
set -e

NODE_ROLE=$1  # primary | standby | witness

case "$NODE_ROLE" in
  primary)
    echo "Registering primary node..."
    cp /tmp/repmgr_primary.conf /etc/repmgr.conf
    chown postgres:postgres /etc/repmgr.conf
    sudo -u postgres createdb repmgr -O repmgr 2>/dev/null || true
    sudo -u postgres repmgr -f /etc/repmgr.conf primary register
    sudo -u postgres repmgr -f /etc/repmgr.conf cluster show
    ;;

  standby)
    echo "Cloning and registering standby..."
    cp /tmp/repmgr_standby.conf /etc/repmgr.conf
    chown postgres:postgres /etc/repmgr.conf
    systemctl stop postgresql
    sudo -u postgres rm -rf /var/lib/postgresql/16/main
    sudo -u postgres repmgr -h 163.61.156.98 -U repmgr -d repmgr \
      -f /etc/repmgr.conf standby clone --fast-checkpoint
    systemctl start postgresql
    sudo -u postgres repmgr -f /etc/repmgr.conf standby register
    sudo -u postgres repmgr -f /etc/repmgr.conf cluster show
    ;;

  witness)
    echo "Registering witness node..."
    # Witness needs a local PostgreSQL instance (metadata only)
    apt-get install -y postgresql-16 postgresql-16-repmgr
    cp /tmp/repmgr_witness.conf /etc/repmgr.conf
    chown postgres:postgres /etc/repmgr.conf
    sudo -u postgres createuser -s repmgr 2>/dev/null || true
    sudo -u postgres createdb repmgr -O repmgr 2>/dev/null || true
    sudo -u postgres repmgr -h 163.61.156.98 -U repmgr -d repmgr \
      -f /etc/repmgr.conf witness register
    sudo -u postgres repmgr -f /etc/repmgr.conf cluster show
    ;;

  *)
    echo "Usage: $0 {primary|standby|witness}"
    exit 1
    ;;
esac

echo "Repmgr $NODE_ROLE setup complete."
