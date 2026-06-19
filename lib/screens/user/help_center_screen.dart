import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../utils/app_theme.dart';
import '../../widgets/custom_button.dart';

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  Future<void> _contactAdmin() async {
    final url = Uri.parse("https://wa.me/6281232340661?text=Halo%20Admin%20D'Homey,%20saya%20butuh%20bantuan");
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch WhatsApp');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pusat Bantuan')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text('Pertanyaan Populer (FAQ)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.primary)),
          const SizedBox(height: 16),
          _buildFAQItem('Bagaimana cara melaporkan fasilitas rusak?', 'Buka menu Profil, lalu tekan tombol "Lapor Masalah Teknis". Anda bisa memotret kerusakan dan mengirimkannya langsung ke Admin.'),
          _buildFAQItem('Bagaimana cara kerja Matchmaker?', 'Matchmaker menggunakan AI untuk mencocokkan hobi Anda (yang diisi di Edit Profil) dengan penghuni lain, lalu menyarankan kegiatan bersama.'),
          _buildFAQItem('Apakah pesan ke Pipip (AI) aman?', 'Ya, curhatan Anda ke Pipip bersifat rahasia. AI hanya mengirimkan laporan "tingkat stres" secara anonim (tanpa nama) ke admin agar kos bisa mengadakan acara penyegaran.'),
          
          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 32),
          
          const Icon(Icons.support_agent_rounded, size: 64, color: AppTheme.primary),
          const SizedBox(height: 16),
          const Text('Masih Butuh Bantuan?', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 8),
          const Text('Tim admin kami siap membantu Anda 24/7 untuk memastikan kenyamanan tinggal Anda.', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.textLight)),
          const SizedBox(height: 24),
          
          CustomButton(
            text: 'Hubungi Admin (WhatsApp)',
            onPressed: _contactAdmin,
          ),
        ],
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        title: Text(question, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0).copyWith(top: 0),
            child: Text(answer, style: const TextStyle(color: AppTheme.textLight, fontSize: 13, height: 1.5)),
          ),
        ],
      ),
    );
  }
}
