# 📘 Panduan Pengguna — DHBH POS

> Panduan operasional untuk kasir, admin, dan karyawan dalam menjalankan aplikasi **DHBH POS** (Point of Sale klinik kesehatan multi-cabang).
>
> Disusun dari dokumentasi proyek: `PROJECT_CONTEXT.md`, `Database_details.md`, `AGENTS.md`, dan `Panduan.md`.

---

## Daftar Isi

1. [Tentang Aplikasi](#1-tentang-aplikasi)
2. [Persyaratan Sistem](#2-persyaratan-sistem)
3. [Cara Instalasi](#3-cara-instalasi)
4. [Login & Akun](#4-login--akun)
5. [Tampilan Utama](#5-tampilan-utama)
6. [Melakukan Transaksi (POS)](#6-melakukan-transaksi-pos)
7. [Pembayaran](#7-pembayaran)
8. [Pencetakan Struk](#8-pencetakan-struk)
9. [Riwayat Transaksi (History)](#9-riwayat-transaksi-history)
10. [Data Pelanggan](#10-data-pelanggan)
11. [Menu: Ringkasan Harian & Laporan Tutup Kasir](#11-menu-ringkasan-harian--laporan-tutup-kasir)
12. [Backup Data](#12-backup-data)
13. [Pemecahan Masalah (Troubleshooting)](#13-pemecahan-masalah-troubleshooting)
14. [Keamanan](#14-keamanan)

---

## 1. Tentang Aplikasi

**DHBH POS** adalah aplikasi kasir (Point of Sale) untuk klinik kesehatan DHBH yang memiliki **dua cabang**:

| Cabang | Lokasi |
|---|---|
| **DHBH Kranggan** | Jl. Raya Kranggan, Jatisampurna, Bekasi |
| **DHBH Cikampek** | Ruko Cikampek No. 20, Karawang |

Fitur utama:

- Penjualan layanan & produk (Bekam, Terapi, Herbal, Perawatan).
- Layanan **Klinik** (di tempat) dan **Home Visit** (ke rumah).
- Pembayaran **Cash / Transfer / QRIS**.
- Pencetakan struk (printer Windows atau printer thermal Bluetooth).
- Riwayat transaksi dan **refund**.
- Ringkasan penjualan harian dan **Laporan Tutup Kasir**.
- Data pelanggan.
- Backup data manual.

> ⚠️ **Penting:** Aplikasi ini **online-only** — membutuhkan koneksi internet untuk mengakses data di server. Tanpa internet, aplikasi tidak dapat memproses transaksi (hanya menampilkan banner offline).

---

## 2. Persyaratan Sistem

### 2.1 Komputer (PC Kasir)

| Komponen | Minimum |
|---|---|
| Sistem Operasi | Windows 10 64-bit (1809+) / Windows 11 |
| RAM | 4 GB |
| Penyimpanan | 2 GB ruang kosong |
| Layar | 1366×768 |
| Internet | Stabil, akses HTTPS keluar |

### 2.2 Printer (opsional)

| Jenis | Keterangan |
|---|---|
| **Printer Windows** (USB/shared) | Diset sebagai printer default di Windows. Contoh: XP-58. |
| **Printer Thermal Bluetooth** | Printer struk 58 mm dengan Bluetooth. Dapat auto-connect otomatis saat login. |

> Tanpa printer, aplikasi **tetap bisa dipakai** — transaksi tetap tersimpan, hanya struk tidak dicetak.

---

## 3. Cara Instalasi

### 3.1 Instalasi Resmi (Installer)

1. Salin file **`DHBH-POS-Setup.exe`** ke komputer.
2. Klik dua kali file installer.
3. Jika muncul peringatan Windows SmartScreen, klik **More info → Run anyway**.
4. Klik **Next**, terima lokasi instalasi (default: `%LOCALAPPDATA%\DHBH POS`).
5. Centang **Create a desktop shortcut** (buat pintasan di desktop).
6. Klik **Install**, lalu **Launch** untuk langsung menjalankan aplikasi.

> Instalasi dilakukan **per pengguna** (tanpa perlu admin / UAC).

### 3.2 Cara Menjalankan Setelah Terpasang

- Klik ganda pintasan **DHBH POS** di desktop, **atau**
- Klik **Start Menu → DHBH POS**.

### 3.3 Opsi Portable (tanpa instalasi)

1. Salin folder `build\windows\x64\runner\Release` ke komputer.
2. Jalankan file **`dhbh_app.exe`**.
3. Buat pintasan desktop ke `dhbh_app.exe` jika diinginkan.

---

## 4. Login & Akun

### 4.1 Cara Login

1. Buka aplikasi → layar **Login** akan muncul.
2. Masukkan **Email** (contoh: `nisa@dhbh.com`).
3. Masukkan **Password** (default: `dhbh12345`).
4. Klik tombol **Login**.
5. Tunggu proses koneksi ke server. Setelah berhasil, aplikasi akan memuat data produk dan membuka layar utama.

### 4.2 Akun Tersimpan (Login Cepat)

- Email yang pernah login tersimpan otomatis di layar login sebagai **"Akun Tersimpan"**.
- Klik kartu akun → email terisi otomatis → tinggal masukkan password.
- Tekan tombol **×** untuk menghapus email dari daftar.

### 4.3 Daftar Akun Staf

Semua akun memakai pola `nama@dhbh.com` dengan password default `dhbh12345`.

**Cabang DHBH Kranggan (ID 1):**

| Email | Role |
|---|---|
| sohidi@dhbh.com | Admin (Kepala Cabang) |
| nisa@dhbh.com | Kasir |
| firdaus, herman, harsono, siti, abu, nur, amel, pramono, fadli, ikhsan, alan, yolanda, suhaemi @dhbh.com | Karyawan / Terapis |

**Cabang DHBH Cikampek (ID 2):**

| Email | Role |
|---|---|
| wartok@dhbh.com | Admin (Kepala Cabang) |
| ridwan@dhbh.com | Kasir |
| dzikri, vey, dika @dhbh.com | Karyawan / Terapis |

> ⚠️ Jika lupa password, hubungi administrator untuk **reset password** (password tidak bisa diambil dari server).

### 4.4 Perbedaan Role

| Role | Kemampuan |
|---|---|
| **Admin** | Akses penuh: POS, riwayat, laporan, backup, kelola produk/pengguna. |
| **Kasir** | Mengoperasikan POS, transaksi, riwayat, laporan harian. |
| **Karyawan/Terapis** | Akses terbatas — digunakan terutama untuk identitas terapis pada transaksi. |

---

## 5. Tampilan Utama

Setelah login, layar utama menampilkan:

- **Bar atas (AppBar):**
  - Logo & **nama cabang** tempat Anda login.
  - **Transaksi Hari Ini** (jumlah) dan **Revenue Hari Ini** (total penjualan).
  - **Status printer** (Bluetooth / Windows printer).
  - Nama pengguna & tombol **Logout**.

- **Navigasi bawah (4 tab):**

| Tab | Fungsi |
|---|---|
| **POS** | Layar kasir utama untuk membuat transaksi. |
| **History** | Riwayat transaksi, cetak ulang, refund. |
| **Pelanggan** | Direktori data pelanggan. |
| **Menu** | Ringkasan harian, laporan tutup kasir, backup. |

---

## 6. Melakukan Transaksi (POS)

### 6.1 Mencari Produk / Layanan

- Gunakan kotak **pencarian** di bagian atas untuk mencari produk berdasarkan nama.
  - 💡 **Pintasan keyboard:** tekan `Ctrl + K` untuk langsung fokus ke kolom pencarian.
- Gunakan **chip kategori** untuk memfilter: **Bekam, Terapi, Herbal, Perawatan**.

### 6.2 Menambah Item ke Keranjang

1. Klik kartu produk.
2. Jika produk memiliki harga **Home Visit**, akan muncul pilihan:
   - **Klinik** → layanan di tempat.
   - **Home Visit** → layanan ke rumah.
3. Item masuk ke **keranjang** di sisi kanan.

> Harga yang tampil sudah **sesuai cabang Anda** (harga khusus per cabang otomatis digunakan).

### 6.3 Mengelola Keranjang

- **Tambah jumlah:** klik tombol `+` pada item.
- **Kurangi jumlah:** klik tombol `−`.
- **Hapus item:** gunakan tombol hapus (🗑) pada item.
- Total belanja tampil di bagian bawah keranjang.

### 6.4 Menahan Pesanan (Hold Order)

- Klik **Hold Order / Parkir** untuk menahan pesanan sementara (misal pelanggan menunggu).
- Isi **nama pelanggan** saat menahan.
- Pesanan yang ditahan dapat **diambil kembali** kapan saja dan dilanjutkan ke pembayaran.

### 6.5 Lanjut ke Pembayaran

- Setelah item lengkap, tekan tombol **Bayar** (F9) di bagian bawah keranjang.
  - 💡 **Pintasan keyboard:** tekan `F9` untuk membuka layar pembayaran.

---

## 7. Pembayaran

Form pembayaran berisi:

| Field | Keterangan |
|---|---|
| **Pelanggan** | **Wajib minimal 1.** Bisa lebih dari satu — klik **+ Tambah Pelanggan** untuk menambah baris. Tiap baris bisa diketik manual atau dipilih dari direktori pelanggan (tombol **Pilih**). Tombol hapus (×) tersedia untuk baris tambahan. |
| **Terapis** | Pilih terapis yang menangani (opsional) — bisa **lebih dari satu** dengan tombol **+ Tambah Terapis** (muncul sebagai chip yang bisa dihapus). Terapis diambil dari karyawan cabang Anda. |
| **Catatan** | Catatan tambahan, misal *"Tips: Rp 50.000"* (opsional). |
| **Metode Pembayaran** | Pilih **Cash / Transfer / QRIS**. |
| **Jumlah Dibayar** | Diisi otomatis = total jika non-cash; untuk cash, isi nominal yang diterima. |

### 7.1 Langkah Pembayaran

1. Isi **Nama Pelanggan** (minimal 1). Jika ada lebih dari satu pelanggan, klik **+ Tambah Pelanggan** dan isi baris berikutnya.
2. (Opsional) pilih **Terapis** — klik **+ Tambah Terapis** (bisa lebih dari satu) dan isi **Catatan**.
3. Pilih **Metode Pembayaran**.
4. Untuk **Cash**: masukkan **Jumlah Dibayar** → aplikasi menghitung **Kembalian** otomatis.
   - Untuk **Transfer/QRIS**: nominal dibayar otomatis sama dengan total.
5. Klik **Simpan / Bayar**.

> Semua nama pelanggan & terapis akan tercetak pada struk dan tersimpan di riwayat.

### 7.2 Setelah Pembayaran

- Transaksi **tersimpan ke server**.
- Struk **dicetak otomatis** (jika printer tersedia).
- Keranjang dikosongkan dan siap untuk transaksi berikutnya.

> ✅ Jika tidak ada printer, transaksi **tetap tersimpan** — struk bisa dicetak ulang nanti dari menu **History**.

---

## 8. Pencetakan Struk

### 8.1 Urutan Prioritas Printer (Windows)

1. **Printer Thermal Bluetooth** (jika terhubung) — paling disukai.
2. **Printer Windows** (default system / XP-58).
3. Jika keduanya tidak ada → pesan **"Tidak ada printer terhubung"**, transaksi tetap tersimpan.

> Struk transaksi mencetak **semua nama pelanggan & terapis** yang dipilih saat pembayaran.

### 8.2 Printer Thermal Bluetooth (auto-connect)

- Saat login, aplikasi **otomatis mencoba menyambung** ke printer Bluetooth yang sudah dipasangkan.
- Pastikan printer dalam keadaan **menyala**.
- MAC printer default yang didukung: `66:12:3f:23:ef:92`.
- Jika gagal otomatis, buka **dialog koneksi Bluetooth** di aplikasi:
  1. Buka dialog **Bluetooth / Printer** (ikon status printer di bar atas).
  2. Klik **Scan** untuk mencari perangkat.
  3. Pilih printer → **Connect** (sambungkan), pair jika diminta Windows.
  4. Klik **Test Print** untuk uji coba.

### 8.3 Printer Windows (USB / shared)

1. Pastikan driver printer terpasang di Windows.
2. Set printer struk sebagai **printer default** (atau pastikan printer bernama `XP-58` tersedia).
3. Lakukan test print dari Windows.
4. Cetak transaksi dari aplikasi seperti biasa.

### 8.4 Tanpa Printer

- Aplikasi **tidak akan berpura-pura berhasil mencetak**.
- Muncul pesan **"Tidak ada printer terhubung"**.
- Transaksi tetap tersimpan; status cetak tercatat `unprinted`/`failed` sampai berhasil dicetak ulang.

---

## 9. Riwayat Transaksi (History)

Menu **History** menampilkan seluruh transaksi (sesuai cabang Anda).

### 9.1 Fitur

- **Cari** transaksi (berdasarkan pelanggan/produk/nomor).
- **Urutkan** berdasarkan tanggal/terbaru.
- Klik transaksi untuk **memperluas detail**:
  - Daftar item, jumlah, harga.
  - Metode pembayaran.
  - Terapis & catatan.
  - Status (selesai / refund).

### 9.2 Cetak Ulang / Copy

- Klik **Print Again** untuk mencetak ulang struk.
- Klik **Make a Copy** untuk membuat salinan struk.

### 9.3 Refund (Pengembalian Dana)

1. Buka detail transaksi.
2. Klik **Refund**.
3. Isi **alasan** refund.
4. Transaksi ditandai **refunded** dan tercatat di laporan.

---

## 10. Data Pelanggan

Menu **Pelanggan** berisi direktori pelanggan.

| Aksi | Cara |
|---|---|
| **Tambah** | Klik tombol tambah (+), isi nama/telepon/alamat. |
| **Edit** | Klik pelanggan → ubah data → simpan. |
| **Hapus** | Klik ikon hapus pada pelanggan. |
| **Cari** | Gunakan kotak pencarian. |

- Saat pembayaran, pelanggan dapat **dipilih langsung** dari direktori ini (mode picker) sehingga tidak perlu mengetik ulang.

---

## 11. Menu: Ringkasan Harian & Laporan Tutup Kasir

Menu **Menu** berisi laporan dan utilitas.

### 11.1 Ringkasan Harian

- Menampilkan **Ringkasan Penjualan Hari Ini** untuk cabang Anda:
  - Total transaksi.
  - Total revenue.
  - Breakdown pembayaran: **Cash / Transfer / QRIS / Refund**.
  - **Terapis yang bertugas** (nama).
- Data otomatis diperbarui sesuai transaksi terbaru.

### 11.2 Laporan Tutup Kasir

Laporan lengkap untuk penutupan kasir, berisi:

- Tanggal & cabang.
- **Modal Awal** (diisi kasir pada saat buka kasir).
- **Produk terjual** (nama, qty, total).
- **Breakdown pembayaran** (Cash / Transfer / QRIS).
- **Terapis yang bertugas** (nama).
- **Saldo akhir** (hasil perhitungan otomatis).

Cara cetak:

1. Buka tab **Menu**.
2. Masukkan **Modal Awal**.
3. Klik **Print Ringkasan** (struk ringkasan harian) atau **Print / Cetak Laporan** (laporan tutup kasir).
4. Struk dicetak sesuai prioritas printer.

> Jika tidak ada printer terhubung, akan muncul pesan **"Tidak ada printer terhubung"**.

### 11.3 Transaksi Terakhir

- Menu juga menampilkan **20 transaksi terakhir** untuk pantauan cepat.

---

## 12. Backup Data

Aplikasi mendukung **backup manual** data ke database SQLite lokal (file `dhbh_backup.db`).

1. Buka tab **Menu → Backup Data**.
2. Klik **Mulai Backup / Backup Sekarang**.
3. Tunggu hingga selesai (ada indikator progres).
4. Aplikasi akan menampilkan status sukses atau gagal.

> ⚠️ Backup ini **manual** — tidak menggantikan data di server, hanya salinan cadangan. Lakukan secara rutin jika diperlukan oleh kebijakan klinik.

---

## 13. Pemecahan Masalah (Troubleshooting)

### 13.1 Aplikasi Tidak Bisa Login

Periksa:

1. Koneksi internet aktif dan stabil.
2. Email & password benar (huruf kecil semua).
3. Akun **aktif** dan terhubung ke cabang yang benar.
4. Coba akun lain (misal `nisa@dhbh.com` / `dhbh12345`) untuk memastikan.

Jika masih gagal → hubungi administrator (mungkin perlu reset password).

### 13.2 Produk Tidak Muncul

1. Pastikan sudah login dengan akun yang punya cabang.
2. Cek koneksi internet.
3. Muat ulang / buka tab lain lalu kembali ke POS.

### 13.3 Printer Tidak Mencetak

1. Apakah printer menyala & terhubung (Bluetooth / USB)?
2. Untuk Bluetooth: buka dialog koneksi → **Scan → Connect → Test Print**.
3. Untuk printer Windows: pastikan printer di-set **default**.
4. Pastikan tidak ada pesan **"Tidak ada printer terhubung"** di aplikasi.

### 13.4 Harga Tampil Salah

- Harga yang tampil adalah harga **efektif per cabang** (override harga cabang, jika ada, digunakan; jika tidak, harga default produk).
- Jika ada selisih, hubungi admin untuk cek harga produk & override cabang di database.

### 13.5 Aplikasi Terasa Lambat

1. Pastikan menggunakan **versi release** (bukan debug).
2. Tutup aplikasi lain yang berat.
3. Gunakan koneksi **kabel (LAN)** daripada Wi-Fi yang tidak stabil.
4. Pastikan PC tidak dalam mode hemat baterai ekstrem.

### 13.6 File Log Error

- Jika aplikasi bermasalah, file log error tersimpan di:
  `%TEMP%\dhbh_flutter_errors.log`
- Sertakan file ini saat melapor ke tim teknis.

---

## 14. Keamanan

- **Jangan bagikan password** akun Anda kepada siapa pun.
- **Logout** saat meninggalkan komputer kasir.
- Jangan menjalankan aplikasi sebagai **Administrator** kecuali diperlukan printer.
- Jangan mengubah perangkat keras/software PC tanpa izin.
- Pastikan PC mendapatkan **update Windows** secara rutin.

---

> **Akhir Panduan.** Jika ada pertanyaan atau kendala, hubungi tim teknis / administrator DHBH. Selamat bertransaksi! 🎉
