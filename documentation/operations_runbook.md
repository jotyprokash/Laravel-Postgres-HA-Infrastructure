# Operations Runbook

This runbook contains the commands used to operate, validate, and recover the assessment environment.

## Server Roles

| Hostname | IP | Current role |
| --- | --- | --- |
| `app-gateway` | `163.61.156.56` | Laravel/Nginx container, PgBouncer, repmgr witness |
| `db-primary` | `163.61.156.98` | Standby after failover and rejoin |
| `db-standby` | `163.61.156.112` | Active PostgreSQL primary after failover |

The names remain from the original provisioning sequence. The role column is the source of truth after failover.

## Daily Health Check

Run on VM-1:

```bash
docker ps
systemctl status pgbouncer --no-pager
grep '^laravel_app' /etc/pgbouncer/pgbouncer.ini
curl -I https://app.jotysdevsecopslab.xyz/

PGPASSWORD=laravel_pass psql -P pager=off -h 127.0.0.1 -p 6432 -U laravel_db -d laravel_app \
  -c "SELECT count(*) FROM registrations;"
```

Run on the active primary:

```bash
sudo -u postgres repmgr -f /etc/repmgr.conf cluster show
sudo -u postgres psql -P pager=off -c \
  "SELECT client_addr, state, sync_state, replay_lsn FROM pg_stat_replication;"
```

Run on the standby:

```bash
sudo -u postgres psql -P pager=off -c "SELECT pg_is_in_recovery();"
sudo -u postgres psql -P pager=off -c \
  "SELECT now() - pg_last_xact_replay_timestamp() AS replication_lag;"
```

## Registration Smoke Test

Run on VM-1:

```bash
curl -i -X POST https://app.jotysdevsecopslab.xyz/api/register \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d '{"username":"ops_smoke_001","email":"ops_smoke_001@example.com","name":"Ops Smoke","phone":"+8801000000009"}'

PGPASSWORD=laravel_pass psql -P pager=off -h 127.0.0.1 -p 6432 -U laravel_db -d laravel_app \
  -c "SELECT id, username, email, created_at FROM registrations WHERE username='ops_smoke_001';"
```

## Controlled Failover

Use this only when the original primary is unavailable or intentionally being failed over.

On the old primary:

```bash
systemctl stop repmgrd
systemctl stop postgresql
systemctl status postgresql --no-pager
```

On the standby to promote:

```bash
sudo -u postgres repmgr -f /etc/repmgr.conf standby promote --log-to-file --force
sudo -u postgres repmgr -f /etc/repmgr.conf cluster show
sudo -u postgres psql -c "SELECT pg_is_in_recovery();"
```

On VM-1, update PgBouncer to the promoted primary:

```bash
grep '^laravel_app' /etc/pgbouncer/pgbouncer.ini
sudo sed -i 's/host=163.61.156.98/host=163.61.156.112/' /etc/pgbouncer/pgbouncer.ini
systemctl reload pgbouncer
grep '^laravel_app' /etc/pgbouncer/pgbouncer.ini

PGPASSWORD=laravel_pass psql -h 127.0.0.1 -p 6432 -U laravel_db -d laravel_app \
  -c "SELECT inet_server_addr(), current_database(), current_user;"
```

Then run the registration smoke test.

## Rejoin Old Primary As Standby

After failover, the old primary must not be restarted as a writable primary. Reclone it from the promoted primary.

On the old primary:

```bash
systemctl stop repmgrd || true
systemctl stop postgresql || true

cp /etc/repmgr.conf /etc/repmgr.conf.before-rejoin.$(date +%Y%m%d_%H%M%S)

cat > /etc/repmgr.conf <<'EOF'
node_id=1
node_name='primary'
conninfo='host=163.61.156.98 user=repmgr dbname=repmgr connect_timeout=2'
data_directory='/var/lib/postgresql/16/main'
failover=automatic
promote_command='/usr/bin/repmgr standby promote -f /etc/repmgr.conf --log-to-file'
follow_command='/usr/bin/repmgr standby follow -f /etc/repmgr.conf --log-to-file --upstream-node-id=%n'
monitoring_history=yes
reconnect_attempts=6
reconnect_interval=10
EOF

sudo -u postgres rm -rf /var/lib/postgresql/16/main

sudo -u postgres repmgr -h 163.61.156.112 -U repmgr -d repmgr \
  -f /etc/repmgr.conf standby clone --fast-checkpoint --force

pg_ctlcluster 16 main start

sudo -u postgres psql -c \
  "ALTER SYSTEM SET primary_conninfo = 'host=163.61.156.112 port=5432 user=repmgr password=repmgr_pass application_name=primary connect_timeout=2';"

pg_ctlcluster 16 main restart

sudo -u postgres repmgr -f /etc/repmgr.conf standby register --force
printf 'REPMGRD_ENABLED=yes\nREPMGRD_CONF="/etc/repmgr.conf"\n' > /etc/default/repmgrd
systemctl restart repmgrd
```

Validate from the active primary:

```bash
sudo -u postgres psql -P pager=off -c \
  "SELECT client_addr, state, sync_state, replay_lsn FROM pg_stat_replication;"

sudo -u postgres repmgr -f /etc/repmgr.conf cluster show
```

## Load Test

Create payload:

```bash
cat > /tmp/register_payload.json <<'EOF'
{"username":"load_test_user","email":"load_test@example.com","name":"Load Test","phone":"+8801000000005"}
EOF
```

Run 100K requests with 1K concurrent clients:

```bash
ulimit -n 200000

hey -n 100000 -c 1000 -m POST \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d "$(cat /tmp/register_payload.json)" \
  http://127.0.0.1/api/register
```

Monitor on VM-1 during the test:

```bash
watch -n 2 'docker stats --no-stream laravel-app; echo; systemctl status pgbouncer --no-pager | sed -n "1,12p"; echo; ss -s'
```

Validate row count:

```bash
PGPASSWORD=laravel_pass psql -P pager=off -h 127.0.0.1 -p 6432 -U laravel_db -d laravel_app \
  -c "SELECT count(*) FROM registrations;"
```

Validate replication after load:

```bash
sudo -u postgres psql -P pager=off -c \
  "SELECT client_addr, state, sync_state, replay_lsn FROM pg_stat_replication;"

sudo -u postgres repmgr -f /etc/repmgr.conf cluster show
```

## Troubleshooting Notes

API route not found:

```bash
docker compose -f docker/docker-compose.yml exec app php artisan route:list
```

The fix in this repo registers Laravel API routes through `src/bootstrap/app.php`.

PgBouncer reports wrong password type:

```text
FATAL: server login failed: wrong password type
```

Use MD5 authentication consistently for the PgBouncer application user.

Standby registered but not streaming:

```bash
sudo -u postgres psql -c \
  "ALTER SYSTEM SET primary_conninfo = 'host=<primary-ip> port=5432 user=repmgr password=repmgr_pass application_name=<node-name> connect_timeout=2';"
pg_ctlcluster 16 main restart
```

Witness shows rejected from another node:

- Confirm witness `conninfo` uses `163.61.156.56`, not `127.0.0.1`.
- Confirm PostgreSQL on VM-1 listens on the public cluster interface.
- Confirm `shared_preload_libraries = 'repmgr'`.

High concurrency EOF during stress test:

- This indicates HTTP/PHP worker or client-side connection saturation, not necessarily PostgreSQL corruption.
- Use the successful 100K/1K run as the accepted validation point.
- Scale app workers and add additional app nodes before claiming very high concurrent-client capacity.
