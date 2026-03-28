-- Smart Lawn NY — POS & Inventory Management Schema
-- Supabase Project: hsjodrniizoctxsznjsy
-- Run in Supabase SQL Editor (https://supabase.com/dashboard/project/hsjodrniizoctxsznjsy/sql)

-- ============================================================
-- CATEGORIES
-- ============================================================
CREATE TABLE IF NOT EXISTS categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  sort_order INT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

INSERT INTO categories (name, sort_order) VALUES
  ('Robotic Mowers', 1),
  ('Accessories', 2),
  ('Installation', 3),
  ('Service Plans', 4),
  ('Parts', 5)
ON CONFLICT DO NOTHING;

-- ============================================================
-- ENHANCE PRODUCTS TABLE (add columns if missing)
-- ============================================================
ALTER TABLE products ADD COLUMN IF NOT EXISTS category_id UUID REFERENCES categories(id);
ALTER TABLE products ADD COLUMN IF NOT EXISTS description TEXT;
ALTER TABLE products ADD COLUMN IF NOT EXISTS image_url TEXT;
ALTER TABLE products ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'active' CHECK (status IN ('active','inactive','discontinued'));
ALTER TABLE products ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT NOW();

-- ============================================================
-- CUSTOMERS
-- ============================================================
CREATE TABLE IF NOT EXISTS customers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  email TEXT,
  phone TEXT,
  address TEXT,
  city TEXT,
  state TEXT DEFAULT 'NY',
  zip TEXT,
  notes TEXT,
  tags TEXT[] DEFAULT '{}',
  total_spent NUMERIC(12,2) DEFAULT 0,
  total_orders INT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_customers_email ON customers(email);
CREATE INDEX IF NOT EXISTS idx_customers_phone ON customers(phone);

-- ============================================================
-- ENHANCE SALES TABLE (add customer_id FK)
-- ============================================================
ALTER TABLE sales ADD COLUMN IF NOT EXISTS customer_id UUID REFERENCES customers(id);
ALTER TABLE sales ADD COLUMN IF NOT EXISTS tax NUMERIC(10,2) DEFAULT 0;
ALTER TABLE sales ADD COLUMN IF NOT EXISTS subtotal NUMERIC(10,2);
ALTER TABLE sales ADD COLUMN IF NOT EXISTS discount NUMERIC(10,2) DEFAULT 0;
ALTER TABLE sales ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'completed' CHECK (status IN ('completed','refunded','voided'));
ALTER TABLE sales ADD COLUMN IF NOT EXISTS receipt_number TEXT;

-- ============================================================
-- SALE ITEMS (multi-product sales)
-- ============================================================
CREATE TABLE IF NOT EXISTS sale_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  sale_id UUID REFERENCES sales(id) ON DELETE CASCADE,
  product_id UUID REFERENCES products(id),
  product_name TEXT,
  quantity INT NOT NULL DEFAULT 1,
  unit_price NUMERIC(10,2) NOT NULL,
  total NUMERIC(10,2) NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_sale_items_sale ON sale_items(sale_id);

-- ============================================================
-- INVOICES
-- ============================================================
CREATE TABLE IF NOT EXISTS invoices (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  invoice_number TEXT UNIQUE,
  customer_id UUID REFERENCES customers(id),
  customer_name TEXT,
  customer_email TEXT,
  customer_address TEXT,
  status TEXT DEFAULT 'draft' CHECK (status IN ('draft','sent','viewed','paid','overdue','cancelled')),
  due_date DATE,
  subtotal NUMERIC(10,2) DEFAULT 0,
  tax NUMERIC(10,2) DEFAULT 0,
  discount NUMERIC(10,2) DEFAULT 0,
  total NUMERIC(10,2) DEFAULT 0,
  notes TEXT,
  payment_method TEXT,
  paid_at TIMESTAMPTZ,
  sent_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_invoices_customer ON invoices(customer_id);
CREATE INDEX IF NOT EXISTS idx_invoices_status ON invoices(status);

-- ============================================================
-- INVOICE ITEMS
-- ============================================================
CREATE TABLE IF NOT EXISTS invoice_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  invoice_id UUID REFERENCES invoices(id) ON DELETE CASCADE,
  product_id UUID REFERENCES products(id),
  description TEXT NOT NULL,
  quantity INT NOT NULL DEFAULT 1,
  unit_price NUMERIC(10,2) NOT NULL,
  total NUMERIC(10,2) NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_invoice_items_invoice ON invoice_items(invoice_id);

-- ============================================================
-- ORDERS (online + in-store tracking)
-- ============================================================
CREATE TABLE IF NOT EXISTS orders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_number TEXT UNIQUE,
  customer_id UUID REFERENCES customers(id),
  customer_name TEXT,
  customer_email TEXT,
  customer_phone TEXT,
  shipping_address TEXT,
  source TEXT DEFAULT 'in-store' CHECK (source IN ('in-store','online','phone','quote')),
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending','confirmed','processing','shipped','delivered','completed','cancelled','refunded')),
  subtotal NUMERIC(10,2) DEFAULT 0,
  tax NUMERIC(10,2) DEFAULT 0,
  shipping NUMERIC(10,2) DEFAULT 0,
  discount NUMERIC(10,2) DEFAULT 0,
  total NUMERIC(10,2) DEFAULT 0,
  payment_method TEXT,
  payment_status TEXT DEFAULT 'unpaid' CHECK (payment_status IN ('unpaid','partial','paid','refunded')),
  notes TEXT,
  stripe_session_id TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_orders_customer ON orders(customer_id);
CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(status);
CREATE INDEX IF NOT EXISTS idx_orders_number ON orders(order_number);

-- ============================================================
-- ORDER ITEMS
-- ============================================================
CREATE TABLE IF NOT EXISTS order_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID REFERENCES orders(id) ON DELETE CASCADE,
  product_id UUID REFERENCES products(id),
  product_name TEXT,
  quantity INT NOT NULL DEFAULT 1,
  unit_price NUMERIC(10,2) NOT NULL,
  total NUMERIC(10,2) NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_order_items_order ON order_items(order_id);

-- ============================================================
-- ROW LEVEL SECURITY (anon can do everything for now — single-user app)
-- ============================================================
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE sale_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE invoices ENABLE ROW LEVEL SECURITY;
ALTER TABLE invoice_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE order_items ENABLE ROW LEVEL SECURITY;

-- Allow all operations for anon (password-protected admin page)
DO $$
DECLARE
  t TEXT; p TEXT;
  pairs TEXT[][] := ARRAY[
    ['categories','anon_all_categories'],
    ['customers','anon_all_customers'],
    ['sale_items','anon_all_sale_items'],
    ['invoices','anon_all_invoices'],
    ['invoice_items','anon_all_invoice_items'],
    ['orders','anon_all_orders'],
    ['order_items','anon_all_order_items'],
    ['products','anon_all_products'],
    ['sales','anon_all_sales'],
    ['inventory_log','anon_all_inventory_log']
  ];
BEGIN
  FOR i IN 1..array_length(pairs, 1) LOOP
    t := pairs[i][1]; p := pairs[i][2];
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = t AND policyname = p) THEN
      EXECUTE format('CREATE POLICY %I ON %I FOR ALL USING (true) WITH CHECK (true)', p, t);
    END IF;
  END LOOP;
END $$;

-- ============================================================
-- HELPER FUNCTIONS
-- ============================================================

-- Auto-generate invoice numbers: INV-0001, INV-0002, etc.
CREATE OR REPLACE FUNCTION generate_invoice_number()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.invoice_number IS NULL THEN
    NEW.invoice_number := 'INV-' || LPAD(
      (SELECT COALESCE(MAX(CAST(SUBSTRING(invoice_number FROM 5) AS INT)), 0) + 1 FROM invoices)::TEXT, 4, '0');
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_invoice_number ON invoices;
CREATE TRIGGER trg_invoice_number
  BEFORE INSERT ON invoices
  FOR EACH ROW EXECUTE FUNCTION generate_invoice_number();

-- Auto-generate order numbers: ORD-0001, ORD-0002, etc.
CREATE OR REPLACE FUNCTION generate_order_number()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.order_number IS NULL THEN
    NEW.order_number := 'ORD-' || LPAD(
      (SELECT COALESCE(MAX(CAST(SUBSTRING(order_number FROM 5) AS INT)), 0) + 1 FROM orders)::TEXT, 4, '0');
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_order_number ON orders;
CREATE TRIGGER trg_order_number
  BEFORE INSERT ON orders
  FOR EACH ROW EXECUTE FUNCTION generate_order_number();

-- Auto-generate receipt numbers: REC-0001, etc.
CREATE OR REPLACE FUNCTION generate_receipt_number()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.receipt_number IS NULL THEN
    NEW.receipt_number := 'REC-' || LPAD(
      (SELECT COALESCE(MAX(CAST(SUBSTRING(receipt_number FROM 5) AS INT)), 0) + 1 FROM sales WHERE receipt_number IS NOT NULL)::TEXT, 4, '0');
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_receipt_number ON sales;
CREATE TRIGGER trg_receipt_number
  BEFORE INSERT ON sales
  FOR EACH ROW EXECUTE FUNCTION generate_receipt_number();

-- Auto-update customer totals after sale
CREATE OR REPLACE FUNCTION update_customer_totals()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.customer_id IS NOT NULL THEN
    UPDATE customers SET
      total_spent = COALESCE((SELECT SUM(total) FROM sales WHERE customer_id = NEW.customer_id AND status = 'completed'), 0),
      total_orders = COALESCE((SELECT COUNT(*) FROM sales WHERE customer_id = NEW.customer_id AND status = 'completed'), 0),
      updated_at = NOW()
    WHERE id = NEW.customer_id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_update_customer_totals ON sales;
CREATE TRIGGER trg_update_customer_totals
  AFTER INSERT OR UPDATE ON sales
  FOR EACH ROW EXECUTE FUNCTION update_customer_totals();

-- ============================================================
-- WARRANTY TRACKING
-- ============================================================
ALTER TABLE serial_numbers ADD COLUMN IF NOT EXISTS warranty_start DATE;
ALTER TABLE serial_numbers ADD COLUMN IF NOT EXISTS warranty_end DATE;
ALTER TABLE serial_numbers ADD COLUMN IF NOT EXISTS warranty_type TEXT DEFAULT '2-year manufacturer';

-- ============================================================
-- MAAS SUBSCRIPTIONS (Mower-as-a-Service)
-- ============================================================
CREATE TABLE IF NOT EXISTS subscriptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id UUID REFERENCES customers(id),
  customer_name TEXT,
  product_id UUID REFERENCES products(id),
  serial_number_id UUID REFERENCES serial_numbers(id),
  plan_name TEXT NOT NULL,
  monthly_rate NUMERIC(10,2) NOT NULL,
  billing_months INT DEFAULT 6,
  season_start DATE,
  season_end DATE,
  property_address TEXT,
  property_acres NUMERIC(5,2),
  status TEXT DEFAULT 'active' CHECK (status IN ('active','paused','cancelled','completed','pending')),
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_subs_customer ON subscriptions(customer_id);
CREATE INDEX IF NOT EXISTS idx_subs_status ON subscriptions(status);

ALTER TABLE subscriptions ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'subscriptions' AND policyname = 'anon_all_subscriptions') THEN
    CREATE POLICY "anon_all_subscriptions" ON subscriptions FOR ALL USING (true) WITH CHECK (true);
  END IF;
END $$;
