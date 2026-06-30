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
    *   Only `22` (SSH), `80/443` (HTTP/S on VM-1), and `5432` (PostgreSQL internally) are allowed.
3.  **SSH Hardening:**
    *   Password authentication is disabled after the initial setup.
    *   Root SSH login is set to `Prohibit-Password` or completely disabled.
