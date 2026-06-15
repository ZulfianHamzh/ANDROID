-- ============================================================
-- FIX: Hapus trigger 'handle_new_user' yang salah terpasang di activity_logs
-- ============================================================

-- 1. Hapus trigger yang salah pada activity_logs
DROP TRIGGER IF EXISTS "User" ON activity_logs;

-- 2. Pastikan trigger yang benar ada di auth.users
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
