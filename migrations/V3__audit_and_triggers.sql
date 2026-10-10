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
