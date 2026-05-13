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

-- ============================================================
-- VENDORS — suppliers we owe money to
-- ============================================================
CREATE TABLE IF NOT EXISTS vendors (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  account_code TEXT,
  address TEXT,
  city TEXT,
  state TEXT,
  zip TEXT,
  country TEXT DEFAULT 'USA',
  phone TEXT,
  fax TEXT,
  email TEXT,
  website TEXT,
  bank_name TEXT,
  bank_account_name TEXT,
  bank_account_number TEXT,
  bank_aba TEXT,
  bank_swift TEXT,
  bank_address TEXT,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_vendors_name ON vendors(name);
CREATE UNIQUE INDEX IF NOT EXISTS uq_vendors_name ON vendors(name);

-- ============================================================
-- BILLS — payables (vendor invoices we owe)
-- ============================================================
CREATE TABLE IF NOT EXISTS bills (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  bill_number TEXT,
  vendor_id UUID REFERENCES vendors(id),
  vendor_name TEXT,
  bill_date DATE,
  due_date DATE,
  terms TEXT,
  customer_po TEXT,
  sales_person TEXT,
  ship_via TEXT,
  tracking_number TEXT,
  subtotal NUMERIC(12,2) DEFAULT 0,
  tax NUMERIC(12,2) DEFAULT 0,
  freight NUMERIC(12,2) DEFAULT 0,
  discount NUMERIC(12,2) DEFAULT 0,
  total NUMERIC(12,2) DEFAULT 0,
  amount_paid NUMERIC(12,2) DEFAULT 0,
  balance_due NUMERIC(12,2) DEFAULT 0,
  status TEXT DEFAULT 'open' CHECK (status IN ('draft','open','partial','paid','overdue','disputed','cancelled')),
  paid_at TIMESTAMPTZ,
  pdf_url TEXT,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_bills_vendor ON bills(vendor_id);
CREATE INDEX IF NOT EXISTS idx_bills_status ON bills(status);
CREATE INDEX IF NOT EXISTS idx_bills_due_date ON bills(due_date);
CREATE UNIQUE INDEX IF NOT EXISTS uq_bills_vendor_billnum ON bills(vendor_id, bill_number);

-- ============================================================
-- BILL ITEMS — line items per bill (received + backordered)
-- ============================================================
CREATE TABLE IF NOT EXISTS bill_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  bill_id UUID REFERENCES bills(id) ON DELETE CASCADE,
  product_id UUID REFERENCES products(id),
  sku TEXT,
  mfg_item_number TEXT,
  description TEXT NOT NULL,
  quantity_received INT NOT NULL DEFAULT 0,
  quantity_backordered INT NOT NULL DEFAULT 0,
  list_price NUMERIC(10,2),
  unit_cost NUMERIC(10,2) NOT NULL DEFAULT 0,
  total_cost NUMERIC(12,2) NOT NULL DEFAULT 0,
  serial_numbers TEXT[],
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_bill_items_bill ON bill_items(bill_id);
CREATE INDEX IF NOT EXISTS idx_bill_items_product ON bill_items(product_id);

-- ============================================================
-- RLS — match existing pattern (single-user password-protected admin)
-- ============================================================
ALTER TABLE vendors ENABLE ROW LEVEL SECURITY;
ALTER TABLE bills ENABLE ROW LEVEL SECURITY;
ALTER TABLE bill_items ENABLE ROW LEVEL SECURITY;

DO $$
DECLARE
  t TEXT; p TEXT;
  pairs TEXT[][] := ARRAY[
    ['vendors','anon_all_vendors'],
    ['bills','anon_all_bills'],
    ['bill_items','anon_all_bill_items']
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
-- TRIGGER — auto-flip bill status based on balance + due_date
-- ============================================================
CREATE OR REPLACE FUNCTION update_bill_status()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.balance_due <= 0 AND NEW.status NOT IN ('disputed','cancelled') THEN
    NEW.status := 'paid';
    IF NEW.paid_at IS NULL THEN NEW.paid_at := NOW(); END IF;
  ELSIF NEW.due_date IS NOT NULL AND NEW.due_date < CURRENT_DATE
        AND NEW.balance_due > 0
        AND NEW.status NOT IN ('disputed','cancelled','paid') THEN
    NEW.status := CASE WHEN NEW.amount_paid > 0 THEN 'partial' ELSE 'overdue' END;
  END IF;
  NEW.updated_at := NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_bill_status ON bills;
CREATE TRIGGER trg_bill_status
  BEFORE INSERT OR UPDATE ON bills
  FOR EACH ROW EXECUTE FUNCTION update_bill_status();

-- ============================================================
-- SEED — vendor 1: Yarbo International Inc.
-- Source: /Users/dougbrown/Desktop/INV-001749 (4).pdf
-- ============================================================
INSERT INTO vendors (
  name, address, city, state, zip, country, phone, email, website,
  bank_name, bank_account_name, bank_account_number, bank_aba, bank_swift, bank_address
) VALUES (
  'Yarbo International Inc.',
  '8 The Green Ste A, Kent',
  'Dover', 'DE', '19901', 'USA',
  '+1-631-818-1850',
  'info@yarbo.com',
  'https://www.yarbo.com',
  'Citibank, N.A.',
  'YARBO INTERNATIONAL INC',
  '51000027',
  '021000089',
  'CITIUS33XXX',
  '388 Greenwich Street, New York, NY 10013'
) ON CONFLICT (name) DO NOTHING;

-- ============================================================
-- SEED — vendor 2: Congdon Associates / CADCO Distribution
-- Source: Invoice No. 108833 ... .pdf
-- ============================================================
INSERT INTO vendors (
  name, account_code, address, city, state, zip, country, phone, fax, email
) VALUES (
  'Congdon Associates (CADCO Distribution)',
  'C0003599',
  '8 McFadden Road',
  'Easton', 'PA', '18045', 'USA',
  '800-942-2326',
  '877-224-2521',
  'parts@cadcodist.com'
) ON CONFLICT (name) DO NOTHING;

-- ============================================================
-- SEED — bill 1: Yarbo INV-001749  (OPEN, due 2026-05-22)
-- ============================================================
WITH v AS (SELECT id FROM vendors WHERE name = 'Yarbo International Inc.' LIMIT 1)
INSERT INTO bills (
  bill_number, vendor_id, vendor_name, bill_date, due_date, terms,
  subtotal, tax, total, balance_due, status, notes
)
SELECT
  'INV-001749', v.id, 'Yarbo International Inc.',
  '2026-01-19', '2026-05-22', 'Custom',
  6448.00, 0.00, 6448.00, 6448.00, 'open',
  'Source PDF: /Users/dougbrown/Desktop/INV-001749 (4).pdf. Bill-to "Second Nature" (parent LLC of Smart Lawn). 2x refurbished bundles + 2x tow hitches included free.'
FROM v
ON CONFLICT (vendor_id, bill_number) DO NOTHING;

WITH b AS (SELECT id FROM bills WHERE bill_number = 'INV-001749' LIMIT 1)
INSERT INTO bill_items (bill_id, sku, description, quantity_received, unit_cost, total_cost, notes)
SELECT b.id, 's1 m1 used',
       'Snow Blower Module + Lawn Mower Module + Refurbished Yarbo Core (bundle)',
       2, 3224.00, 6448.00, NULL FROM b
WHERE NOT EXISTS (SELECT 1 FROM bill_items WHERE bill_id = b.id AND sku = 's1 m1 used')
UNION ALL
SELECT b.id, 'tow hitch', 'Yarbo Tow Hitch',
       2, 69.00, 0.00,
       'List price $69 ea but invoice shows $0 ext. price (included free with bundle).' FROM b
WHERE NOT EXISTS (SELECT 1 FROM bill_items WHERE bill_id = b.id AND sku = 'tow hitch');

-- ============================================================
-- SEED — bill 2: CADCO 108833  (OVERDUE 2026-04-23, 13 units + X450 backorder)
-- ============================================================
WITH v AS (SELECT id FROM vendors WHERE account_code = 'C0003599' LIMIT 1)
INSERT INTO bills (
  bill_number, vendor_id, vendor_name, bill_date, due_date, terms,
  customer_po, sales_person, ship_via, tracking_number,
  subtotal, tax, freight, total, balance_due, status, notes
)
SELECT
  '108833', v.id, 'Congdon Associates (CADCO Distribution)',
  '2026-03-24', '2026-04-23', 'Net30',
  '032026', 'Justin Neiles', 'Pitt Ohio Express', '5054577842',
  16303.55, 0.00, 0.00, 16303.55, 16303.55, 'overdue',
  'Source PDF: Invoice No. 108833 ... .pdf. Bill-to Second Nature Tree LLC dba Smart Lawn. Based on SO 84463 / Delivery 98232. 13 units total received, X450 1.5 Acre 4WD on backorder qty 2 (now received per Doug 2026-05-13, serials TBD).'
FROM v
ON CONFLICT (vendor_id, bill_number) DO NOTHING;

WITH b AS (SELECT id FROM bills WHERE bill_number = '108833' LIMIT 1)
INSERT INTO bill_items (bill_id, mfg_item_number, description,
                        quantity_received, quantity_backordered,
                        list_price, unit_cost, total_cost, serial_numbers)
SELECT b.id, 'X430', 'Navimow Inc X430 1.0 Acre - 4WD',
       4, 0, 1750.00, 1715.00, 6860.00,
       ARRAY['22EBD2549Y1911','22EBD2549Y1944','22EBD2549Y1959','22EBD2549Y1985'] FROM b
WHERE NOT EXISTS (SELECT 1 FROM bill_items WHERE bill_id = b.id AND mfg_item_number = 'X430')
UNION ALL
SELECT b.id, 'i210 AWD', 'Navimow Inc i210 AWD .25 Acre - AWD',
       1, 0, 948.27, 929.30, 929.30,
       ARRAY['2SEEA2544K0396'] FROM b
WHERE NOT EXISTS (SELECT 1 FROM bill_items WHERE bill_id = b.id AND mfg_item_number = 'i210 AWD')
UNION ALL
SELECT b.id, 'H220', 'Navimow Inc H220 .5 Acre - 2WD',
       1, 1, 1539.30, 1508.51, 1508.51,
       ARRAY['20HAA2545Y0061'] FROM b
WHERE NOT EXISTS (SELECT 1 FROM bill_items WHERE bill_id = b.id AND mfg_item_number = 'H220')
UNION ALL
SELECT b.id, 'i215 LiDAR', 'Navimow Inc i215 LiDAR .37 Acre - 2WD',
       1, 0, 1167.27, 1143.92, 1143.92,
       ARRAY['21DDB2545Y0542'] FROM b
WHERE NOT EXISTS (SELECT 1 FROM bill_items WHERE bill_id = b.id AND mfg_item_number = 'i215 LiDAR')
UNION ALL
SELECT b.id, 'CM 120M1', 'Navimow Inc CM 120M1 Terranox - 3 Acre',
       1, 0, 3574.35, 1787.18, 1787.18,
       ARRAY['22GBE2551Y0221'] FROM b
WHERE NOT EXISTS (SELECT 1 FROM bill_items WHERE bill_id = b.id AND mfg_item_number = 'CM 120M1')
UNION ALL
SELECT b.id, 'CM 240M1', 'Navimow Inc CM 240M1 Terranox - 6 Acre',
       1, 0, 4549.35, 2274.68, 2274.68,
       ARRAY['22HBE2551Y0125'] FROM b
WHERE NOT EXISTS (SELECT 1 FROM bill_items WHERE bill_id = b.id AND mfg_item_number = 'CM 240M1')
UNION ALL
SELECT b.id, 'i1A11N', 'Navimow Inc i1A11N Mowgate (charging accessory)',
       4, 0, 449.99, 449.99, 1799.96, NULL FROM b
WHERE NOT EXISTS (SELECT 1 FROM bill_items WHERE bill_id = b.id AND mfg_item_number = 'i1A11N')
UNION ALL
SELECT b.id, 'X450', 'Navimow Inc X450 1.5 Acre - 4WD (backordered on this bill; received separately)',
       0, 2, NULL, 0, 0, NULL FROM b
WHERE NOT EXISTS (SELECT 1 FROM bill_items WHERE bill_id = b.id AND mfg_item_number = 'X450');

-- ============================================================
-- UPSERT — Navimow products into existing products table
-- Costs from CADCO bill 108833. Retail prices from product pages on smartlawnny.com.
-- Quantity = received - sold - demo, per Doug 2026-05-13.
-- (X430: 4 received, -1 sold, -1 demo = 2 saleable. Demo unit lives in serial_numbers as status='demo'.)
-- ============================================================
INSERT INTO products (sku, name, brand, description, cost, price, quantity, status)
SELECT * FROM (VALUES
  ('navimow-x430',              'Navimow X430 1.0 Acre 4WD',           'Navimow', 'Robotic lawn mower, 1.0 acre, 4WD',         1715.00::numeric, 2499.00::numeric, 2, 'active'),
  ('navimow-x450',              'Navimow X450 1.5 Acre 4WD',           'Navimow', 'Robotic lawn mower, 1.5 acre, 4WD',         0.00::numeric,    2999.00::numeric, 2, 'active'),
  ('navimow-h220',              'Navimow H220 .5 Acre 2WD',            'Navimow', 'Robotic lawn mower, 0.5 acre, 2WD',         1508.51::numeric, 2199.00::numeric, 1, 'active'),
  ('navimow-i210-awd',          'Navimow i210 AWD .25 Acre',           'Navimow', 'Robotic lawn mower, 0.25 acre, AWD',        929.30::numeric,  948.00::numeric,  1, 'active'),
  ('navimow-i215-lidar',        'Navimow i215 LiDAR .37 Acre 2WD',     'Navimow', 'Robotic lawn mower with LiDAR, 0.37 acre',  1143.92::numeric, 1599.00::numeric, 1, 'active'),
  ('navimow-terranox-cm120m1',  'Navimow CM 120M1 Terranox 3 Acre',    'Navimow', 'Commercial robotic mower, 3 acre',          1787.18::numeric, 5499.00::numeric, 1, 'active'),
  ('navimow-terranox-cm240m1',  'Navimow CM 240M1 Terranox 6 Acre',    'Navimow', 'Commercial robotic mower, 6 acre',          2274.68::numeric, 6999.00::numeric, 1, 'active'),
  ('navimow-mowgate',           'Navimow i1A11N Mowgate',              'Navimow', 'Charging gate accessory',                   449.99::numeric,  449.00::numeric,  4, 'active')
) AS v(sku,name,brand,description,cost,price,quantity,status)
WHERE NOT EXISTS (SELECT 1 FROM products p WHERE p.sku = v.sku);

-- ============================================================
-- UPSERT — Yarbo products into products table
-- Source: Yarbo Presentation 2026.pdf + INV-001749. Retail prices NOT YET SET (Doug to set).
-- ============================================================
INSERT INTO products (sku, name, brand, description, cost, price, quantity, status)
SELECT * FROM (VALUES
  ('yarbo-s1m1-refurb-bundle',  'Yarbo Core Refurb + Lawn Mower Module + Snow Blower Module', 'Yarbo', 'Refurbished Y-Series Core bundled with Lawn Mower (non-Pro) and Snow Blower modules. From INV-001749.', 3224.00::numeric, 0::numeric, 2, 'active'),
  ('yarbo-tow-hitch',           'Yarbo Tow Hitch',                                            'Yarbo', 'Tow hitch accessory for Yarbo Core',                                                                  0.00::numeric,    0::numeric, 2, 'active')
) AS v(sku,name,brand,description,cost,price,quantity,status)
WHERE NOT EXISTS (SELECT 1 FROM products p WHERE p.sku = v.sku);

-- ============================================================
-- SEED — serial_numbers for the 8 verified Navimow units (status='in_stock')
-- Doug must manually flag in admin UI:
--   * 1 X430 → status='sold' (per "i sold one x430" 2026-05-13) — needs sale_id, customer_id, sold_at
--   * 1 X430 → status='demo' (per "another x430 i took for demo" 2026-05-13)
-- X450 backorder serials: NOT seeded (no serials in PDF; will arrive on follow-up CADCO invoice).
-- ============================================================
INSERT INTO serial_numbers (serial_number, product_id, status)
SELECT v.sn, p.id, 'in_stock'
FROM (VALUES
  ('22EBD2549Y1911', 'navimow-x430'),
  ('22EBD2549Y1944', 'navimow-x430'),
  ('22EBD2549Y1959', 'navimow-x430'),
  ('22EBD2549Y1985', 'navimow-x430'),
  ('2SEEA2544K0396', 'navimow-i210-awd'),
  ('20HAA2545Y0061', 'navimow-h220'),
  ('21DDB2545Y0542', 'navimow-i215-lidar'),
  ('22GBE2551Y0221', 'navimow-terranox-cm120m1'),
  ('22HBE2551Y0125', 'navimow-terranox-cm240m1')
) AS v(sn, sku)
JOIN products p ON p.sku = v.sku
WHERE NOT EXISTS (SELECT 1 FROM serial_numbers s WHERE s.serial_number = v.sn);

-- ============================================================
-- LINK — backfill bill_items.product_id from sku/mfg_item_number lookup
-- ============================================================
UPDATE bill_items bi
SET product_id = p.id
FROM products p
WHERE bi.product_id IS NULL
  AND (
    (bi.sku IS NOT NULL AND p.sku = bi.sku) OR
    (bi.mfg_item_number = 'X430'        AND p.sku = 'navimow-x430') OR
    (bi.mfg_item_number = 'X450'        AND p.sku = 'navimow-x450') OR
    (bi.mfg_item_number = 'H220'        AND p.sku = 'navimow-h220') OR
    (bi.mfg_item_number = 'i210 AWD'    AND p.sku = 'navimow-i210-awd') OR
    (bi.mfg_item_number = 'i215 LiDAR'  AND p.sku = 'navimow-i215-lidar') OR
    (bi.mfg_item_number = 'CM 120M1'    AND p.sku = 'navimow-terranox-cm120m1') OR
    (bi.mfg_item_number = 'CM 240M1'    AND p.sku = 'navimow-terranox-cm240m1') OR
    (bi.mfg_item_number = 'i1A11N'      AND p.sku = 'navimow-mowgate')
  );

-- ============================================================
-- LEADS — public-form submissions (contact / newsletter / hoa / quote / chat)
-- Built to replace the dead Google Apps Script webhook as the source of truth.
-- Apps Script becomes fire-and-forget for email/SMS notification only.
-- ============================================================
CREATE TABLE IF NOT EXISTS leads (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  source TEXT NOT NULL CHECK (source IN ('contact','newsletter','hoa','quote','chat','map_checkout','property_count','other')),
  raw_payload JSONB,
  first_name TEXT,
  last_name TEXT,
  email TEXT,
  phone TEXT,
  street TEXT,
  city TEXT,
  state TEXT,
  zip TEXT,
  county TEXT,
  lawn_size TEXT,
  interest TEXT,
  message TEXT,
  status TEXT DEFAULT 'new' CHECK (status IN ('new','contacted','qualified','quoted','converted','lost','spam')),
  notes TEXT,
  user_agent TEXT,
  referrer TEXT,
  page_url TEXT,
  contacted_at TIMESTAMPTZ,
  converted_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_leads_status ON leads(status);
CREATE INDEX IF NOT EXISTS idx_leads_source ON leads(source);
CREATE INDEX IF NOT EXISTS idx_leads_email ON leads(email);
CREATE INDEX IF NOT EXISTS idx_leads_phone ON leads(phone);
CREATE INDEX IF NOT EXISTS idx_leads_created_desc ON leads(created_at DESC);

ALTER TABLE leads ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  -- public site needs INSERT only; admin uses anon role for read/update too
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'leads' AND policyname = 'anon_all_leads') THEN
    CREATE POLICY "anon_all_leads" ON leads FOR ALL USING (true) WITH CHECK (true);
  END IF;
END $$;

CREATE OR REPLACE FUNCTION update_leads_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at := NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_leads_updated_at ON leads;
CREATE TRIGGER trg_leads_updated_at
  BEFORE UPDATE ON leads
  FOR EACH ROW EXECUTE FUNCTION update_leads_updated_at();
