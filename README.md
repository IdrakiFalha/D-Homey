# D'Homey - Smart Co-Living Application

D'Homey adalah sebuah aplikasi manajemen dan komunitas indekos (kos-kosan) berbasis mobile yang mengintegrasikan berbagai aspek pengelolaan properti dengan fitur interaktif bagi para penghuninya. Aplikasi ini bertujuan untuk mempermudah pekerjaan pengelola/admin sekaligus menciptakan lingkungan kos yang nyaman, komunikatif, dan saling terhubung antar penghuni.

Aplikasi ini dibagi menjadi dua *role* atau hak akses utama: **Penghuni (User)** dan **Admin (Pengelola Kos)**.

---

## 🚀 Fitur Utama

### 1. Fitur untuk Penghuni (User)
Penghuni memiliki akses ke berbagai layanan yang memudahkan kehidupan sehari-hari mereka di kos:
* **Beranda / Dashboard:** Menampilkan sapaan personalisasi dan menyediakan akses cepat (Pintasan Layanan) seperti Laundry, Layanan Perbaikan, Belanja/Pesan Makanan, serta permintaan pembersihan kamar atau toilet (terintegrasi langsung dengan WhatsApp pengelola).
* **Agenda & Hangout Plans:** Mengusulkan acara santai (mabar game, nonton bareng) dengan sistem RSVP. Agenda yang sudah lewat tenggat waktu akan otomatis disembunyikan.
* **Komunikasi & Obrolan (Chatting):**
  * *Personal Chat:* Mengirim pesan teks, pesan suara (*voice note*), foto (kamera/galeri), dan berbagi lokasi secara *real-time*.
  * *Panggilan (Call & Video Call):* Panggilan suara dan video langsung di dalam aplikasi.
  * *Community Chat:* Grup terbuka untuk seluruh penghuni bersosialisasi.
* **Sistem Pelaporan (Technical Report):** Melaporkan kerusakan fasilitas kamar (AC bocor, lampu mati) kepada admin.
* **Profil & Personalisasi:** Mengubah foto profil, penyesuaian tema (Dark/Light Mode), pengaturan bahasa, notifikasi, serta daftar hobi.

### 2. Fitur untuk Admin (Pengelola Kos)
Admin memiliki panel dashboard khusus untuk memantau dan mengelola seluruh operasional secara terpusat:
* **Dashboard Statistik:** Menampilkan data ringkas *real-time* meliputi jumlah Penghuni Aktif, Kamar Kosong, serta Laporan/Komplain.
* **Manajemen Kamar & Penghuni:** Mengelola ketersediaan, fasilitas kamar, verifikasi penghuni baru, serta informasi kontak darurat (*emergency contact*).
* **Tracking Pembayaran (Iuran):** Memantau tanggal jatuh tempo dan pencatatan pembayaran sewa bulanan.
* **Manajemen Laporan & Agenda:** Meninjau keluhan teknis pengguna serta melakukan verifikasi (setuju/tolak) terhadap usulan rencana *Hangout* penghuni.

---

## 🛠️ Spesifikasi Teknis

* **Frontend Framework:** Flutter (Bahasa Pemrograman Dart) — Mendukung Android & iOS.
* **Backend Ecosystem:** Firebase (Cloud Firestore, Firebase Authentication, Cloud Storage).
* **UI/UX Design:** Desain modern & dinamis menggunakan konsep *Glassmorphism* serta dukungan penuh *Dark Mode* dan *Light Mode*.

---
> **Catatan Hukum:** Repositori ini berisi *source code* resmi dari aplikasi D'Homey yang diunggah khusus untuk memenuhi berkas persyaratan pendaftaran Hak Kekayaan Intelektual (HKI) dalam kategori Program Komputer.
