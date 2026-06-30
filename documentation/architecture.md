# Architecture & Design Reasoning

## Overview
The architecture is designed to handle extreme burst traffic (100K/s writes) while maintaining absolute data integrity and high availability.

## Component Selection & Reasoning

### 1. Application Layer (VM-1): Dockerized Laravel API
*   **Why Docker?** Encapsulating the stateless application layer ensures perfect portability, rapid rollback, and strict dependency isolation. 
*   **Why native database?** We avoid Docker for the database nodes to prevent virtualization overhead on disk I/O, which is the primary bottleneck for database writes.

### 2. Connection Pooler (VM-1): PgBouncer
*   **Why?** PostgreSQL spawns a new OS process per connection. 100K concurrent connections would instantly OOM (Out of Memory) the server. PgBouncer queues these requests and multiplexes them across a small, stable pool of backend connections (~200).

### 3. Database Layer (VM-2 & VM-3): PostgreSQL 16
*   **Why PostgreSQL?** Native streaming replication, transactional integrity, and highly tunable memory/WAL structures make it ideal for this scenario.

### 4. High Availability: Repmgr
*   **Why Repmgr?** It is an industry-standard, lightweight cluster manager. We deploy the primary on VM-2, the replica on VM-3, and a "Witness" node on VM-1. The witness provides a 3rd vote for quorum, mathematically preventing "split-brain" scenarios during network partitions.
