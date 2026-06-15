-- =============================================================
-- Tabel: cashier_shifts
-- Untuk: Laporan Tutup Kasir (Closing Report)
-- =============================================================
CREATE TABLE IF NOT EXISTS cashier_shifts (
  id BIGSERIAL PRIMARY KEY,
  cashier_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  branch_id BIGINT REFERENCES branches(id) ON DELETE SET NULL,
  modal_awal INTEGER DEFAULT 0,
  waktu_buka TIMESTAMPTZ,
  waktu_tutup TIMESTAMPTZ,
  tanggal DATE DEFAULT CURRENT_DATE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Trigger: auto update updated_at
CREATE OR REPLACE FUNCTION update_cashier_shifts_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS on_cashier_shifts_updated ON cashier_shifts;
CREATE TRIGGER on_cashier_shifts_updated
  BEFORE UPDATE ON cashier_shifts
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Indexes
CREATE INDEX IF NOT EXISTS idx_cashier_shifts_tanggal ON cashier_shifts(tanggal);
CREATE INDEX IF NOT EXISTS idx_cashier_shifts_cashier ON cashier_shifts(cashier_id);

-- Row Level Security (RLS)
ALTER TABLE cashier_shifts ENABLE ROW LEVEL SECURITY;

-- Policy: semua user yang terautentikasi bisa baca
CREATE POLICY "Authenticated users can read cashier_shifts"
  ON cashier_shifts FOR SELECT
  USING (auth.role() = 'authenticated');

-- Policy: user bisa insert shift miliknya sendiri
CREATE POLICY "Users can insert their own shifts"
  ON cashier_shifts FOR INSERT
  WITH CHECK (cashier_id = auth.uid() OR auth.role() = 'authenticated');

-- Policy: user bisa update shift miliknya sendiri
CREATE POLICY "Users can update their own shifts"
  ON cashier_shifts FOR UPDATE
  USING (cashier_id = auth.uid());

-- =============================================================
-- View: products_sold_per_day (opsional, untuk aggregasi)
-- =============================================================
CREATE OR REPLACE VIEW products_sold_per_day AS
SELECT
  DATE(ti.created_at) AS tanggal,
  ti.product_id,
  ti.product_name,
  ti.is_home_visit,
  SUM(ti.quantity) AS total_qty,
  SUM(ti.total_price) AS total_amount
FROM transaction_items ti
JOIN transactions t ON t.id = ti.transaction_id
WHERE t.status = 'completed'
GROUP BY DATE(ti.created_at), ti.product_id, ti.product_name, ti.is_home_visit
ORDER BY tanggal DESC, total_amount DESC;
