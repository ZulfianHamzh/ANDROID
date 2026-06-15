-- ============================================================
-- FIX: Trigger 'handle_new_user' salah menempel di tabel lain
-- ============================================================

-- 1. Cari SEMUA trigger yang pakai fungsi handle_new_user
SELECT 
  tgname AS trigger_name,
  relname AS table_name,
  nspname AS schema_name
FROM pg_trigger t
JOIN pg_class c ON t.tgrelid = c.oid
JOIN pg_namespace n ON c.relnamespace = n.oid
WHERE tgname = 'on_auth_user_created';

-- 2. Hapus trigger dari tabel yang SALAH (bukan auth.users)
-- (Ulangi untuk setiap tabel yang muncul dari query di atas selain auth.users)
DROP TRIGGER IF EXISTS on_auth_user_created ON public.transactions;
DROP TRIGGER IF EXISTS on_auth_user_created ON public.user_profiles;
DROP TRIGGER IF EXISTS on_auth_user_created ON public.products;

-- 3. Pastikan trigger yang benar hanya ada di auth.users
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 4. Verifikasi
SELECT 
  tgname AS trigger_name,
  relname AS table_name,
  nspname AS schema_name
FROM pg_trigger t
JOIN pg_class c ON t.tgrelid = c.oid
JOIN pg_namespace n ON c.relnamespace = n.oid
WHERE tgname = 'on_auth_user_created';
