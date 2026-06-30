# High Availability & Failover Mechanism

## The `repmgr` Cluster

We utilize `repmgr` (Replication Manager) daemon (`repmgrd`) to automatically monitor and failover the database cluster.

### Node Configuration
1.  **VM-2 (Primary):** Replicates WAL data to Standby.
2.  **VM-3 (Standby):** Asynchronously receives WAL. If `repmgrd` loses connection to the Primary, it initiates an election.
3.  **VM-1 (Witness):** Does not hold database data, but acts as a tie-breaker. If VM-2 dies, VM-3 and VM-1 form a majority (2 out of 3 votes), allowing VM-3 to safely promote itself to Primary without fear of split-brain.

## Automatic Failover Flow
1. VM-2 crashes.
2. VM-3's `repmgrd` detects the failure after `reconnect_attempts` and `reconnect_interval`.
3. VM-3 checks with VM-1 (Witness). They establish quorum.
4. VM-3 executes `repmgr standby promote`.
5. **Application Routing:** VM-3 executes an `event_notification_command` which SSHs into VM-1 and reloads PgBouncer to point to VM-3's IP.
6. The application experiences sub-second downtime and resumes writing 100K/s to the new Primary.
