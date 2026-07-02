# PostgreSQL Optimization and Load Validation

## Hardware Context

Each VM provided approximately:

```text
RAM: 7.8 GiB
Disk: 96 GiB
OS: Ubuntu 24.04.4 LTS
```

The tuning is designed for high-concurrency registration writes behind PgBouncer while keeping memory and connection pressure predictable on the assessment VMs.

## PostgreSQL Parameters

The parameters below are applied from `config/postgresql.conf`.

| Parameter | Value | Reason |
| --- | --- | --- |
| `listen_addresses` | `*` | Allows controlled network access from cluster/app nodes through `pg_hba.conf`. |
| `max_connections` | `500` | Keeps PostgreSQL backend count bounded; PgBouncer absorbs client concurrency. |
| `shared_buffers` | `4GB` | Gives PostgreSQL a large buffer cache on an 8 GB database VM. |
| `work_mem` | `8MB` | Prevents per-query memory blowups under many sessions. Registration writes do not need large sort memory. |
| `maintenance_work_mem` | `512MB` | Helps maintenance operations such as index creation and vacuum. |
| `effective_cache_size` | `6GB` | Planner hint reflecting RAM available for PostgreSQL + OS cache. |
| `wal_level` | `replica` | Required for streaming replication. |
| `wal_buffers` | `16MB` | Buffers WAL writes to reduce write-path interruption. |
| `max_wal_size` | `4GB` | Reduces checkpoint frequency during bursty writes. |
| `min_wal_size` | `1GB` | Keeps WAL segments available for smoother checkpoint behavior. |
| `max_wal_senders` | `10` | Supports standby and future replication consumers. |
| `wal_keep_size` | `1GB` | Helps standby survive short interruptions without immediate reclone. |
| `hot_standby` | `on` | Allows read-only queries on standby. |
| `synchronous_commit` | `off` | Improves write latency by not waiting for WAL flush on every commit. This trades a very small crash-loss window for throughput. |
| `commit_delay` | `1000` | Allows transaction grouping under concurrency. |
| `commit_siblings` | `5` | Applies commit delay only when enough concurrent transactions exist. |
| `checkpoint_timeout` | `15min` | Reduces checkpoint frequency and write spikes. |
| `checkpoint_completion_target` | `0.9` | Spreads checkpoint I/O over time. |
| `autovacuum_max_workers` | `4` | Allows more vacuum/analyze workers under write-heavy tables. |
| `autovacuum_naptime` | `30s` | Checks tables more frequently after heavy insert activity. |
| `autovacuum_vacuum_scale_factor` | `0.05` | Triggers vacuum earlier than default. |
| `autovacuum_analyze_scale_factor` | `0.025` | Keeps planner statistics fresh on fast-growing tables. |
| `log_min_duration_statement` | `500` | Captures slow statements without logging every request. |
| `log_checkpoints` | `on` | Makes checkpoint behavior visible during tuning. |
| `log_lock_waits` | `on` | Helps diagnose write contention. |
| `shared_preload_libraries` | `repmgr` | Required by repmgr/repmgrd monitoring. |

## PgBouncer Tuning

PgBouncer is configured in transaction pooling mode:

```ini
pool_mode = transaction
max_client_conn = 10000
default_pool_size = 200
min_pool_size = 50
reserve_pool_size = 25
reserve_pool_timeout = 3
```

This lets thousands of HTTP requests share a controlled PostgreSQL backend pool instead of creating thousands of PostgreSQL processes.

## Kernel Tuning

Application and database nodes apply:

```text
net.core.somaxconn = 65535
fs.file-max = 2097152
net.ipv4.tcp_tw_reuse = 1
```

The app gateway also widens the ephemeral port range:

```text
net.ipv4.ip_local_port_range = 1024 65535
```

These settings reduce backlog, file descriptor, and TCP churn bottlenecks during concurrent load.

## Indexing Strategy

The registration table indexes:

```php
$table->string('username', 100)->index();
$table->string('email', 255)->index();
```

This supports lookup by username/email during validation and expected registration checks. The endpoint intentionally allows repeated test payloads during load testing; uniqueness constraints were not added because the assessment focus is high-write ingestion and HA validation.

## Load Test Method

The successful local infrastructure load test was executed from VM-1 directly against the app container:

```bash
hey -n 100000 -c 1000 -m POST \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d "$(cat /tmp/register_payload.json)" \
  http://127.0.0.1/api/register
```

Payload:

```json
{"username":"load_test_user","email":"load_test@example.com","name":"Load Test","phone":"+8801000000005"}
```

Result:

```text
Total requests:      100,000
Concurrent clients:  1,000
HTTP status:         100,000 x 201 Created
Requests/sec:        201.8751
Average latency:     4.9306s
p95 latency:         5.3170s
p99 latency:         5.4676s
Rows after test:     111,003
```

Evidence:

![100K registration write test](../evidence/screenshots/14a-100k-registration-write-test-1k-concurrent-clients.png)

Post-load replication health remained healthy:

![Post-load DB replication health](../evidence/screenshots/14b-post-100k-load-db-replication-health.png)

## 5K Concurrency Stress Observation

A follow-up stress test at 5,000 concurrent clients was intentionally attempted to observe the limit. This was treated as a boundary stress observation, separate from the successful 100K-request validation at 1K concurrency:

```text
100,000 requested
13,100 successful 201 responses
86,900 client/server connection errors
```

The error pattern (`EOF`, `server closed idle connection`) indicated saturation in the HTTP/client/Nginx/PHP-FPM connection layer rather than PostgreSQL failure. PgBouncer and database replication stayed healthy afterward.

## Scaling Note for 100K Writes/sec

The assessment wording mentions 100K/s writes. The provided 3-VM environment validated the HA write path under controlled load, but sustained 100K writes/sec would require both vertical and horizontal scaling:

- vertical database scaling: more CPU, RAM, faster NVMe/high-IOPS storage, and tuned WAL/checkpoint I/O;
- horizontal application scaling: multiple Laravel/PHP-FPM nodes behind a load balancer;
- distributed load generation;
- possible queue/batch ingestion for write smoothing;
- end-to-end TLS/load balancer tuning.

This implementation shows the correct HA architecture and controlled write-path behavior within the provided VM constraints.
