# Security & Least-Privilege

Even though root credentials were provided for the assessment, operating as root in production is an anti-pattern. 

## Implementation
1.  **Dedicated Users:**
    *   `deployer`: A non-root user with passwordless `sudo` privileges created for application deployment and maintenance.
    *   `postgres`: Standard system user for DB engine.
    *   `repmgr`: Dedicated database user for replication only.
    *   `laravel_db`: Dedicated database user restricted to the application database.
2.  **Firewall (UFW):**
    *   Default Deny all incoming traffic.
    *   VM-1 allows `22`, `80/443`, PgBouncer `6432` from the Docker bridge, and PostgreSQL `5432` from the cluster CIDR for the repmgr witness.
    *   VM-2 and VM-3 allow `22` and PostgreSQL `5432` only from the cluster CIDR.
3.  **SSH Hardening:**
    *   Password authentication is left enabled during the assessment bootstrap because the provided access method uses root credentials.
    *   For a production handoff, inject SSH keys for `deployer`, then disable password authentication and root SSH login.
    *   The automatic failover hook requires passwordless SSH from the `postgres` user on VM-3 to the `deployer` user on VM-1.
