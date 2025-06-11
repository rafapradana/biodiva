# 📱 **Biodiva – AI Flora Fauna Identifier & Quiz App**

## 🚀 Tech Stack

* **Framework**: Flutter
* **AI Model**: Google Gemini (gemini-2.0-flash)
* **Database**: Local storage (Hive)
* **Authentication**: No login/signup, one-time name input

### 🧭 **User Flow Overview**

1. **Splash Screen**
2. **First-Time Setup**

   * Input nama pengguna
   * Simpan nama di local storage
3. **Home Screen (Beranda)**

   * Greeting Card (menyapa nama user)
   * Stats Card (jumlah flora/fauna & quiz)
   * Shortcut Card ke Identifier & Quiz
4. **Navbar Menu:**

   * **Beranda**
   * **Identifier**
   * **Quiz**

---

## 🏠 **1. Beranda**

### UI:

* Greeting Card: "Halo, \[Nama] 👋"
* Statistik:

  * Flora/Fauna Diidentifikasi: X item
  * Quiz Dihasilkan: Y buah
* Shortcut:

  * 🔍 Identifier
  * 🧠 Quiz

---

## 🔎 **2. Identifier**

### UI:

* **Search Bar** + Filter (jenis, urut berdasarkan waktu/tanggal)
* List card hasil identifikasi:

  * Gambar thumbnail
  * Nama Umum & Ilmiah
  * Tanggal identifikasi
* **FAB (+)**:

  * Tampilkan bottom sheet:

    * 📷 Ambil dari Kamera
    * 🖼️ Ambil dari Galeri

### Setelah Submit Foto:

* Tampilkan Loading → Kirim ke Gemini untuk analisis
* Lalu tampilkan:

  #### 📋 **Detail Identifikasi**

  * Gambar
  * Jenis: Flora / Fauna
  * Nama Umum
  * Nama Ilmiah
  * Keyakinan (%)
  * Deskripsi
  * Habitat
  * Tabel Klasifikasi (Kingdom s/d Spesies)
  * Status Konservasi
  * 🔘 **\[Generate Quiz]**
  * 🔙 Kembali ke Beranda

---

## 🧠 **3. Quiz**

### Tab 1: **Quiz**

* Search bar + Filter (jenis flora/fauna, waktu, dll)
* List Quiz:

  * Judul (misal: “Quiz – Anggrek Bulan”)
  * Tanggal dibuat
  * Jumlah soal

### Tab 2: **History**

* List quiz yang sudah dikerjakan
* Menampilkan skor, waktu pengerjaan, dan tombol “Lihat Detail”
* Fitur Search & Filter

---