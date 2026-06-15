-- ============================================================
-- DHBH App - Complete Supabase Schema
-- ============================================================
-- Jalankan SQL ini di Supabase SQL Editor (https://supabase.com)
-- ============================================================

-- 1. TABEL BRANCH (Cabang)
CREATE TABLE IF NOT EXISTS branches (
  id BIGSERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  address TEXT,
  phone TEXT,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. TABEL USER ROLES (Role Pengguna)
CREATE TABLE IF NOT EXISTS user_roles (
  id BIGSERIAL PRIMARY KEY,
  name TEXT NOT NULL UNIQUE, -- 'admin', 'kasir'
  description TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Insert default roles
INSERT INTO user_roles (name, description) VALUES
  ('admin', 'Administrator dengan akses penuh'),
  ('kasir', 'Kasir dengan akses POS dan history')
ON CONFLICT (name) DO NOTHING;

-- Insert 3 cabang default
INSERT INTO branches (name, address, phone) VALUES
  ('Cabang DHBH 1', 'Jl. Merdeka No. 1', '021-1234561'),
  ('Cabang DHBH 2', 'Jl. Sudirman No. 2', '021-1234562'),
  ('Cabang DHBH 3', 'Jl. Thamrin No. 3', '021-1234563')
ON CONFLICT DO NOTHING;

-- 3. TABEL USER PROFILES (Profil Pengguna - terhubung ke Supabase Auth)
CREATE TABLE IF NOT EXISTS user_profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  username TEXT UNIQUE NOT NULL,
  full_name TEXT NOT NULL,
  role_id BIGINT REFERENCES user_roles(id) NOT NULL,
  branch_id BIGINT REFERENCES branches(id),
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Trigger: Auto-create user_profiles when user signs up via Supabase Auth
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.user_profiles (id, username, full_name, role_id, is_active)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data ->> 'username', split_part(NEW.email, '@', 1)),
    COALESCE(
      NEW.raw_user_meta_data ->> 'display_name',
      NEW.raw_user_meta_data ->> 'name',
      split_part(NEW.email, '@', 1)
    ),
    COALESCE(
      (SELECT id FROM public.user_roles WHERE name = COALESCE(NEW.raw_user_meta_data ->> 'role', 'kasir')),
      (SELECT id FROM public.user_roles WHERE name = 'kasir')
    ),
    true
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 4. TABEL PRODUCT CATEGORIES (Kategori Produk/Layanan)
CREATE TABLE IF NOT EXISTS product_categories (
  id BIGSERIAL PRIMARY KEY,
  name TEXT NOT NULL UNIQUE,
  description TEXT,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Insert default categories
INSERT INTO product_categories (name, description) VALUES
  ('Bekam', 'Layanan bekam'),
  ('Terapi', 'Layanan terapi dan pijat'),
  ('Herbal', 'Produk herbal'),
  ('Perawatan', 'Layanan perawatan tubuh')
ON CONFLICT (name) DO NOTHING;

-- 5. TABEL PRODUCTS (Produk/Layanan) - Berdasarkan data Excel
CREATE TABLE IF NOT EXISTS products (
  id BIGSERIAL PRIMARY KEY,
  item_no INT UNIQUE,
  category_id BIGINT REFERENCES product_categories(id),
  category TEXT,
  name TEXT NOT NULL,
  description TEXT,
  price_clinic INT NOT NULL,
  price_home_visit INT,
  image_url TEXT,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 6. TABEL PRODUCT VARIANTS (Varian Produk - untuk produk dengan variasi)
CREATE TABLE IF NOT EXISTS product_variants (
  id BIGSERIAL PRIMARY KEY,
  product_id BIGINT REFERENCES products(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  price_adjustment INT DEFAULT 0,
  stock INT DEFAULT 0,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 7. TABEL CUSTOMERS (Pelanggan)
CREATE TABLE IF NOT EXISTS customers (
  id BIGSERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  phone TEXT,
  address TEXT,
  total_visits INT DEFAULT 0,
  total_spent BIGINT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 8. TABEL TRANSACTIONS (Transaksi)
CREATE TABLE IF NOT EXISTS transactions (
  id BIGSERIAL PRIMARY KEY,
  order_no INT NOT NULL,
  branch_id BIGINT REFERENCES branches(id),
  cashier_id UUID REFERENCES user_profiles(id),
  customer_id BIGINT REFERENCES customers(id),
  customer_name TEXT,
  total_amount INT NOT NULL,
  amount_paid INT NOT NULL,
  change_amount INT DEFAULT 0,
  payment_method TEXT NOT NULL CHECK (payment_method IN ('cash', 'debit', 'credit', 'qris', 'e_wallet')),
  status TEXT NOT NULL DEFAULT 'completed' CHECK (status IN ('completed', 'pending', 'cancelled', 'refunded')),
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 9. TABEL TRANSACTION ITEMS (Item dalam Transaksi)
CREATE TABLE IF NOT EXISTS transaction_items (
  id BIGSERIAL PRIMARY KEY,
  transaction_id BIGINT REFERENCES transactions(id) ON DELETE CASCADE,
  product_id BIGINT REFERENCES products(id),
  product_name TEXT NOT NULL,
  quantity INT NOT NULL,
  unit_price INT NOT NULL,
  total_price INT NOT NULL,
  is_home_visit BOOLEAN DEFAULT FALSE,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 10. TABEL SPLIT PAYMENTS (Pembayaran Berganda - untuk 1 transaksi多种 metode)
CREATE TABLE IF NOT EXISTS split_payments (
  id BIGSERIAL PRIMARY KEY,
  transaction_id BIGINT REFERENCES transactions(id) ON DELETE CASCADE,
  payment_method TEXT NOT NULL CHECK (payment_method IN ('cash', 'debit', 'credit', 'qris', 'e_wallet')),
  amount INT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 11. TABEL HELD ORDERS (Pesanan Ditahan)
CREATE TABLE IF NOT EXISTS held_orders (
  id BIGSERIAL PRIMARY KEY,
  branch_id BIGINT REFERENCES branches(id),
  cashier_id UUID REFERENCES user_profiles(id),
  items JSONB NOT NULL,
  notes TEXT,
  customer_name TEXT,
  hold_order_status TEXT NOT NULL DEFAULT 'active',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 12. TABEL REFUNDS (Pengembalian Dana)
CREATE TABLE IF NOT EXISTS refunds (
  id BIGSERIAL PRIMARY KEY,
  transaction_id BIGINT REFERENCES transactions(id) ON DELETE CASCADE,
  cashier_id UUID REFERENCES user_profiles(id),
  reason TEXT NOT NULL,
  refund_amount INT NOT NULL,
  refund_method TEXT NOT NULL CHECK (refund_method IN ('cash', 'transfer', 'qris')),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 13. TABEL INVENTORY MOVEMENTS (Perubahan Stok)
CREATE TABLE IF NOT EXISTS inventory_movements (
  id BIGSERIAL PRIMARY KEY,
  product_id BIGINT REFERENCES products(id) ON DELETE CASCADE,
  quantity_change INT NOT NULL,
  movement_type TEXT NOT NULL CHECK (movement_type IN ('sale', 'purchase', 'adjustment', 'return')),
  reference_id BIGINT,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 14. TABEL DAILY SUMMARIES (Ringkasan Harian)
CREATE TABLE IF NOT EXISTS daily_summaries (
  id BIGSERIAL PRIMARY KEY,
  branch_id BIGINT REFERENCES branches(id),
  date DATE NOT NULL,
  total_transactions INT DEFAULT 0,
  total_revenue BIGINT DEFAULT 0,
  total_cash BIGINT DEFAULT 0,
  total_debit BIGINT DEFAULT 0,
  total_credit BIGINT DEFAULT 0,
  total_qris BIGINT DEFAULT 0,
  total_e_wallet BIGINT DEFAULT 0,
  total_refunds BIGINT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(branch_id, date)
);

-- 15. TABEL ACTIVITY LOGS (Log Aktivitas Pengguna)
CREATE TABLE IF NOT EXISTS activity_logs (
  id BIGSERIAL PRIMARY KEY,
  user_id UUID REFERENCES user_profiles(id),
  action TEXT NOT NULL,
  details JSONB,
  ip_address TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- TRIGGER: Auto-log activity ketika transaksi dibuat
-- ============================================================
CREATE OR REPLACE FUNCTION log_transaction_insert()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.activity_logs (user_id, action, details)
  VALUES (
    NEW.cashier_id,
    'transaksi_baru',
    jsonb_build_object(
      'order_no', NEW.order_no,
      'total', NEW.total_amount,
      'payment', NEW.payment_method
    )
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_transaction_insert ON public.transactions;
CREATE TRIGGER on_transaction_insert
  AFTER INSERT ON public.transactions
  FOR EACH ROW EXECUTE FUNCTION log_transaction_insert();

-- ============================================================
-- TRIGGER: Auto-log activity ketika refund dibuat
-- ============================================================
CREATE OR REPLACE FUNCTION log_refund_insert()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.activity_logs (user_id, action, details)
  VALUES (
    NEW.cashier_id,
    'refund_baru',
    jsonb_build_object(
      'transaction_id', NEW.transaction_id,
      'amount', NEW.refund_amount,
      'reason', NEW.reason
    )
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_refund_insert ON public.refunds;
CREATE TRIGGER on_refund_insert
  AFTER INSERT ON public.refunds
  FOR EACH ROW EXECUTE FUNCTION log_refund_insert();

-- ============================================================
-- TRIGGER: Auto-update updated_at
-- ============================================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply trigger ke semua tabel yang punya updated_at
DO $$
DECLARE
  tbl TEXT;
BEGIN
  FOR tbl IN
    SELECT table_name FROM information_schema.columns
    WHERE column_name = 'updated_at'
      AND table_schema = 'public'
      AND table_name NOT LIKE 'pg_%'
      AND table_name NOT LIKE '_%'
  LOOP
    EXECUTE format(
      'DROP TRIGGER IF EXISTS set_updated_at ON %I; CREATE TRIGGER set_updated_at BEFORE UPDATE ON %I FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();',
      tbl, tbl
    );
  END LOOP;
END;
$$ LANGUAGE plpgsql;

-- ============================================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================================

-- Aktifkan RLS di semua tabel
ALTER TABLE branches ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE product_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE product_variants ENABLE ROW LEVEL SECURITY;
ALTER TABLE customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE transaction_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE split_payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE held_orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE refunds ENABLE ROW LEVEL SECURITY;
ALTER TABLE inventory_movements ENABLE ROW LEVEL SECURITY;
ALTER TABLE daily_summaries ENABLE ROW LEVEL SECURITY;
ALTER TABLE activity_logs ENABLE ROW LEVEL SECURITY;

-- Policy: Semua user bisa membaca produk aktif
CREATE POLICY "Produk bisa dibaca semua user" ON products
  FOR SELECT USING (true);

-- Policy: Hanya admin yang bisa insert/update/delete produk
CREATE POLICY "Admin bisa insert produk" ON products
  FOR INSERT WITH CHECK (
    EXISTS (SELECT 1 FROM user_profiles up
      JOIN user_roles ur ON up.role_id = ur.id
      WHERE up.id = auth.uid() AND ur.name = 'admin')
  );

CREATE POLICY "Admin bisa update produk" ON products
  FOR UPDATE USING (
    EXISTS (SELECT 1 FROM user_profiles up
      JOIN user_roles ur ON up.role_id = ur.id
      WHERE up.id = auth.uid() AND ur.name = 'admin')
  );

CREATE POLICY "Admin bisa delete produk" ON products
  FOR DELETE USING (
    EXISTS (SELECT 1 FROM user_profiles up
      JOIN user_roles ur ON up.role_id = ur.id
      WHERE up.id = auth.uid() AND ur.name = 'admin')
  );

-- Policy: Transaksi - semua user bisa membaca
CREATE POLICY "Semua user bisa baca transaksi" ON transactions
  FOR SELECT USING (true);

-- Policy: Refunds - semua user bisa insert
CREATE POLICY "Semua user bisa insert refunds" ON refunds
  FOR INSERT WITH CHECK (true);

-- Policy: Transaksi - semua user bisa insert
CREATE POLICY "Semua user bisa insert transaksi" ON transactions
  FOR INSERT WITH CHECK (true);

-- Policy: Transaksi - semua user bisa update
CREATE POLICY "Semua user bisa update transaksi" ON transactions
  FOR UPDATE USING (true);

-- Policy: Transaction items - semua user bisa insert
CREATE POLICY "Semua user bisa insert transaction_items" ON transaction_items
  FOR INSERT WITH CHECK (true);

-- Policy: Transaction items - semua user bisa select
CREATE POLICY "Semua user bisa baca transaction_items" ON transaction_items
  FOR SELECT USING (true);

-- Policy: Held orders - semua user authenticated bisa insert
CREATE POLICY "User bisa insert held orders" ON held_orders
  FOR INSERT WITH CHECK (auth.role() = 'authenticated');

-- Policy: Held orders - semua user authenticated bisa select
CREATE POLICY "User bisa select held orders" ON held_orders
  FOR SELECT USING (auth.role() = 'authenticated');

-- Policy: Held orders - semua user authenticated bisa update
CREATE POLICY "User bisa update held orders" ON held_orders
  FOR UPDATE USING (auth.role() = 'authenticated');

-- Policy: Held orders - semua user authenticated bisa delete
CREATE POLICY "User bisa delete held orders" ON held_orders
  FOR DELETE USING (auth.role() = 'authenticated');

-- Policy: Branch bisa dibaca semua user
CREATE POLICY "Branch bisa dibaca semua user" ON branches
  FOR SELECT USING (true);

-- Policy: User profiles bisa dibaca oleh semua user yang terautentikasi
CREATE POLICY "User bisa baca profile" ON user_profiles
  FOR SELECT USING (auth.role() = 'authenticated');

-- Policy: Trigger bisa insert user_profiles (dari auth.users trigger)
CREATE POLICY "Trigger bisa insert user_profiles" ON user_profiles
  FOR INSERT WITH CHECK (true);

-- ============================================================
-- INSERT DATA PRODUK AWAL (Dari Excel)
-- ============================================================
INSERT INTO products (item_no, name, price_clinic, price_home_visit, category_id, category) VALUES
  (1,  'Bekam Basah Per-Titik',              6000,   8000,   (SELECT id FROM product_categories WHERE name = 'Bekam'),    'Bekam'),
  (2,  'Bekam Kering Per-Titik',             4000,   6000,   (SELECT id FROM product_categories WHERE name = 'Bekam'),    'Bekam'),
  (3,  'Bekam Kepala Per-Titik',             30000,  45000,  (SELECT id FROM product_categories WHERE name = 'Bekam'),    'Bekam'),
  (4,  'Bekam Basah 11 Titik',               66000,  88000,  (SELECT id FROM product_categories WHERE name = 'Bekam'),    'Bekam'),
  (5,  'Bekam Basah 19 Titik',               114000, 152000, (SELECT id FROM product_categories WHERE name = 'Bekam'),    'Bekam'),
  (6,  'Bekam Basah 21 Titik',               126000, 168000, (SELECT id FROM product_categories WHERE name = 'Bekam'),    'Bekam'),
  (7,  'Bekam Basah 23 Titik',               138000, 184000, (SELECT id FROM product_categories WHERE name = 'Bekam'),    'Bekam'),
  (8,  'Bekam Basah 33 Titik',               198000, 264000, (SELECT id FROM product_categories WHERE name = 'Bekam'),    'Bekam'),
  (9,  'Pengobatan Holystik (Pijit Syaraf, Bekam & Refleksi)', 300000, 450000, (SELECT id FROM product_categories WHERE name = 'Terapi'),   'Terapi'),
  (10, 'Gurah Hidung',                       150000, 225000, (SELECT id FROM product_categories WHERE name = 'Terapi'),   'Terapi'),
  (11, 'Gurah Mata',                         50000,  75000,  (SELECT id FROM product_categories WHERE name = 'Terapi'),   'Terapi'),
  (12, 'Gurah Telinga',                      50000,  75000,  (SELECT id FROM product_categories WHERE name = 'Terapi'),   'Terapi'),
  (13, 'Refleksi & Rendam Kaki',             80000,  120000, (SELECT id FROM product_categories WHERE name = 'Terapi'),   'Terapi'),
  (14, 'Pijat Urut Anak',                    100000, 150000, (SELECT id FROM product_categories WHERE name = 'Terapi'),   'Terapi'),
  (15, 'Pijat Urut Dewasa & Rendam Kaki',    150000, 225000, (SELECT id FROM product_categories WHERE name = 'Terapi'),   'Terapi'),
  (16, 'Pijat Syaraf & Rendam Kaki/ Pengobatan', 175000, 262500, (SELECT id FROM product_categories WHERE name = 'Terapi'),   'Terapi'),
  (17, 'Pijat Syaraf Stroke',                200000, 300000, (SELECT id FROM product_categories WHERE name = 'Terapi'),   'Terapi'),
  (18, 'Pijat Kretek (Kiropraktik/Chiropraktik)', 150000, 225000, (SELECT id FROM product_categories WHERE name = 'Terapi'),   'Terapi'),
  (19, 'Totok Syaraf Cinta & Rendam Kaki',   250000, 375000, (SELECT id FROM product_categories WHERE name = 'Terapi'),   'Terapi'),
  (21, 'Totok Wajah',                        100000, 150000, (SELECT id FROM product_categories WHERE name = 'Perawatan'), 'Perawatan'),
  (25, 'Lulur',                              120000, 180000, (SELECT id FROM product_categories WHERE name = 'Perawatan'), 'Perawatan'),
  (26, 'Akupunktur',                         250000, 375000, (SELECT id FROM product_categories WHERE name = 'Terapi'),   'Terapi'),
  (27, 'Herbal Kapsul BSA',                  110000, NULL,   (SELECT id FROM product_categories WHERE name = 'Herbal'),   'Herbal'),
  (28, 'Herbal Pembangkit Energi',           180000, NULL,   (SELECT id FROM product_categories WHERE name = 'Herbal'),   'Herbal')
ON CONFLICT (item_no) DO NOTHING;

-- Update produk yang sudah ada (jika kolom category kosong)
UPDATE products SET category = 'Bekam'    WHERE category IS NULL AND item_no BETWEEN 1 AND 8;
UPDATE products SET category = 'Terapi'   WHERE category IS NULL AND item_no IN (9,10,11,12,13,14,15,16,17,18,19,26);
UPDATE products SET category = 'Perawatan' WHERE category IS NULL AND item_no IN (21,25);
UPDATE products SET category = 'Herbal'   WHERE category IS NULL AND item_no IN (27,28);

-- ============================================================
-- FUNGSI: Generate daily summary (jalankan setiap hari via cron/scheduler)
-- ============================================================
CREATE OR REPLACE FUNCTION generate_daily_summary(target_date DATE DEFAULT CURRENT_DATE)
RETURNS void AS $$
BEGIN
  INSERT INTO daily_summaries (branch_id, date, total_transactions, total_revenue,
    total_cash, total_debit, total_credit, total_qris, total_e_wallet, total_refunds)
  SELECT
    t.branch_id,
    target_date,
    COUNT(DISTINCT t.id) AS total_transactions,
    COALESCE(SUM(t.total_amount), 0) AS total_revenue,
    COALESCE(SUM(CASE WHEN t.payment_method = 'cash' THEN t.amount_paid ELSE 0 END), 0) AS total_cash,
    COALESCE(SUM(CASE WHEN t.payment_method = 'debit' THEN t.amount_paid ELSE 0 END), 0) AS total_debit,
    COALESCE(SUM(CASE WHEN t.payment_method = 'credit' THEN t.amount_paid ELSE 0 END), 0) AS total_credit,
    COALESCE(SUM(CASE WHEN t.payment_method = 'qris' THEN t.amount_paid ELSE 0 END), 0) AS total_qris,
    COALESCE(SUM(CASE WHEN t.payment_method = 'e_wallet' THEN t.amount_paid ELSE 0 END), 0) AS total_e_wallet,
    COALESCE((SELECT SUM(refund_amount) FROM refunds r JOIN transactions t2 ON r.transaction_id = t2.id WHERE DATE(t2.created_at) = target_date), 0) AS total_refunds
  FROM transactions t
  WHERE DATE(t.created_at) = target_date AND t.status = 'completed'
  GROUP BY t.branch_id
  ON CONFLICT (branch_id, date)
  DO UPDATE SET
    total_transactions = EXCLUDED.total_transactions,
    total_revenue = EXCLUDED.total_revenue,
    total_cash = EXCLUDED.total_cash,
    total_debit = EXCLUDED.total_debit,
    total_credit = EXCLUDED.total_credit,
    total_qris = EXCLUDED.total_qris,
    total_e_wallet = EXCLUDED.total_e_wallet,
    total_refunds = EXCLUDED.total_refunds;
END;
$$ LANGUAGE plpgsql;
