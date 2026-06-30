# High-Availability Laravel Infrastructure

Production-grade deployment of a Laravel application backed by a highly available PostgreSQL cluster. Architected specifically to handle extreme burst traffic (100K/s concurrent write operations).

## Architecture

![Architecture Diagram](architecture.png)

* **Application Tier (VM-1):** Dockerized Laravel API routing through PgBouncer for strict connection pooling.
* **Database Tier (VM-2 & VM-3):** Native PostgreSQL 16 configured with asynchronous streaming replication.
* **High Availability:** Managed via `repmgr`, featuring automatic failover and a witness node to prevent split-brain partition scenarios.

## Deployment

Execute the provisioning executables sequentially on fresh Ubuntu 22.04 servers:

```bash
# 1. Base OS Security & Hardening (All Nodes)
bash executables/00_security_hardening.sh

# 2. Database Provisioning
bash executables/01_postgres_primary.sh     # Primary (VM-2)
bash executables/02_postgres_standby.sh     # Standby (VM-3)

# 3. High Availability Cluster Initialization
bash executables/03_repmgr_setup.sh primary # VM-2
bash executables/03_repmgr_setup.sh standby # VM-3
bash executables/03_repmgr_setup.sh witness # VM-1

# 4. Application & Pooler Deployment
bash executables/04_app_deployment.sh       # App Server (VM-1)

# 5. End-to-End Validation
bash executables/05_validate.sh
```

> **Note:** Detailed technical reasoning for OS/Kernel tuning, database parameter adjustments, and security posture are available in the `documentation/` directory.
