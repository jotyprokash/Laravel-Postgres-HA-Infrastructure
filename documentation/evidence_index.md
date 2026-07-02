# Evidence Index

This page keeps the screenshots discoverable without turning the README into a long gallery.

| Screenshot | Area | What it proves |
| --- | --- | --- |
| [01-vm1-app-gateway-baseline.png](../evidence/screenshots/01-vm1-app-gateway-baseline.png) | Baseline | VM-1 hostname, OS, memory, disk, network state |
| [01-vm2-db-primary-baseline.png](../evidence/screenshots/01-vm2-db-primary-baseline.png) | Baseline | VM-2 hostname, OS, memory, disk, network state |
| [01-vm3-db-standby-baseline.png](../evidence/screenshots/01-vm3-db-standby-baseline.png) | Baseline | VM-3 hostname, OS, memory, disk, network state |
| [02-vm1-app-gateway-ufw.png](../evidence/screenshots/02-vm1-app-gateway-ufw.png) | Security | VM-1 firewall rules for SSH, HTTP, HTTPS, PgBouncer, repmgr metadata |
| [02-vm2-db-primary-ufw.png](../evidence/screenshots/02-vm2-db-primary-ufw.png) | Security | VM-2 database firewall restricted to cluster traffic |
| [02-vm3-db-standby-ufw.png](../evidence/screenshots/02-vm3-db-standby-ufw.png) | Security | VM-3 database firewall restricted to cluster traffic |
| [03-vm2-postgresql-primary-provisioned.png](../evidence/screenshots/03-vm2-postgresql-primary-provisioned.png) | PostgreSQL | Primary PostgreSQL provisioning |
| [04-vm3-postgresql-standby-prerequisites.png](../evidence/screenshots/04-vm3-postgresql-standby-prerequisites.png) | PostgreSQL | Standby PostgreSQL prerequisites |
| [05-vm2-repmgr-primary-registered.png](../evidence/screenshots/05-vm2-repmgr-primary-registered.png) | HA | Primary registered in repmgr with repmgrd running |
| [06a-vm2-replication-streaming.png](../evidence/screenshots/06a-vm2-replication-streaming.png) | Replication | Primary sees standby streaming asynchronously |
| [06b-vm3-standby-recovery-and-repmgrd.png](../evidence/screenshots/06b-vm3-standby-recovery-and-repmgrd.png) | Replication | Standby is in recovery and repmgrd is active |
| [07a-vm1-witness-registered-and-repmgrd.png](../evidence/screenshots/07a-vm1-witness-registered-and-repmgrd.png) | HA | Witness registered and repmgrd active on VM-1 |
| [07b-vm2-cluster-with-witness.png](../evidence/screenshots/07b-vm2-cluster-with-witness.png) | HA | Cluster view with primary, standby, and witness |
| [08-vm1-laravel-ui-pgbouncer-http-ok.png](../evidence/screenshots/08-vm1-laravel-ui-pgbouncer-http-ok.png) | Application | Laravel UI, container, PgBouncer, and local HTTP health |
| [09-api-registration-write-and-standby-replication.png](../evidence/screenshots/09-api-registration-write-and-standby-replication.png) | Validation | API write persisted and replicated to standby |
| [10-domain-https-frontend-cloudflare-proxied.png](../evidence/screenshots/10-domain-https-frontend-cloudflare-proxied.png) | Public access | Cloudflare-proxied HTTPS frontend working |
| [11-https-domain-api-write-and-standby-replication.png](../evidence/screenshots/11-https-domain-api-write-and-standby-replication.png) | Validation | HTTPS domain write persisted and replicated |
| [12-pre-failover-cluster-and-app-health.png](../evidence/screenshots/12-pre-failover-cluster-and-app-health.png) | Failover | Healthy cluster and app before failover |
| [13a-standby-promoted-to-primary.png](../evidence/screenshots/13a-standby-promoted-to-primary.png) | Failover | Standby promoted after old primary stopped |
| [13b-pgbouncer-repointed-to-promoted-primary.png](../evidence/screenshots/13b-pgbouncer-repointed-to-promoted-primary.png) | Failover | PgBouncer routed application traffic to promoted primary |
| [13c-app-write-success-after-failover.png](../evidence/screenshots/13c-app-write-success-after-failover.png) | Failover | Application write succeeded after failover |
| [13d-old-primary-rejoined-as-standby.png](../evidence/screenshots/13d-old-primary-rejoined-as-standby.png) | Recovery | Old primary safely rejoined as standby |
| [14a-100k-registration-write-test-1k-concurrent-clients.png](../evidence/screenshots/14a-100k-registration-write-test-1k-concurrent-clients.png) | Load | 100K registration requests with 1K concurrency returned HTTP 201 |
| [14b-post-100k-load-db-replication-health.png](../evidence/screenshots/14b-post-100k-load-db-replication-health.png) | Load | Replication and cluster health after load test |
| [15-cloudflare-http3-edge-browser-verified.png](../evidence/screenshots/15-cloudflare-http3-edge-browser-verified.png) | Public access | Browser DevTools verified Cloudflare edge delivery over HTTP/3 (`h3`) |
