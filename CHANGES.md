# Perubahan untuk DHBH POS

## 1. Role Baru: `karyawan`

### Database
- Tabel `user_roles` ditambahkan role baru: `karyawan` (id: 3)
- Role `admin`, `kasir`, `karyawan`

### Dampak ke Flutter App
- Tidak ada perubahan — trigger `handle_new_user()` sudah support role dari `raw_user_meta_data`
- Saat register via Dashboard (Next.js), role otomatis terisi
- **Login offline** tetap berfungsi karena SQLite menyimpan role_id

---

## 2. Harga Produk per Cabang

### Database — Tabel Baru
```sql
CREATE TABLE public.product_branch_prices (
  id              BIGSERIAL PRIMARY KEY,
  product_id      BIGINT NOT NULL REFERENCES public.products(id) ON DELETE CASCADE,
  branch_id       BIGINT NOT NULL REFERENCES public.branches(id) ON DELETE CASCADE,
  price_clinic    INTEGER,        -- null = pakai harga default produk
  price_home_visit INTEGER,       -- null = pakai harga default produk
  created_at      TIMESTAMPTZ DEFAULT now(),
  updated_at      TIMESTAMPTZ DEFAULT now(),
  UNIQUE(product_id, branch_id)
);
```

### RLS Policy
```sql
-- Semua user bisa baca
CREATE POLICY "Semua user bisa baca product_branch_prices"
ON public.product_branch_prices FOR SELECT TO public USING (true);

-- Admin bisa insert/update/delete
CREATE POLICY "Admin bisa kelola product_branch_prices"
ON public.product_branch_prices FOR ALL TO public
USING (
  EXISTS (
    SELECT 1 FROM user_profiles up
    JOIN user_roles ur ON ur.id = up.role_id
    WHERE up.id = auth.uid() AND ur.name = 'admin'
  )
);
```

### 🔄 Perubahan yang Diperlukan di Flutter App

#### a. Model — `ProductBranchPrice`
Buat model baru:
```dart
class ProductBranchPrice {
  final int id;
  final int productId;
  final int branchId;
  final int? priceClinic;
  final int? priceHomeVisit;
}
```

#### b. Query Produk — Harus LEFT JOIN `product_branch_prices`

**Sebelum:**
```dart
final response = await supabase
  .from('products')
  .select('*')
  .eq('is_active', true);
```

**Sesudah:**
```dart
final response = await supabase
  .from('products')
  .select('''
    *,
    branch_prices:product_branch_prices!left(
      price_clinic,
      price_home_visit
    )
  ''')
  .eq('is_active', true)
  .eq('product_branch_prices.branch_id', currentBranchId);
```

Atau query terpisah untuk mengambil branch prices, lalu digabung di JavaScript/Dart.

#### c. Effective Price Logic
Di setiap tempat yang menampilkan harga, gunakan **COALESCE**:

```dart
int getEffectivePriceClinic(Product product, int branchId) {
  final branchPrice = product.branchPrices?.firstWhere(
    (bp) => bp.branchId == branchId,
    orElse: () => null,
  );
  return branchPrice?.priceClinic ?? product.priceClinic;
}

int getEffectivePriceHomeVisit(Product product, int branchId) {
  final branchPrice = product.branchPrices?.firstWhere(
    (bp) => bp.branchId == branchId,
    orElse: () => null,
  );
  return branchPrice?.priceHomeVisit ?? product.priceHomeVisit;
}
```

#### d. Tempat yang Perlu Diupdate

| File | Bagian | Perubahan |
|------|--------|-----------|
| `models/product.dart` | Model Product | Tambah field `branchPrices` |
| `services/cache_service.dart` | `fetchProducts()` | Update query + cache |
| `services/supabase_service.dart` | `fetchProducts()` | Update query dengan LEFT JOIN |
| `screens/pos_screen.dart` | Tampilan harga | Pakai `getEffectivePrice()` |
| `widgets/product_card.dart` | Card produk | Pakai `getEffectivePrice()` |
| `widgets/cart_item_card.dart` | Cart item | Pakai `getEffectivePrice()` |
| `providers/pos_provider.dart` | `addToCart()` | Simpan unit_price dari effective price |
| `services/local_database_service.dart` | `cached_products` | Update schema (tambah branch price) |

#### e. Flow Transaksi — Tidak Berubah
`transaction_items.unit_price` sudah menyimpan **harga saat transaksi**, jadi tidak perlu diubah. Yang berubah hanya cara **menentukan harga sebelum checkout**.

---

## 3. RLS Policy Fixes

### Masalah
Beberapa tabel hanya punya policy untuk role `{anon}` — user login (`authenticated`) tidak bisa membaca/menulis.

### Tabel yang Diperbaiki

| Tabel | Perubahan |
|-------|-----------|
| `user_roles` | ✅ Policy SELECT untuk `{public}` |
| `customers` | ✅ Policy SELECT untuk `{public}` |
| `daily_summaries` | ✅ Policy SELECT untuk `{public}` |
| `product_categories` | ✅ Policy SELECT untuk `{public}` |
| `product_variants` | ✅ Policy SELECT untuk `{public}` |
| `split_payments` | ✅ Policy SELECT untuk `{public}` |
| `inventory_movements` | ✅ Policy SELECT untuk `{public}` |
| `user_profiles` | ✅ Policy UPDATE untuk user sendiri + admin |

### Dampak ke Flutter App
- **Tidak ada perubahan** — semua query yang sudah ada tetap berfungsi
- Ini hanya memperbaiki query yang sebelumnya gagal (silent error) di authenticated context

---

## 4. Ringkasan Migration SQL

| # | Nama Migration | Tujuan |
|---|---------------|--------|
| 1 | `add_karyawan_role` | Tambah role `karyawan` |
| 2 | `fix_user_roles_rls_for_authenticated` | Fix RLS `user_roles` |
| 3 | `fix_rls_for_authenticated_users` | Fix RLS 6 tabel |
| 4 | `fix_user_profiles_update_policy` | Fix RLS UPDATE `user_profiles` |
| 5 | Buat tabel `product_branch_prices` + RLS | Harga per cabang |

### Catatan untuk Flutter Developer
- **Prioritas tinggi**: Implementasi harga per cabang (item 2a-2e)
- **Tidak urgent**: Fix RLS (tidak mempengaruhi Flutter karena semua query sudah berjalan via anon key atau tidak ada error yang terlihat)
- **Role karyawan**: Tidak perlu perubahan di Flutter — trigger handle_new_user() sudah support
