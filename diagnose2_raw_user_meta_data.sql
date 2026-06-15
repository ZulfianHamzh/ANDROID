-- ============================================================
-- DIAGNOSTIK LANJUTAN: Cari sumber error raw_user_meta_data
-- ============================================================

-- 1. Cek apakah kolom 'raw_user_meta_data' ADA di auth.users
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_schema = 'auth' 
  AND table_name = 'users' 
  AND column_name = 'raw_user_meta_data';

-- 2. Cek SEMUA generated columns di public schema
SELECT 
  table_name, 
  column_name, 
  is_generated,
  generation_expression
FROM information_schema.columns 
WHERE table_schema = 'public' 
  AND is_generated = 'ALWAYS';

-- 3. Cek apakah ada policy/rule di transactions yang pakai fungsi
SELECT
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual,
  with_check
FROM pg_policies
WHERE tablename = 'transactions';

-- 4. Cek semua default value di kolom transactions
SELECT 
  column_name, 
  column_default 
FROM information_schema.columns 
WHERE table_schema = 'public' 
  AND table_name = 'transactions'
  AND column_default IS NOT NULL;

-- 5. Cek apakah ada publication/replication yg related
SELECT * FROM pg_publication_tables 
WHERE schemaname = 'public' AND tablename = 'transactions';
