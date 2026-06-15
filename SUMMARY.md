# DHBH POS — Complete Application Summary

**Version:** 1.0.0  
**Platform:** Android (Flutter)  
**Backend:** Supabase (PostgreSQL)  
**State Management:** Riverpod  
**Target Device:** 8-inch Tablet (800×1280, 16:10)

---

## 📁 Project Structure

```
lib/
├── config/
│   └── supabase_config.dart          # Supabase URL & Anon Key
├── models/
│   ├── cart_item.dart                # Cart item model (product + qty + price type)
│   ├── held_order.dart               # Held/paused order model
│   ├── product.dart                  # Product model (clinic & home visit prices)
│   ├── transaction.dart              # Transaction model + enums (status, payment, print)
│   └── user.dart                     # AppUser model (admin/kasir roles)
├── services/
│   ├── bluetooth_service.dart        # Bluetooth singleton — scan, connect, send data
│   ├── cache_service.dart            # Cache layer — fetch with Supabase→SQLite fallback + syncAllToLocal()
│   ├── local_database_service.dart   # SQLite local database (6 tables + CRUD + held order management)
│   ├── supabase_service.dart         # Supabase API — auth, products, transactions, reports, closing report
│   ├── sync_service.dart             # Background sync engine for offline queue
│   └── thermal_printer_service.dart  # ESC/POS receipt generation & printing + closing report
├── providers/
│   ├── bluetooth_provider.dart       # Bluetooth connection status, devices stream
│   ├── connectivity_provider.dart    # Network connectivity stream (online/offline)
│   ├── pos_provider.dart             # Main POS state (auth, cart, transactions, products, print)
│   ├── sync_provider.dart            # Sync state (idle/syncing/pending/error)
│   └── thermal_printer_provider.dart # Printer service provider
├── screens/
│   ├── login_screen.dart             # Login (online + offline fallback)
│   ├── register_screen.dart          # Admin — register new account
│   ├── main_app_screen.dart          # Main shell with 3-tab layout + AppBar
│   ├── pos_screen.dart               # POS tab — search, categories, product grid, cart
│   ├── history_screen.dart           # History tab — transaction list + refund + reprint
│   └── menu_screen.dart              # Menu tab — daily summary, closing report, transactions, logs
├── utils/
│   ├── app_theme.dart                # Colors, typography
│   ├── network_utils.dart            # DNS check, connectivity check
│   └── responsive_utils.dart         # Responsive scaling for 800×1280 tablet
├── widgets/
│   ├── bluetooth_connection_dialog.dart  # Bluetooth pairing dialog
│   ├── bluetooth_status_widget.dart     # Printer status in AppBar
│   ├── cart_item_card.dart              # Cart item row widget
│   ├── connectivity_banner.dart         # Offline/online/pending sync banner
│   ├── payment_dialog.dart              # Payment method dialog
│   ├── product_card.dart                # Product grid card widget
│   ├── skeleton_widget.dart             # Loading skeleton
│   └── sync_status_widget.dart          # Sync badge in AppBar
└── main.dart                         # App entry — init DB, BT, Supabase
```

---

## 🔐 Authentication

### Flow
1. **App startup** → Clear session (auto-logout), init local DB & Bluetooth
2. **Login screen** → User enters email + password
3. **Online:** Supabase `signInWithPassword()` → fetch user profile → cache to SQLite
4. **Offline fallback:** Search `offline_accounts` table in SQLite → verify password locally → login
5. **Login success** → Navigate to `MainAppScreen`
6. **App restart** → Session cleared → show login screen again

### Roles
| Role | Access |
|------|--------|
| `admin` | Full access — all menu sections, CRUD products, activity logs |
| `kasir` | Limited — POS, history, daily summary, closing report, transactions list |

---

## 🖥️ Screens

### 1. Login Screen (`login_screen.dart`)
- Email + password form
- Online login (Supabase auth)
- Offline fallback (SQLite cached accounts via `offlineLogin()`)
- **Akun tersimpan** — daftar akun yang pernah login, tap untuk autofill email
- Offline login hanya perlu masukkan password (email terisi otomatis)

### 2. Main App Screen (`main_app_screen.dart`)
- **AppBar:** Logo + branch name | Transaction badge | Sync status | Bluetooth status | User profile
- **Connectivity Banner:** Red (offline) / Orange (pending sync) / Hidden (online+synced)
- **3 Tabs:** POS | History | Menu
- **Bottom Nav:** Tab bar with icons
- **Auto-refresh** on tab switch via `TabBar.onTap`

### 3. POS Screen (`pos_screen.dart`)
- **Search bar** — filter products by name
- **Category chips** — horizontal scrollable filter
- **Product grid** — 2 cols (phone) / 3 cols (tablet) with price display
- **Cart panel (tablet)** / **Cart footer (phone)** — items list, qty controls, total, checkout button
- **Payment dialog** — Cash / Debit / Credit / QRIS / E-Wallet + amount input + customer name
- **Hold order** — pause current cart
- **Auto-print** receipt after successful transaction (if BT printer connected)
- **Pull-to-refresh**

### 4. History Screen (`history_screen.dart`)
- Transaction list (reversed chronological)
- **Expanded card:** items detail, customer, payment breakdown, print status
- **Print status badge:** printed (green) / unprinted (grey) / failed (orange)
- **Refund button** (admin: red)
- **Print Again / Make a Copy** button — reprint via Bluetooth
- **Pull-to-refresh**

### 5. Menu Screen (`menu_screen.dart`)
- **Ringkasan Harian** — Daily summary card (total transactions, revenue per payment method)
  - [🖨️ Print Ringkasan] button
- **Laporan Tutup Kasir** — Closing report section:
  - 📅 Date picker + 💰 Modal Awal input + [🖨️ Print] button
  - Products sold list (name, qty, total)
  - Payment breakdown per method
  - Transaction counts (completed, held)
- **Transaksi** — All transactions table (20 per page)
- **Aktivitas Harian** (admin only) — Activity logs
- **Pull-to-refresh**

---

## 🗄️ Database

### Supabase (PostgreSQL)

#### `branches`
| Column | Type | Notes |
|--------|------|-------|
| id | int8 PK | |
| name | text | |
| address | text | nullable |
| phone | text | nullable |
| is_active | bool | nullable |
| created_at | timestamptz | |
| updated_at | timestamptz | trigger auto |

#### `user_roles`
| Column | Type | Notes |
|--------|------|-------|
| id | int8 PK | |
| name | text | unique ('admin', 'kasir') |
| description | text | nullable |

#### `user_profiles`
| Column | Type | Notes |
|--------|------|-------|
| id | uuid PK | references auth.users |
| username | text | unique |
| full_name | text | |
| role_id | int8 | references user_roles |
| branch_id | int8 | nullable, references branches |
| fingerprints | text | nullable |
| is_active | bool | default true |

#### `products`
| Column | Type | Notes |
|--------|------|-------|
| id | int8 PK | |
| item_no | int4 | unique, nullable |
| category_id | int8 | nullable |
| category | text | nullable |
| name | text | |
| description | text | nullable |
| price_clinic | int4 | |
| price_home_visit | int4 | nullable |
| image_url | text | nullable |
| is_active | bool | default true |

#### `transactions`
| Column | Type | Notes |
|--------|------|-------|
| id | int8 PK | |
| order_no | int4 | |
| branch_id | int8 | nullable |
| cashier_id | uuid | nullable |
| customer_id | int8 | nullable |
| customer_name | text | nullable |
| total_amount | int4 | |
| amount_paid | int4 | |
| change_amount | int4 | nullable |
| payment_method | text | cash/debit/credit/qris/e_wallet |
| status | text | completed/pending/cancelled/refunded |
| notes | text | nullable |
| print_status | text | printed/unprinted/failed/pending |
| created_at | timestamptz | |
| updated_at | timestamptz | trigger auto |

#### `transaction_items`
| Column | Type | Notes |
|--------|------|-------|
| id | int8 PK | |
| transaction_id | int8 | nullable |
| product_id | int8 | nullable |
| product_name | text | |
| quantity | int4 | |
| unit_price | int4 | |
| total_price | int4 | |
| is_home_visit | bool | nullable |
| notes | text | nullable |

#### `held_orders`
| Column | Type | Notes |
|--------|------|-------|
| id | int8 PK | |
| branch_id | int8 | nullable |
| cashier_id | uuid | nullable |
| items | jsonb | |
| notes | text | nullable |
| customer_name | text | nullable |
| hold_order_status | text | active/completed |
| created_at | timestamptz | |
| updated_at | timestamptz | trigger auto |

#### `cashier_shifts`
| Column | Type | Notes |
|--------|------|-------|
| id | bigint PK | auto-increment |
| cashier_id | uuid | nullable, references auth.users |
| branch_id | bigint | nullable, references branches |
| modal_awal | integer | default 0 |
| waktu_buka | timestamptz | nullable |
| waktu_tutup | timestamptz | nullable |
| tanggal | date | default current_date |
| created_at | timestamptz | default now() |
| updated_at | timestamptz | trigger auto |

#### Other Tables
- `product_categories`, `product_variants`, `customers`, `split_payments`, `refunds`, `inventory_movements`, `daily_summaries`, `activity_logs`

#### Functions & Triggers
- `handle_new_user()` — auto-create user_profile on auth signup
- `generate_daily_summary()` — aggregate daily transactions
- `log_transaction_insert` / `log_refund_insert` — auto-log to activity_logs
- `update_updated_at_column` — auto-update timestamps

### SQLite (Local — `dhbh_offline.db`)

| Table | Purpose |
|-------|---------|
| `cached_products` | Mirror products (read offline, refresh online) |
| `offline_accounts` | Cached user profiles + email/password for offline login |
| `offline_transactions` | Transactions created while offline |
| `cached_held_orders` | Held orders created while offline |
| `pending_sync` | Queue for actions needing cloud sync |
| `cashier_shifts` | Mirror cashier_shifts (local + sync) |

---

## 🔵 Bluetooth Thermal Printer

### Connection Flow
1. **AppBar** → Tap printer status widget → Open connection dialog
2. **Dialog** → List paired Bluetooth devices → Select → Connect
3. **Status** → Green "Printer" badge when connected

### ESC/POS Receipts

#### Transaction Receipt
```
         DHBH POS
       [Branch Name]
Kasir: nama
Tgl: 11/06/2026 14:30
ID: 123
──────────────────
Item          Qty  Harga
──────────────────
Nama Produk
  (Klinik) @Rp10.000
  x2              Rp20.000

Nama Produk Lain
  (Home Visit) @Rp15.000
  x1              Rp15.000
──────────────────
     Total: Rp35.000
Metode: Cash
Pelanggan: (optional)
──────────────────
   Terima kasih!
Selamat datang kembali
```

#### Closing Report (Laporan Tutup Kasir)
```
     LAPORAN TUTUP KASIR
   PENJUALAN & TRANSAKSI DHBH
Cabang: Nama Cabang
Kasir: Nama Kasir
Waktu Buka: 7:00
Waktu Tutup: 21:00

PRODUK TERJUAL
Nama               Qty  Harga
─────────────────── ─── ────────
Produk A (Klinik)   x2  Rp20.000
Produk B (Home)     x1  Rp15.000
────────────────────────────────
Total: Rp35.000

─────────────────────────────
Modal Awal: Rp100.000

PENERIMAAN
Cash         Rp20.000
Debit        Rp10.000
QRIS         Rp 5.000
────────────────────────────────
Total Penerimaan: Rp35.000
────────────────────────────────
Saldo Akhir: Rp135.000
Transaksi Selesai: 5
Transaksi Hold: 1
Total Item Terjual: 3
────────────────────────────────
       Terima kasih
```

---

## 📡 Offline Support

### Architecture
```
ONLINE:  User Action → Supabase ✓ → SQLite (synced=1) → State
OFFLINE: User Action → Supabase ✗ → SQLite (synced=0) → pending_sync queue → State
                                        ↓ (online kembali)
                                   SyncService → Supabase ✓ → SQLite (synced=1)
```

### What Works Offline
| Feature | Online | Offline |
|---------|--------|---------|
| Login | ✅ Supabase auth | ✅ SQLite cached accounts |
| Products | ✅ Live fetch | ✅ Cached products |
| Create Transaction | ✅ Supabase | ✅ SQLite + queue |
| Held Orders | ✅ Supabase | ✅ SQLite + queue |
| Print Receipt | ✅ Bluetooth | ✅ Bluetooth (local) |
| Closing Report | ✅ Supabase data | ❌ Needs network |
| History | ✅ Supabase | ✅ Cached transactions |
| Daily Summary | ✅ Supabase | ❌ Needs network |

### Sync Queue (`pending_sync`)
- Queue items processed FIFO
- Max 3 retries with exponential backoff (5s, 30s, 2m)
- Failed items marked with error for manual review
- Auto-sync triggered on connectivity change
- Manual sync via **Sync Manual** button (Menu) or tap sync badge (AppBar)

### UI Indicators
| Icon | Status | Action |
|------|--------|--------|
| 🔴 Banner | Offline | Data disimpan lokal |
| 🟡 Banner | Pending sync (N) | Tap "Sync" |
| 🟢 Banner (brief) | Online + synced | Auto-hide after 2s |
| 🔵 N badge | Pending items | Tap to sync |
| 🟡 Spinner | Syncing | Wait |

---

## 🧩 State Management (Riverpod)

### Providers
| Provider | Type | Purpose |
|----------|------|---------|
| `posProvider` | StateNotifier<PosState> | Auth, cart, products, transactions, print |
| `bluetoothServiceProvider` | Provider | Bluetooth singleton |
| `bluetoothStatusProvider` | StreamProvider<bool> | BT connection status |
| `bluetoothDevicesProvider` | StreamProvider<List> | Paired devices list |
| `connectedBluetoothDeviceProvider` | StreamProvider | Current connected device |
| `connectivityProvider` | StreamProvider<bool> | Internet connectivity |
| `supabaseClientProvider` | Provider | Supabase client instance |
| `supabaseServiceProvider` | Provider | Supabase service singleton |
| `syncServiceProvider` | Provider | Sync service |
| `syncProvider` | StateNotifier<SyncState> | Sync status (idle/syncing/pending/error) |

### PosState
```dart
PosState {
  AppUser? currentUser;
  List<Product> products;
  List<CartItem> cartItems;
  List<Transaction> transactions;
  List<HeldOrder> heldOrders;
  String? pendingCustomerName;
  String searchQuery;
  String selectedCategory;
  bool isLoading;
}
```

### SyncState
```dart
SyncState {
  SyncStatus status;    // idle | syncing | pending | error
  int pendingCount;
  String? lastError;
  int syncedCount;
}
```

---

## ⏱️ Timeout Architecture

| Layer | Timeout | Location |
|-------|---------|----------|
| HTTP Client | 5s | `_CustomHttpOverrides` in `main.dart` |
| DNS Resolution | 3s | `NetworkUtils.checkDnsResolution()` |
| Auth Request | 6s | `SupabaseService.signIn()` |
| DB Queries | 6s | `SupabaseService.fetch*()` |
| Login (total) | 12s | `PosProvider.login()` |
| Bulk Load | 20s | `PosProvider.loadProducts()` |

---

## 📱 Responsive Design

| Breakpoint | Layout |
|------------|--------|
| `< 700px` | Phone layout (1 col, cart footer) |
| `≥ 700px` (800×1280) | Tablet layout (2 col, side cart panel) |
| `≥ 600px` | Login screen wide layout (2 col) |

Uses `ResponsiveUtils` class with scale factor based on 800px baseline, clamped between 0.75–1.25.

---

## 🔧 Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| `supabase_flutter` | ^2.8.1 | Backend API & auth |
| `flutter_riverpod` | ^2.6.1 | State management |
| `flutter_bluetooth_serial` | ^0.4.0 | Bluetooth thermal printer |
| `sqflite` | ^2.4.1 | Local SQLite database |
| `connectivity_plus` | ^6.1.1 | Network status monitoring |
| `intl` | ^0.20.2 | Date/number formatting |
| `google_fonts` | ^6.2.1 | Montserrat font |
| `uuid` | ^4.5.1 | Generate UUIDs for offline transactions |
| `path_provider` | ^2.1.5 | File paths for SQLite |
| `shared_preferences` | ^2.3.4 | Key-value storage |

---

## 🚀 Deployment

### Build APK
```bash
flutter clean
flutter pub get
flutter build apk --release
```
Output: `build/app/outputs/flutter-apk/app-release.apk`

### Run on Device
```bash
flutter run
```

### Supabase Migration
Run `migration_cashier_shifts.sql` in Supabase SQL Editor for the closing report feature.

---

## 📊 Key Flows

### Complete Transaction Flow
```
User adds items to cart → Checkout → Payment dialog →
  → Generate UUID → Create Transaction object →
  → Try Supabase save:
    ├─ Success ✓ → SQLite (synced=1) → Clear cart → Add to state
    └─ Failed ✗ → SQLite (synced=0) → Add to pending_sync queue → Clear cart → Add to state
  → Auto-print (if BT connected):
    ├─ Print via ThermalPrinterService
    └─ Update print_status in DB via orderNo
  → syncAllToLocal() triggered (fire & forget)
```

### Data Loading Flow (`loadProducts()`)
```
loadProducts()
├─ Products   → CacheService.fetchProducts() → Supabase ✓ → cache → state
│                                             → Supabase ✗ → SQLite → state
├─ Transaksi  → CacheService.fetchTransactions() → Supabase ✓ → cache → state
│                                                → Supabase ✗ → SQLite → state
└─ HeldOrders → CacheService.fetchHeldOrders() → Supabase ✓ → cache → state
│                                               → Supabase ✗ → SQLite → state
└─ syncAllToLocal() — fire & forget background sync semua data ke SQLite
```

### Auto-Sync to SQLite
| Trigger | Action |
|---------|--------|
| LoadProducts (tab switch, pull-to-refresh, login) | `syncAllToLocal()` — fetch all from Supabase → write to SQLite |
| Menu screen _loadAll | `_cacheAllToLocal()` — same sync |
| Each CacheService.fetch* | Writes through to SQLite on success |

### Offline Sync Flow
```
Connectivity changes to online →
  SyncService.checkPendingCount() →
  For each pending_sync item (FIFO):
    ├─ create_transaction → save to Supabase
    ├─ create_held_order → save to Supabase
    └─ complete_held_order → update Supabase
  └─ Success → Remove from queue
     Failed → retry_count++, if > 3 → mark failed
  → Update SyncProvider state
  → Refresh UI indicators
```

### Print Flow
```
User taps "Print Again" / "Make a Copy" →
  → ThermalPrinterService().printTransaction(t) →
    ├─ BluetoothService().isConnected?
    │  ├─ No → return false
    │  └─ Yes → generate ESC/POS receipt → send via Bluetooth → return true/false
  → Update print_status via orderNo (if available, else skip)
  → Update local state (printed/failed) — regardless of DB result
  → Show snackbar result
```

### Held Order Completion Flow
```
User taps held order → retrieveHeldOrder():
  → Copy items to cart → Remove from local state
  → Try Supabase completeHeldOrder(id)
  → Try SQLite completeLocalHeldOrder(id) — always runs
  → User pays → normal transaction flow

deleteHeldOrder():
  → Remove from state
  → Try Supabase completeHeldOrder(id)
  → Try SQLite deleteLocalHeldOrder(id) — always runs
```

---

## ✅ Analysis Status
- **Zero errors** ✅
- **Zero warnings** ✅
- Only info-level notices (deprecation, style)

| Layer | Teknologi |
|-------|-----------|
| Frontend | Flutter 3.41 (Dart) — Mobile, Web, Tablet |
| State Management | Riverpod (`StateNotifier`) |
| Backend | Supabase (Auth, PostgreSQL, RLS, Edge Functions) |
| Font | Montserrat (Google Fonts) |
| Lokalisasi | `intl` untuk format Rupiah |

---

## 🗄️ Database Schema (15 Tables)

| # | Tabel | Fungsi |
|---|-------|--------|
| 1 | `branches` | Data cabang (DHBH 1, 2, 3) |
| 2 | `user_roles` | Role pengguna: `admin`, `kasir` |
| 3 | `user_profiles` | Profil user terhubung ke `auth.users` |
| 4 | `product_categories` | Kategori produk: Bekam, Terapi, Herbal, Perawatan |
| 5 | `products` | 24 produk/layanan dengan harga klinik & home visit |
| 6 | `product_variants` | Varian produk (stok, penyesuaian harga) |
| 7 | `customers` | Data pelanggan |
| 8 | `transactions` | Transaksi dengan metode bayar & status |
| 9 | `transaction_items` | Item dalam setiap transaksi |
| 10 | `split_payments` | Pembayaran multi-metode |
| 11 | `held_orders` | Pesanan ditahan sementara |
| 12 | `refunds` | Pengembalian dana |
| 13 | `inventory_movements` | Riwayat perubahan stok |
| 14 | `daily_summaries` | Ringkasan harian (aggregated) |
| 15 | `activity_logs` | Log aktivitas user (auto-trigger) |

### Trigger Otomatis
- **`on_transaction_insert`** — Mencatat log `transaksi_baru` ke `activity_logs`
- **`on_refund_insert`** — Mencatat log `refund_baru` ke `activity_logs`
- **`set_updated_at`** — Auto-update kolom `updated_at` di semua tabel

### Row Level Security (RLS)
Semua tabel memiliki RLS aktif. Kebijakan umum:
- **`branches`** — Semua user bisa baca
- **`products`** — Semua user bisa baca, hanya admin bisa CRUD
- **`transactions`** — Semua user bisa insert/select/update
- **`refunds`** — Semua user bisa insert
- **`held_orders`** — Hanya authenticated user
- **`user_profiles`** — Bisa dibaca authenticated user
- **`activity_logs`** — Dibaca oleh admin via aplikasi

---

## 👥 Role & Akun

### Role
| Role | Akses |
|------|-------|
| **Admin** | POS + History + Refund + Menu Admin (Ringkasan, Semua Transaksi, Aktivitas) |
| **Kasir** | POS + History + Refund |

### Cara Register
1. Buka halaman Register dari Login screen
2. Isi: Nama Lengkap, Email, Password, pilih Role & Cabang
3. Klik Daftar → langsung login tanpa verifikasi email

---

## 📱 Fitur Aplikasi

### 1. Login & Session
- Login via Supabase Auth (email/password)
- Session otomatis dipulihkan saat app dibuka
- Login tercatat di `activity_logs`

### 2. POS (Point of Sale)
- **Grid produk** dengan gambar dari `image_url` (fallback picsum)
- **Search** produk by nama
- **Filter kategori** — Bekam, Terapi, Herbal, Perawatan
- **Cart management** — tambah/kurang quantity, pilih harga (Di Tempat / Home Visit)
- **Order number** — muncul hanya saat cart tidak kosong
- **Payment dialog** — metode: Cash, Debit, Credit, QRIS, E-Wallet
- **Nama pelanggan wajib** — diisi saat bayar

### 3. Hold Order
- Simpan sementara pesanan ke `held_orders`
- Wajib isi **nama pelanggan**
- Badge oranye muncul di search bar jika ada pesanan ditahan
- Bottom sheet daftar held orders → ambil (retrieve) atau hapus
- Saat retrieve, nama pelanggan otomatis terbawa ke dialog bayar
- Status: `active` → `completed` setelah di-retrieve (tidak di-delete)

### 4. History & Refund
- Riwayat transaksi (descending)
- Expand item untuk lihat detail
- Tombol **Refund** (merah) untuk transaksi completed
- Refund: isi alasan → simpan ke `refunds` → status transaksi jadi `refunded`
- Refund tercatat otomatis di `activity_logs`

### 5. Menu Admin
3 tab section:

#### 🔹 Ringkasan Harian
| Metrik | Sumber |
|--------|--------|
| Total Transaksi | `transactions` hari ini (00:00–23:59) |
| Total Revenue | Sum `total_amount` |
| Breakdown per metode | Cash, Debit, QRIS, E-Wallet |
| Total Refund | Jumlah refund hari ini |

#### 🔹 Transaksi (Semua)
- 100 transaksi terakhir
- Tap untuk detail: pelanggan, kasir, metode, status, waktu

#### 🔹 Aktivitas Harian
- 50 log terbaru dari `activity_logs`
- Auto-log: `transaksi_baru`, `refund_baru`, `login`
- Tampilkan: aksi, user, timestamp

### 6. Branch di AppBar
Nama cabang user muncul di sebelah logo DHBH (e.g. `DHBH | Cabang DHBH 1`).

---

## 🧩 Struktur Proyek

```
lib/
├── main.dart                    # Entry point + Supabase init
├── config/
│   └── supabase_config.dart     # Supabase URL & Anon Key
├── models/
│   ├── user.dart                # AppUser (id, role, branchId, branchName)
│   ├── product.dart             # Product (id, name, prices, category, imageUrl)
│   ├── cart_item.dart           # CartItem (product, quantity, notes, isHomeVisit)
│   ├── transaction.dart         # Transaction (items, amount, payment, status, branchId)
│   └── held_order.dart          # HeldOrder (items, customerName, status)
├── providers/
│   └── pos_provider.dart        # StateNotifier: auth, cart, products, transactions, held orders
├── services/
│   └── supabase_service.dart    # Semua komunikasi Supabase
├── screens/
│   ├── login_screen.dart        # Login (email/password)
│   ├── register_screen.dart     # Register (nama, email, password, role, branch)
│   ├── main_app_screen.dart     # AppBar + BottomNav + TabBarView
│   ├── pos_screen.dart          # POS: grid, cart, bayar, hold, held list
│   ├── history_screen.dart      # Riwayat transaksi + refund
│   └── menu_screen.dart         # Admin: ringkasan, transaksi, aktivitas
├── widgets/
│   ├── product_card.dart        # Card produk dengan gambar
│   ├── cart_item_card.dart      # Item cart dengan +/- quantity
│   ├── payment_dialog.dart      # Dialog pembayaran + nama wajib
│   └── skeleton_widget.dart     # Shimmer loading skeleton
└── utils/
    ├── app_theme.dart           # Colors & Typography
    └── sample_data.dart         # (tidak dipakai, migrated ke Supabase)
```

---

## 🔄 Alur Transaksi

```
Login → POS → Pilih Produk → Cart → Bayar (wajib nama)
                                         ↓
                              ┌─ Cash (hitung kembalian)
                              ├─ Debit / Credit
                              ├─ QRIS
                              └─ E-Wallet
                                         ↓
                              Save ke Supabase:
                                - transactions
                                - transaction_items
                                - activity_logs (trigger)
```

### Alur Hold Order
```
Cart → Hold (wajib nama) → held_orders (status=active)
                              ↓
              Badge oranye → Bottom sheet → Ambil
                              ↓
         Cart terisi + nama pelanggan terbawa → Bayar
```

### Alur Refund
```
History → Pilih transaksi → Expand → Tombol Refund
                                         ↓
                              Isi alasan → Confirm
                                         ↓
                              - Insert ke refunds
                              - Update status = refunded
                              - activity_logs (trigger)
```

---

## 🌐 Web Support

Aplikasi kompatibel dengan Flutter Web. Jalankan:
```sh
flutter run -d chrome
```

Konfigurasi web di `web/index.html` dan `web/manifest.json` sudah disesuaikan dengan brand DHBH.

---

## 🚀 Cara Menjalankan

```sh
# Dependencies
flutter pub get

# Android
flutter run -d emulator-5554

# Web
flutter run -d chrome

# Build APK
flutter build apk --release

# Build Web
flutter build web
```

---

## 🔧 Environment Variables

Semua konfigurasi di `lib/config/supabase_config.dart`:
```dart
const String supabaseUrl = 'https://jiunlvlcwsntjbyybszd.supabase.co';
const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...';
```

---

## 📄 Lisensi

Private — DHBH Corp.
