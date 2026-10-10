# Advanced Database Systems Capstone Project Report

**Track Selected:** Multi-Tenant SaaS E-Commerce Architecture
**Database Engine Engine:** PostgreSQL 16

---

## 🔗 Live Database Environment Code
* **Verified Project Playground Fiddle:** [https://www.db-fiddle.com/f/aUXKAjh8si4YuWCqc8BanB/1]

---

## 🌿 1. Entity-Relationship Diagram (ERD)
*Note: The structural database schema was successfully mapped and evaluated using dynamic relational connections.*
*(Remember to upload your downloaded PNG image from dbdiagram.io to this GitHub repository, or simply drag and drop the image file directly into this text editor box to embed it!)*

---

## 📊 2. Live Verification Results & Execution Metrics

### Query #1 & #3 Output Data:
[**Schema (PostgreSQL v16)**

    DROP TABLE IF EXISTS audit_log CASCADE;
    DROP TABLE IF EXISTS order_items CASCADE;
    DROP TABLE IF EXISTS orders CASCADE;
    DROP TABLE IF EXISTS products CASCADE;
    DROP TABLE IF EXISTS users CASCADE;
    DROP TABLE IF EXISTS tenants CASCADE;
    
    -- Step 2: Core Table Migrations Structure
    CREATE TABLE tenants (
        id SERIAL PRIMARY KEY,
        company_name VARCHAR(255) NOT NULL,
        created_at TIMESTAMPTZ DEFAULT NOW()
    );
    
    CREATE TABLE users (
        id SERIAL PRIMARY KEY,
        tenant_id INT REFERENCES tenants(id) ON DELETE CASCADE,
        email VARCHAR(255) UNIQUE NOT NULL,
        password_hash TEXT NOT NULL,
        role VARCHAR(50) NOT NULL
    );
    
    CREATE TABLE products (
        id SERIAL PRIMARY KEY,
        tenant_id INT REFERENCES tenants(id) ON DELETE CASCADE,
        sku VARCHAR(100) NOT NULL,
        name VARCHAR(255) NOT NULL,
        base_price NUMERIC(12,2) NOT NULL,
        variable_attributes JSONB DEFAULT '{}'::jsonb
    );
    
    CREATE TABLE orders (
        id SERIAL PRIMARY KEY,
        tenant_id INT REFERENCES tenants(id) ON DELETE CASCADE,
        user_id INT REFERENCES users(id),
        total_amount NUMERIC(12,2) NOT NULL,
        status VARCHAR(50) DEFAULT 'pending',
        created_at TIMESTAMPTZ DEFAULT NOW()
    );
    
    -- Optimization B-Tree and GIN Indexes
    CREATE INDEX idx_users_tenant ON users(tenant_id, email);
    CREATE INDEX idx_products_tenant ON products(tenant_id, sku);
    CREATE INDEX idx_orders_tenant ON orders(tenant_id, created_at DESC);
    CREATE INDEX idx_products_attributes ON products USING GIN (variable_attributes);
    
    -- Automated Step 5 Structural Audit Logs
    CREATE TABLE audit_log (
        id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
        tbl TEXT NOT NULL,
        op TEXT NOT NULL,
        old_row JSONB,
        new_row JSONB,
        changed_by TEXT DEFAULT current_user,
        at TIMESTAMPTZ DEFAULT now()
    );
    
    CREATE OR REPLACE FUNCTION process_audit() RETURNS TRIGGER AS $$
    BEGIN
        INSERT INTO audit_log(tbl, op, old_row, new_row)
        VALUES (TG_TABLE_NAME, TG_OP, to_jsonb(OLD), to_jsonb(NEW));
        RETURN COALESCE(NEW, OLD);
    END;
    $$ LANGUAGE plpgsql;
    
    CREATE TRIGGER trg_audit_products 
    AFTER INSERT OR UPDATE OR DELETE ON products
    FOR EACH ROW EXECUTE FUNCTION process_audit();
    
    -- Base Database Seeding
    INSERT INTO tenants (company_name) VALUES ('Alpha Tech'), ('Beta Apparel');
    INSERT INTO users (tenant_id, email, password_hash, role) VALUES 
    (1, 'admin@alpha.com', '$2b$12$xyz...', 'admin'),
    (2, 'manager@beta.com', '$2b$12$abc...', 'manager');
    INSERT INTO products (tenant_id, sku, name, base_price, variable_attributes) VALUES 
    (1, 'LAP-001', 'Pro Laptop', 1299.99, '{"specs": {"ram": "16GB", "storage": "512GB"}}'::jsonb),
    (1, 'PHN-002', 'Smart Phone', 799.00, '{"specs": {"screen": "6.1 inch"}}'::jsonb),
    (2, 'TSH-001', 'Cotton T-Shirt', 24.99, '{"details": {"size": "L", "color": "Blue"}}'::jsonb);
    

---

**Query #1**

    -- Query #1: Fetch item properties matching specific JSONB fields
    SELECT sku, name, base_price, variable_attributes->'specs'->>'ram' AS ram_size
    FROM products 
    WHERE variable_attributes @> '{"specs": {"ram": "16GB"}}';

| sku     | name       | base_price | ram_size |
| ------- | ---------- | ---------- | -------- |
| LAP-001 | Pro Laptop | 1299.99    | 16GB     |

---
**Query #2**

    -- Query #2: Trigger data mutation changes to verify tracking logs
    UPDATE products SET base_price = 1199.99 WHERE sku = 'LAP-001';

There are no results to be displayed.

---
**Query #3**

    -- Query #3: Verify captured history entries inside your Audit Logs
    SELECT tbl, op, old_row->>'name' AS target_item, old_row->>'base_price' AS previous_price, new_row->>'base_price' AS updated_price 
    FROM audit_log;

| tbl      | op     | target_item | previous_price | updated_price |
| -------- | ------ | ----------- | -------------- | ------------- |
| products | INSERT |             |                | 1299.99       |
| products | INSERT |             |                | 799.00        |
| products | INSERT |             |                | 24.99         |
| products | UPDATE | Pro Laptop  | 1299.99        | 1199.99       |

---

[View on DB Fiddle](https://www.db-fiddle.com/f/aUXKAjh8si4YuWCqc8BanB/1)]

---

## 🛠️ 3. Production Architecture Projections
* **Automated Migration Pipeline:** Table revisions are structured using sequential alphanumeric schema file tags (`V1` to `V5`). Executing automated tracking updates allows platforms like Flyway to incrementally deploy infrastructure adjustments cleanly.
* **Least-Privilege Role Separation:** Enterprise instances isolate operations by separating user roles into data read-only profiles (`app_read`) and targeted execution modification engines (`app_write`), mitigating accidental schema deletions.
* **Server DR Backup Routine:** Point-in-time binary dumps are scheduled automatically on a cron sequence using:
  pg_dump -Fc -f backups/capstone_\$(date +%F).dump capstone
