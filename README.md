# Tokoku POS

Aplikasi Point of Sale (POS) modern berbasis mobile (Flutter) yang dirancang untuk memudahkan manajemen toko Anda. Aplikasi ini menggunakan arsitektur _Clean Architecture_ dan terintegrasi dengan backend Firebase (Authentication, Cloud Firestore, dan Cloud Storage) untuk penyimpanan data secara _real-time_ dan aman.

## 📱 Fitur Utama

### 1. Autentikasi yang Aman

- **Login & Register:** Mendukung pendaftaran akun baru menggunakan kombinasi Email & Password.
- **Google Sign-In:** Integrasi login cepat satu pintu menggunakan akun Google.

### 2. Manajemen Produk (Katalog Inventory)

- **CRUD Produk:** Tambah, baca, perbarui, dan hapus data produk secara _real-time_.
- **Upload Gambar:** Unggah gambar produk langsung menggunakan Firebase Cloud Storage.
- **Auto-Generate SKU:** Pembuatan kode SKU secara berurutan dan otomatis (Contoh: `PRD-00001`).
- **Arsip & Hapus:** Mendukung fitur arsip (sembunyikan produk dari katalog aktif tanpa menghapusnya) dan fitur hapus permanen (hard delete, termasuk penghapusan data gambar di _cloud_).

### 3. Pencarian & Filter Pintar

- **Real-time Search:** Mencari produk berdasarkan Nama atau SKU secara langsung.
- **Filter Fleksibel:** Filter berbasis kategori produk.
- **Rentang Harga:** Filter berdasarkan batas Harga Minimal dan Harga Maksimal.
- **Sorting (Pengurutan):** Mengurutkan tampilan produk berdasarkan harga (Termurah atau Termahal).

### 4. UI/UX Premium

- Desain minimalis dan responsif.
- Menggunakan palet warna _Deep Indigo Blue_ yang modern dan nyaman di mata.
- Modal _bottom sheet_ pintar untuk kemudahan filter katalog.
- Format mata uang (Rupiah) otomatis saat _input_ data produk (menggunakan _CurrencyInputFormatter_).

---

## 🛠️ Stack Teknologi & Dependensi

- **Framework:** Flutter (Dart)
- **State Management:** BLoC / Cubit (`flutter_bloc`)
- **Arsitektur:** Clean Architecture (Presentation, Domain, Data)
- **Dependency Injection:** `get_it`
- **Routing:** `go_router`
- **Backend / BaaS:** Firebase (Auth, Firestore, Storage)
- **UI & Fonts:** Material 3, Google Fonts, Shimmer Loading

---

## 🚀 Cara Menjalankan Aplikasi

Berikut adalah instruksi untuk menyiapkan dan menjalankan proyek ini di mesin lokal Anda:

### Persyaratan Sistem (Prerequisites)

Pastikan sistem Anda sudah ter-install:

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (versi 3.11.0 atau lebih tinggi).
- Editor kode seperti [Visual Studio Code](https://code.visualstudio.com/) atau Android Studio.
- Emulator Android/iOS berjalan, atau _smartphone_ fisik yang terhubung via kabel data/Wi-Fi (mode _Developer_ & _USB Debugging_ diaktifkan).

### Langkah-langkah (Installation & Run)

1. **Clone Repository (Jika diperlukan):**

   ```bash
   git clone https://github.com/fermanferdaus/tokoku.git
   cd tokoku
   ```

2. **Install Dependensi Flutter:**
   Unduh semua package yang diperlukan sesuai file `pubspec.yaml` dengan perintah:

   ```bash
   flutter pub get
   ```

3. **Konfigurasi Firebase (Penting):**
   Aplikasi ini memerlukan Firebase untuk berjalan. Pastikan Anda memiliki konfigurasi Firebase yang valid:
   - Pastikan file `google-services.json` berada di direktori `android/app/`.
   - _(Jika mendukung iOS)_ Pastikan file `GoogleService-Info.plist` berada di direktori `ios/Runner/`.
   - *Catatan: File-file ini tidak di-*commit* ke repository publik untuk alasan keamanan.*

4. **Jalankan Aplikasi:**
   Pilih target perangkat (emulator atau device fisik) lalu eksekusi perintah:
   ```bash
   flutter run
   ```
   _Atau, tekan `F5` / tombol Run di Visual Studio Code._

---

## 📂 Struktur Direktori Proyek

Proyek ini dibangun menggunakan **Clean Architecture**. Struktur direktori dibagi menjadi tiga layer utama:

```
lib/
├── config/              # Konfigurasi aplikasi (seperti router go_router)
├── core/                # Utility, constants, errors, formatters, dan theme (warna/font)
├── data/                # Data layer (datasources, models, repositories impl)
├── domain/              # Domain layer (entities, repositories interface)
├── presentation/        # Presentation layer (blocs/cubits, screens, widgets)
├── injection_container.dart # Setup dependency injection (get_it)
└── main.dart            # Entry point aplikasi
```

---
