# Laravel PostgreSQL HA Infrastructure

[![Laravel](https://img.shields.io/badge/Laravel-API-FF2D20?style=flat-square&logo=laravel&logoColor=white)](https://laravel.com)
[![PHP](https://img.shields.io/badge/PHP-8.4_FPM-777BB4?style=flat-square&logo=php&logoColor=white)](https://www.php.net)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-16-4169E1?style=flat-square&logo=postgresql&logoColor=white)](https://www.postgresql.org)
[![PgBouncer](https://img.shields.io/badge/PgBouncer-Pooling-336791?style=flat-square)](https://www.pgbouncer.org)
[![repmgr](https://img.shields.io/badge/repmgr-HA-2F5D7C?style=flat-square)](https://www.repmgr.org)
[![Docker](https://img.shields.io/badge/Docker-Compose-2496ED?style=flat-square&logo=docker&logoColor=white)](https://www.docker.com)
[![Nginx](https://img.shields.io/badge/Nginx-Proxy-009639?style=flat-square&logo=nginx&logoColor=white)](https://nginx.org)
[![Cloudflare](https://img.shields.io/badge/Cloudflare-HTTP%2F3_Edge-F38020?style=flat-square&logo=cloudflare&logoColor=white)](https://www.cloudflare.com)
[![HA](https://img.shields.io/badge/HA-Validated-success?style=flat-square)](documentation/high_availability.md)
[![Failover](https://img.shields.io/badge/Failover-Tested-success?style=flat-square)](documentation/high_availability.md)
[![Load Test](https://img.shields.io/badge/Load-100K_Requests-informational?style=flat-square)](documentation/database_optimization.md)
[![Automation](https://img.shields.io/badge/Automation-Bash_Runbooks-4EAA25?style=flat-square&logo=gnubash&logoColor=white)](documentation/operations_runbook.md)

Three-node Linux infrastructure for a Laravel registration service backed by PostgreSQL 16 high availability, PgBouncer connection pooling, repmgr failover, and Cloudflare-proxied HTTPS.

## Architecture

<p align="center">
  <img src="./architecture.svg?v=20260702-dark" alt="Laravel PostgreSQL HA Architecture" width="1100">
</p>

| VM | Hostname | IP | Role |
| --- | --- | --- | --- |
| VM-1 | `app-gateway` | `163.61.156.56` | Cloudflare origin, Dockerized Laravel/Nginx, PgBouncer, repmgr witness |
| VM-2 | `db-primary` | `163.61.156.98` | Initial PostgreSQL primary; rejoined as standby after failover validation |
| VM-3 | `db-standby` | `163.61.156.112` | Initial PostgreSQL standby; promoted to active primary during failover validation |

## Public Endpoint

The application is available through Cloudflare-proxied HTTPS:

```text
https://app.jotysdevsecopslab.xyz/
```

**Edge Protocol Evidence**

Browser DevTools verified Cloudflare edge delivery over HTTP/3 (`h3`), with HTTP/2 available as fallback for unsupported clients.

<p align="center">
  <img src="./evidence/screenshots/15-cloudflare-http3-browser-devtools-verified.png" alt="Cloudflare HTTP/3 edge protocol verified in browser DevTools" width="900">
</p>

## What Was Implemented

- Laravel registration UI and `/api/register` endpoint with public HTTPS access validated.
- Docker multi-stage PHP 8.4 FPM + Nginx application image.
- PgBouncer transaction pooling on VM-1.
- PostgreSQL 16 native installation on VM-2 and VM-3.
- repmgr primary/standby/witness topology.
- PostgreSQL streaming replication validated between primary and standby.
- Controlled failover validated with PgBouncer repointing to the promoted primary.
- Old primary safely rejoined as standby after failover.
- Cloudflare-proxied HTTPS for the public endpoint.
- 100,000 registration write requests validated with 1,000 concurrent clients.

## Documentation

- [Architecture and technical decisions](documentation/architecture.md)
- [Deployment and reproduction steps](documentation/deployment.md)
- [High availability and failover runbook](documentation/high_availability.md)
- [PostgreSQL optimization and load test results](documentation/database_optimization.md)
- [Security controls](documentation/security.md)
- [Validation matrix](documentation/validation.md)
- [Operations runbook](documentation/operations_runbook.md)
- [Evidence index](documentation/evidence_index.md)
