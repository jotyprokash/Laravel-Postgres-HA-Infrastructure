# Architecture and Design Decisions

## Objective

The assessment asked for a three-server infrastructure design covering Laravel deployment, PostgreSQL high availability, replication, failover, security, automation, and high-write validation. The design uses the three VMs as a compact production-style topology rather than spreading every component into its own server.

## Architecture Diagram

![Architecture](../architecture.svg?v=20260702-dark)

## Server Roles

| VM | Hostname | IP | Main responsibility |
| --- | --- | --- | --- |
| VM-1 | `app-gateway` | `163.61.156.56` | Public application gateway, Dockerized Laravel/Nginx, PgBouncer, repmgr witness |
| VM-2 | `db-primary` | `163.61.156.98` | Initial PostgreSQL primary; later rejoined as standby after failover validation |
| VM-3 | `db-standby` | `163.61.156.112` | Initial PostgreSQL standby; promoted to active primary during failover validation |

## Request Flow

Initial write path:

```text
Client -> Cloudflare HTTPS -> VM-1 Nginx/Laravel -> PgBouncer :6432 -> VM-2 PostgreSQL primary -> VM-3 standby
```

Post-failover write path:

```text
Client -> Cloudflare HTTPS -> VM-1 Nginx/Laravel -> PgBouncer :6432 -> VM-3 promoted primary -> VM-2 standby
```

## Technical Decisions

### VM-1 as Application Gateway

VM-1 is the only public application server in the three-node constraint. It runs the Laravel application in Docker and PgBouncer on the host. Keeping PgBouncer beside the application reduces database connection churn and gives the application a stable local database endpoint.

### Dockerized Laravel, Native PostgreSQL

Laravel is containerized for reproducibility and dependency isolation. PostgreSQL runs directly on VM-2 and VM-3 to avoid avoidable database I/O overhead and to keep PostgreSQL service management, replication, and repmgr integration straightforward.

### PgBouncer Instead of Direct Database Connections

PostgreSQL uses a process-per-connection model. High HTTP concurrency should not translate into thousands of PostgreSQL backend processes. PgBouncer transaction pooling limits the backend pool while allowing the Laravel app to accept many client requests.

### PostgreSQL Primary/Standby

Writes intentionally go to one active primary. PostgreSQL streaming replication is used for high availability, not write load balancing. This avoids split-brain and keeps consistency clear.

### repmgr with Witness

`repmgr` manages node metadata and promotion. VM-1 also hosts a lightweight witness PostgreSQL instance so the database cluster has a third voting member for quorum decisions.

### Load Balancing Decision

A separate HTTP load balancer was not added because the assessment provided only three VMs and VM-1 is the only application node. In a larger production deployment, the next scaling step would be multiple Laravel app gateways behind HAProxy, Nginx, an L4/L7 cloud load balancer, or Cloudflare Load Balancing.

For this three-node design:

- Cloudflare provides public DNS/HTTPS edge handling.
- PgBouncer provides database connection pooling and failover routing.
- PostgreSQL remains single-writer primary/standby.

## Final Validated State

The cluster was initially built as:

```text
VM-2 = primary
VM-3 = standby
```

Failover was then validated by stopping VM-2, promoting VM-3, repointing PgBouncer, and writing successfully through the public API. VM-2 was then safely recloned/rejoined as a standby from VM-3.

Final validated state:

```text
VM-3 = active primary
VM-2 = standby
VM-1 = app gateway + witness
```
