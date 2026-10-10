-- Enable Row-Level Security globally on sensitive tables
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;

-- Enforce isolation boundaries using runtime tenant parameters
CREATE POLICY tenant_isolation_products ON products 
    USING (tenant_id = current_setting('app.current_tenant_id', true)::int);

CREATE POLICY tenant_isolation_orders ON orders 
    USING (tenant_id = current_setting('app.current_tenant_id', true)::int);
