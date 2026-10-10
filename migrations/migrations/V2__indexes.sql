CREATE INDEX idx_users_tenant ON users(tenant_id, email);
CREATE INDEX idx_products_tenant ON products(tenant_id, sku);
CREATE INDEX idx_orders_tenant ON orders(tenant_id, created_at DESC);
CREATE INDEX idx_products_attributes ON products USING GIN (variable_attributes);
