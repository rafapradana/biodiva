# Biodiva - Aplikasi Identifikasi Flora dan Fauna dengan AI

## Deskripsi

Biodiva adalah aplikasi mobile dan web untuk mengidentifikasi flora dan fauna menggunakan teknologi kecerdasan buatan (AI). Aplikasi ini memanfaatkan model Gemini dari Google untuk menganalisis gambar dan memberikan informasi detail tentang spesies yang terdeteksi. Aplikasi ini dikembangkan untuk membantu pengguna mengidentifikasi dan mempelajari berbagai spesies flora dan fauna yang ada di sekitar mereka.

## Fitur Utama

- **Identifikasi Flora dan Fauna**: Upload foto atau ambil gambar langsung untuk mengidentifikasi spesies.
- **Informasi Detail**: Dapatkan informasi lengkap tentang spesies termasuk:
  - Nama umum dan ilmiah
  - Deskripsi
  - Habitat
  - Klasifikasi taksonomi
  - Status konservasi
- **Quiz Pembelajaran**: Pelajari lebih lanjut tentang spesies melalui quiz interaktif yang dibuat secara otomatis berdasarkan hasil identifikasi.
- **Riwayat Identifikasi**: Simpan dan akses semua hasil identifikasi sebelumnya.
- **Dukungan Lintas Platform**: Tersedia untuk perangkat mobile (Android dan iOS) dan web browser.

## Teknologi yang Digunakan

- **Flutter**: Framework UI cross-platform untuk pengembangan aplikasi mobile dan web
- **Dart**: Bahasa pemrograman
- **Google Gemini AI**: API untuk mengidentifikasi spesies dan menghasilkan informasi
- **Hive**: Database lokal untuk penyimpanan data offline
- **Go Router**: Navigasi dan routing
- **Provider**: State management

## Prasyarat

Sebelum memulai, pastikan sistem Anda telah memenuhi prasyarat berikut:

- Flutter SDK (versi 3.0.0 atau lebih baru)
- Dart SDK (versi 3.0.0 atau lebih baru)
- Android Studio / Visual Studio Code dengan plugin Flutter
- Git
- API Key Google Gemini

## Instalasi

### Clone Repository

```bash
git clone https://github.com/rafapradana/biodiva.git
cd biodiva
```

### Konfigurasi API Key

1. Buat file `.env` di root proyek
2. Tambahkan API key Gemini Anda:

```
GEMINI_API_KEY=your_api_key_here
```

### Instalasi Dependencies

```bash
flutter pub get
```

### Menjalankan Aplikasi

#### Mode Development

```bash
# Untuk Web
flutter run -d chrome

# Untuk Android
flutter run -d android

# Untuk iOS
flutter run -d ios
```

#### Build untuk Production

```bash
# Web
flutter build web

# Android
flutter build apk --release

# iOS
flutter build ios --release
```

## Struktur Proyek

```
biodiva/
├── lib/
│   ├── config/         # Konfigurasi aplikasi
│   ├── constants/      # Konstanta aplikasi (strings, theme, dsb)
│   ├── models/         # Model data
│   ├── providers/      # Provider state management
│   ├── routes/         # Konfigurasi routing
│   ├── screens/        # Layar/halaman UI
│   ├── services/       # Layanan (API, database, dsb)
│   ├── utils/          # Fungsi utilitas
│   ├── widgets/        # Widget yang dapat digunakan kembali
│   └── main.dart       # Entry point aplikasi
├── assets/             # Aset statis (gambar, font, dsb)
├── test/               # Unit dan widget tests
├── pubspec.yaml        # Konfigurasi dependencies
└── README.md           # Dokumentasi proyek
```

## Penggunaan

### Identifikasi Spesies

1. Buka aplikasi Biodiva
2. Tekan tombol kamera di halaman utama
3. Pilih sumber gambar (kamera atau galeri)
4. Tunggu proses identifikasi selesai
5. Lihat hasil identifikasi dengan informasi detail tentang spesies

### Membuat Quiz

1. Setelah identifikasi berhasil, tekan tombol "Buat Quiz" di halaman detail spesies
2. Quiz akan dibuat secara otomatis berdasarkan informasi spesies
3. Mulai quiz untuk menguji pengetahuan Anda

### Melihat Riwayat

1. Buka halaman utama
2. Scroll untuk melihat semua identifikasi sebelumnya
3. Tekan item untuk melihat detail lengkap

## Kontribusi

Kami sangat menghargai kontribusi dari komunitas. Berikut adalah langkah-langkah untuk berkontribusi:

### Persiapan

1. Fork repository ini
2. Clone fork Anda ke komputer lokal
3. Buat branch baru untuk fitur atau perbaikan Anda:

```bash
git checkout -b feature/nama-fitur
```

### Pengembangan

1. Ikuti panduan pengkodean dan struktur proyek
2. Pastikan kode Anda bersih dan terdokumentasi dengan baik
3. Tambahkan test untuk fitur baru jika memungkinkan

### Mengirim Pull Request

1. Commit perubahan Anda:

```bash
git commit -m "Deskripsi perubahan yang dilakukan"
```

2. Push ke repository Anda:

```bash
git push origin feature/nama-fitur
```

3. Buka repository di GitHub dan buat Pull Request
4. Berikan deskripsi yang jelas tentang perubahan yang Anda buat
5. Tunggu review dan feedback

### Panduan Pengkodean

- Gunakan bahasa Indonesia untuk nama variabel, fungsi, dan komentar
- Ikuti [Effective Dart Style Guide](https://dart.dev/guides/language/effective-dart/style)
- Gunakan pendekatan provider untuk state management
- Pastikan UI responsif dan bekerja di berbagai ukuran layar

## Pelaporan Bug

Jika Anda menemukan bug atau masalah, silakan buat issue baru di GitHub repository:

1. Buka halaman [Issues](https://github.com/rafapradana/biodiva/issues)
2. Klik "New Issue"
3. Pilih template "Bug Report"
4. Isi dengan informasi yang diminta:
   - Deskripsi bug
   - Langkah-langkah untuk mereproduksi
   - Perilaku yang diharapkan
   - Screenshot (jika ada)
   - Informasi perangkat (OS, versi Flutter, browser jika web)
   - Informasi tambahan yang relevan

## Permintaan Fitur

Untuk mengusulkan fitur baru:

1. Buka halaman [Issues](https://github.com/rafapradana/biodiva/issues)
2. Klik "New Issue"
3. Pilih template "Feature Request"
4. Isi dengan informasi yang diminta:
   - Deskripsi fitur
   - Alasan mengapa fitur ini dibutuhkan
   - Solusi alternatif yang telah Anda coba
   - Mockup atau sketsa (jika ada)

## Troubleshooting

### Masalah Umum dan Solusi

#### Gambar tidak muncul di hasil identifikasi
- Pastikan aplikasi memiliki izin akses kamera dan penyimpanan
- Verifikasi format gambar yang didukung (JPG, PNG)
- Periksa koneksi internet Anda

#### Quiz tidak dapat dibuat
- Pastikan identifikasi berhasil sebelum membuat quiz
- Periksa koneksi internet Anda
- Verifikasi API key Gemini Anda masih aktif

#### Aplikasi crash saat startup
- Pastikan Anda telah menambahkan file `.env` dengan API key yang valid
- Verifikasi semua dependencies terinstal dengan benar

### Debugging

Untuk debugging aplikasi:

```bash
flutter run --debug
```

Untuk melihat log:

```bash
flutter logs
```