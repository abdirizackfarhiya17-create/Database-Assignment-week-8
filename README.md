# Advanced Database Systems Capstone Project Report (Revised)

**Track Selected:** Multi-Tenant SaaS E-Commerce Architecture
**Database Engine Engine:** PostgreSQL 16
**Status:** All Feedback Deliverables Fully Implemented

---

## 🔗 Environment Deployment & Deliverables
* **Evolutionary Migrations Directory:** Located in the `/migrations` folder (V1 through V5 structured scripts).
* **Live Database Verification Fiddle:** [https://www.db-fiddle.com/f/aUXKAjh8si4YuWCqc8BanB/1]

---

## 🛠️ 1. Integrated Hybrid NoSQL Layer Justification
To complete our hybrid database architecture layout, **Redis** was integrated alongside PostgreSQL to manage ephemeral application states:
* **The Problem:** Shopping carts and active user sessions generate high-volume, transient write operations. Handling these inside PostgreSQL causes table bloat and high disk overhead due to MVCC row versioning.
* **The Solution:** Redis holds these ephemeral key-value states purely in memory, bypassing disk constraints entirely and executing shopping cart lookups with sub-millisecond response latencies.

---

## 🔒 2. Row Level Security & Multi-Tenant Protection (RLS)
To prevent cross-tenant data leaks, strict database-level barriers were deployed in `V4__row_level_security.sql`:
* **Implementation:** Row Level Security (RLS) was explicitly enabled on the `products` and `orders` matrices. 
* **The Policy:** Queries are dynamically restricted using the application's secure session identifier context:
  `USING (tenant_id = current_setting('app.current_tenant_id')::int)`
* **Impact:** Even if a developer accidentally drops a `WHERE` clause in the app code, Tenant A cannot view or alter Tenant B's catalog data.

---

## 📊 3. Query Optimization Diagnostics & Performance Evidence

### Analytical JSONB Selection Query
```sql
SELECT sku, name, base_price FROM products 
WHERE variable_attributes @> '{"specs": {"ram": "16GB"}}';
```

### Execution Plan Performance Evidence:
* **BEFORE PLAN (Without Index):**
  ```text
  Seq Scan on products  (cost=0.00..15.40 rows=1 width=680) (actual time=8.120..8.125 rows=1 loops=1)
  Filter: (variable_attributes @> '{"specs": {"ram": "16GB"}}'::jsonb)
  Rows Removed by Filter: 42
  Execution Time: 8.190 ms
  ```
* **AFTER PLAN (With GIN Index Optimization):**
  ```text
  Bitmap Heap Scan on products  (cost=8.00..12.01 rows=1 width=680) (actual time=0.038..0.040 rows=1 loops=1)
  Recheck Cond: (variable_attributes @> '{"specs": {"ram": "16GB"}}'::jsonb)
  ->  Bitmap Index Scan on idx_products_attributes  (cost=0.00..4.00 rows=1 width=0) (actual time=0.012..0.012 rows=1 loops=1)
        Index Cond: (variable_attributes @> '{"specs": {"ram": "16GB"}}'::jsonb)
  Execution Time: 0.078 ms
  ```
* **Optimization Summary:** Latency reduced significantly from **8.190 ms to 0.078 ms** (a 99% optimization gain). The access strategy successfully transformed from a full disk table sequential sweep (`Seq Scan`) into a rapid index pinpoint scan (`Bitmap Index Scan`).

---

## 🛡️ 4. Enterprise Safety & Operational Controls
* **Change Capture Logging:** Relational structural modifications are logged automatically via a generic PL/pgSQL audit trigger function that records serialized old vs new column snapshots inside `audit_log`.
* **Automated Server Disaster Backups:** High-performance physical binary snapshots are managed on an automated cron routine using:
  `pg_dump -Fc -f backups/capstone_$(date +%F).dump capstone`
