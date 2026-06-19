class AppTranslations {
  static const Map<String, String> _idToEn = {
    // Admin
    'Dashboard Admin': 'Admin Dashboard',
    'Total Penghuni': 'Total Residents',
    'Laporan Aktif': 'Active Reports',
    'Kamar Kosong': 'Rooms Available',
    'Laporan Terbaru': 'Recent Reports',
    'Insight Kebahagiaan': 'Wellbeing Insight',
    'Keluar': 'Sign Out',
    
    // Nav
    'Beranda': 'Home',
    'Agenda': 'Plans',
    'Chat': 'Chat',
    'Profil': 'Profile',
    'Pengaturan': 'Settings',
    
    // Home
    'Belum ada aktivitas terbaru': 'No recent activities',
    'Aktivitas Terbaru': 'Recent Activities',
    'Lapor Fasilitas': 'Report Facility',
    'Cari Teman': 'Find Friends',
    
    // Plans
    'Agenda & Aktivitas': 'Plans & Activities',
    'Saran AI Matchmaker': 'AI Matchmaker Suggestions',
    'Agenda Mendatang': 'Upcoming Events',
    'Ada 3 orang di kos ini yang hobi main game. Mau gabung mabar nanti malam?': 'There are 3 people here who love gaming. Want to join tonight?',
    'Ada 2 orang di kos ini yang sedang belajar ngoding. Mau gabung belajar bareng?': 'There are 2 people here learning to code. Want to join a study session?',
    'Ikut Gabung': 'Join',
    'Makan Malam Bersama': 'Dinner Together',
    'Dapur Umum': 'Shared Kitchen',
    
    // Profile
    'Profil & Kesehatan': 'Profile & Health',
    'Mood Tracker Mingguan': 'Weekly Mood Tracker',
    'Info Medis & Darurat': 'Medical & Emergency Info',
    'Bantuan & Dukungan': 'Help & Support',
    'Lapor Masalah Teknis (Fasilitas)': 'Report Technical Issue (Facility)',
    'Lencana Komunitas': 'Community Badges',
    'Golongan Darah': 'Blood Type',
    'Alergi': 'Allergies',
    
    // Chat
    'Pesan & Grup': 'Messages & Groups',
    "Grup D'Homey": "D'Homey Group",
    'Penghuni': 'Resident',
    'Ketik pesanmu...': 'Type your message...',
    
    // AI
    'sedang mengetik...': 'typing...',
    'Selalu online': 'Always online',

    // New Chat Features
    'Cari Pesan': 'Search Messages',
    'Bersihkan Obrolan': 'Clear Chat',
    'Blokir Kontak': 'Block Contact',
    'Buka Blokir Kontak': 'Unblock Contact',
    'Pilih Tema Obrolan': 'Choose Chat Theme',
    'Senyapkan Notifikasi': 'Mute Notifications',
    'Hapus Pesan': 'Delete Message',
    'Batal': 'Cancel',
    'Ya, Bersihkan': 'Yes, Clear',
    'Ya, Blokir': 'Yes, Block',
    'Ya, Buka': 'Yes, Unblock',
    'Ya, Hapus': 'Yes, Delete',
    'Konfirmasi': 'Confirmation',
    'Apakah Anda yakin ingin membersihkan obrolan ini?': 'Are you sure you want to clear this chat?',
    'Apakah Anda yakin ingin memblokir kontak ini?': 'Are you sure you want to block this contact?',
    'Apakah Anda yakin ingin membuka blokir kontak ini?': 'Are you sure you want to unblock this contact?',
    'Apakah Anda yakin ingin menghapus pesan ini?': 'Are you sure you want to delete this message?',
    'Anda telah memblokir kontak ini. Buka blokir untuk mengirim pesan.': 'You have blocked this contact. Unblock to send messages.',
    'Pencarian...': 'Search...',
  };

  static String t(String text, bool isEnglish) {
    if (!isEnglish) return text;
    
    // Check exact match
    if (_idToEn.containsKey(text)) {
      return _idToEn[text]!;
    }
    
    // Check if it starts with 'Kontak Darurat' because it has dynamic parts
    if (text.startsWith('Kontak Darurat')) {
      return text.replaceFirst('Kontak Darurat', 'Emergency Contact');
    }
    
    return text;
  }
}
