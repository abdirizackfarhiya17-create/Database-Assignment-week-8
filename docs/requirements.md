# Engineering Requirements & System Design Metrics

## 1. Functional Scope Boundaries
* **Multi-Tenant Secure Boundaries:** The platform architecture safely encapsulates distinct tenant enterprise datasets on shared table schemas using Row-Level Security (RLS) policies.
* **Hybrid Storage Architecture:** Relational inventory data uses typed tables and JSONB properties, while transient items use memory key-value instances.

## 2. Recovery Plan Metrics
* **RPO (Recovery Point Objective):** Data loss limit must be strictly under 1 minute. Met using synchronous continuous streaming replicas and WAL write archiving safety pipelines.
* **RTO (Recovery Time Objective):** Maximum operational down window bounds under 5 minutes. Enforced via automated orchestration failover tools (e.g., Patroni).
