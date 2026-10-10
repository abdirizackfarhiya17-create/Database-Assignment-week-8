INSERT INTO tenants (company_name) VALUES ('Alpha Tech'), ('Beta Apparel');

INSERT INTO users (tenant_id, email, password_hash, role) VALUES 
(1, 'admin@alpha.com', '$2b$12$xyz...', 'admin'),
(2, 'manager@beta.com', '$2b$12$abc...', 'manager');

-- Temporarily bypass RLS to seed initial products
SET rls.force_system_bypass = true;

INSERT INTO products (tenant_id, sku, name, base_price, variable_attributes) VALUES 
(1, 'LAP-001', 'Pro Laptop', 1299.99, '{"specs": {"ram": "16GB", "storage": "512GB"}}'::jsonb),
(1, 'PHN-002', 'Smart Phone', 799.00, '{"specs": {"screen": "6.1 inch"}}'::jsonb),
(2, 'TSH-001', 'Cotton T-Shirt', 24.99, '{"details": {"size": "L", "color": "Blue"}}'::jsonb);
