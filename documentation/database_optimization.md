# PostgreSQL Optimization for 100K/s Writes

Achieving 100K/s writes on a standard relational database requires converting blocking disk I/O into asynchronous memory operations, while managing risk.

## Key Tuning Parameters (`postgresql.conf`)

| Parameter | Value | Justification |
| :--- | :--- | :--- |
| `synchronous_commit` | `off` | **Critical.** Returns success to the client before WAL is flushed to disk. Essential for high throughput, though a hard OS crash could lose milliseconds of data. |
| `shared_buffers` | `4GB` | Allocates ~25% of system RAM for caching data blocks, preventing constant disk reads. |
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
*(Ensures we do not exhaust ephemeral ports or file descriptors during the 100K concurrent load test).*
