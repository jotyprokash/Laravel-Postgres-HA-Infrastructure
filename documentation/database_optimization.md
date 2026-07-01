# PostgreSQL Optimization for High-Concurrency Writes

The provided database VMs have approximately 8 GB RAM and 96 GB disk. The tuning below is designed for high-concurrency registration writes behind PgBouncer while keeping memory pressure predictable during load testing.

## Key Tuning Parameters (`postgresql.conf`)

| Parameter | Value | Justification |
| :--- | :--- | :--- |
| `synchronous_commit` | `off` | **Critical.** Returns success to the client before WAL is flushed to disk. Essential for high throughput, though a hard OS crash could lose milliseconds of data. |
| `shared_buffers` | `4GB` | Aggressive cache allocation for a dedicated 8 GB database VM. PgBouncer limits backend concurrency so PostgreSQL does not need thousands of server processes. |
| `work_mem` | `8MB` | Keeps per-operation memory bounded under concurrent load. Registration inserts do not require large sort/hash memory. |
| `effective_cache_size` | `6GB` | Planner hint aligned to the available OS cache on an 8 GB VM. |
| `wal_buffers` | `16MB` | Buffers WAL records in memory before writing to disk. Larger buffer = fewer I/O interruptions. |
| `max_wal_size` | `4GB` | Allows WAL to grow significantly before forcing a checkpoint. Reduces checkpoint I/O spikes. |
| `checkpoint_timeout` | `15min` | Delays checkpoints to group I/O operations, drastically improving write latency. |
| `commit_delay` | `1000` | Microseconds to wait before flushing WAL to group multiple transactions. |
| `commit_siblings` | `5` | Only triggers `commit_delay` if at least 5 transactions are waiting, optimizing high-concurrency flushes. |
| `max_connections` | `500` | Kept relatively low because PgBouncer handles the actual thousands of client connections. |

## Network & Kernel Level (`sysctl.conf`)
*   `net.core.somaxconn = 65535`
*   `fs.file-max = 2097152`
*   `net.ipv4.tcp_tw_reuse = 1`
*(Reduces connection backlog, file descriptor, and TCP reuse bottlenecks during high-concurrency load testing).*
