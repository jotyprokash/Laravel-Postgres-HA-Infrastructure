#!/bin/bash
# failover_pgbouncer.sh
# Placed on VM-3 (standby). Called by repmgr event_notification_command upon promotion.
# Updates PgBouncer on VM-1 to point to the new primary.
set -e

NODE_ID=$1
EVENT=$2
NEW_PRIMARY_IP="163.61.156.112"  # VM-3 becomes primary
PGBOUNCER_HOST="163.61.156.56"   # VM-1

if [ "$EVENT" = "standby_promote" ]; then
    echo "Failover detected. Updating PgBouncer on $PGBOUNCER_HOST..."
    ssh deployer@$PGBOUNCER_HOST "sudo sed -i 's/host=163.61.156.98/host=$NEW_PRIMARY_IP/' /etc/pgbouncer/pgbouncer.ini && sudo systemctl reload pgbouncer"
    echo "PgBouncer reconfigured to $NEW_PRIMARY_IP."
fi
