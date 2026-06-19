# D'Homey - Manual dan Panduan Aplikasi

Dokumen ini memuat panduan instalasi, penggunaan modul, serta spesifikasi fitur sistem pintar manajemen dan komunitas indekos D'Homey.

---

## Informasi Repositori
Detail source code aplikasi D'Homey dapat diakses melalui repositori resmi proyek:
https://github.com/IdrakiFalha/D-Homey

---

## Proses Instalasi
Untuk menginstal aplikasi D'Homey pada perangkat seluler, ikuti langkah-langkah berikut:
1. Pastikan perangkat Anda menggunakan sistem operasi Android (atau iOS jika dijalankan dalam mode pengembangan).
2. Perangkat harus tersambung secara stabil dengan koneksi internet.
3. Unduh file .apk aplikasi melalui tautan distribusi yang telah disediakan oleh pihak pengelola.
4. Setelah proses unduh selesai, buka berkas tersebut dan lakukan instalasi aplikasi dengan mengikuti petunjuk di layar.
5. Jika muncul notifikasi izin keamanan sistem, aktifkan opsi "Izinkan instalasi dari sumber tidak dikenal" (Allow installation from unknown sources) untuk melanjutkan instalasi hingga selesai.

---

## Cara Menggunakan Aplikasi dan Deskripsi Modul

Aplikasi D'Homey membagi aksesibilitas sistem ke dalam dua peran (role) utama: Penghuni dan Admin. Berikut adalah rincian fungsionalitas setiap halamannya:

### A. Hak Akses: Penghuni (User)

#### 1. Halaman Login dan Registrasi
* Pengguna diarahkan ke halaman utama untuk masuk (authentication) menggunakan email dan kata sandi yang telah terdaftar di database Firebase.
* Jika belum memiliki akun, calon penghuni dapat memilih opsi untuk melakukan registrasi sebagai penghuni baru guna mengajukan permohonan kamar.

#### 2. Beranda Penghuni (User Dashboard)
Setelah berhasil masuk, pengguna disajikan halaman beranda personal dengan berbagai fitur layanan pintas (shortcut):
* **Pemesanan Layanan:** Akses cepat ke layanan Laundry dan Room/Toilet Cleaning yang terintegrasi langsung ke nomor WhatsApp pengelola.
* **Belanja dan Makanan:** Tautan integrasi ke platform eksternal untuk pemenuhan kebutuhan logistik harian.
* **Daftar Agenda (Hangout Plans):** Menampilkan lini masa kegiatan komunitas terdekat. Halaman ini juga memuat menu penyesuaian tema (Dark/Light Mode) serta pengaturan bahasa aplikasi.

#### 3. Fitur Hangout Plans (Agenda Komunitas)
Penghuni dapat merencanakan dan mengusulkan kegiatan santai bersama penghuni lain. 
* Input data meliputi: Judul Agenda (misal: Mabar ML, Nobar Film), Lokasi, Tanggal, dan Waktu.
* Setelah disetujui Admin, agenda akan muncul secara publik dan penghuni lain dapat melakukan RSVP (menekan tombol "Ikut"). Sistem otomatis menyembunyikan agenda yang telah melewati batas tenggat waktu.

#### 4. Fitur Komunikasi (Chat dan Panggilan)
Memfasilitasi interaksi sosial antarpanghuni secara real-time:
* **Personal dan Community Chat:** Layanan pesan privat antar-individu serta grup terbuka (group chat) untuk seluruh penghuni.
* **Berbagi Media:** Mengirim foto (galeri/kamera), pesan suara (voice note), dan lokasi terkini (Share Location berbasis peta interaktif).
* **Panggilan (Call/Video Call):** Komunikasi interaktif suara dan video langsung dari dalam sistem aplikasi.

#### 5. Fitur Pelaporan (Technical Report)
* Penghuni dapat melaporkan keluhan atau kerusakan fasilitas kamar secara langsung dengan mengisi formulir kendala (misal: AC bocor, lampu mati). Laporan ini otomatis terkirim ke panel Admin untuk ditindaklanjuti.

---

### B. Hak Akses: Admin (Pengelola Kos)

#### 6. Beranda Admin (Admin Dashboard)
Menampilkan visualisasi data ringkas operasional kos-kosan secara real-time:
* Statistik Jumlah Penghuni Aktif dan Kamar Kosong (Tersedia).
* Status Laporan Fasilitas yang sedang ditindaklanjuti.
* Panel verifikasi permintaan masuk kamar dari calon penghuni baru.

#### 7. Fitur Manajemen Kamar dan Penghuni
* **Manajemen Kamar:** Mengatur pemetaan nomor kamar, fasilitas internal, serta memperbarui status ketersediaan (Kosong/Terisi).
* **Manajemen Penghuni:** Mengelola basis data informasi penghuni, meliputi profil, nomor kamar, asal daerah, serta kontak darurat (emergency contact).
* **Tracking Iuran:** Melacak dan mencatat status pembayaran tagihan sewa bulanan beserta tanggal jatuh temponya.

#### 8. Fitur Verifikasi dan Riwayat Agenda
* **Verifikasi Agenda:** Meninjau usulan rencana kegiatan (Hangout Plans) dari penghuni dengan hak penuh untuk menyetujui (Approve) atau menolak (Reject).
* **Riwayat Hangout:** Menampilkan arsip rekaman seluruh agenda komunitas kos yang telah sukses terselenggara di masa lalu lengkap beserta jumlah partisipan yang hadir.
