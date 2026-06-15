-- ============================================================
-- DIAGNOSTIK: Cari penyebab error raw_user_meta_data
-- ============================================================

-- 1. Cek SEMUA trigger di public.transactions
SELECT 
  tgname AS trigger_name,
  pg_get_triggerdef(t.oid) AS trigger_definition
FROM pg_trigger t
JOIN pg_class c ON t.tgrelid = c.oid
JOIN pg_namespace n ON c.relnamespace = n.oid
WHERE c.relname = 'transactions'
  AND n.nspname = 'public'
  AND t.tgname NOT LIKE 'pg_%';

-- 2. Cek definisi fungsi handle_new_user yang sebenarnya
SELECT 
  p.proname AS function_name,
  pg_get_functiondef(p.oid) AS function_definition
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE p.proname = 'handle_new_user'
  AND n.nspname = 'public';

-- 3. Cari SEMUA fungsi/trigger yang mengandung kata 'raw_user_meta_data'
SELECT 
  proname AS function_name,
  nspname AS schema_name
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE prosrc LIKE '%raw_user_meta_data%';

-- 4. Cek foreign key constraints transactions -> user_profiles
SELECT
  conname AS constraint_name,
  pg_get_constraintdef(c.oid) AS constraint_definition
FROM pg_constraint c
JOIN pg_class t ON c.conrelid = t.oid
WHERE t.relname = 'transactions'
  AND c.contype = 'f';

-- 5. Cek apakah ada trigger on update/insert di user_profiles
SELECT 
  tgname AS trigger_name,
  pg_get_triggerdef(t.oid) AS trigger_definition
FROM pg_trigger t
JOIN pg_class c ON t.tgrelid = c.oid
WHERE c.relname = 'user_profiles'
  AND t.tgname NOT LIKE 'pg_%';
