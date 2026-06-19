import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/report_service.dart';
import 'report_history_screen.dart';

import '../../models/report_model.dart';
import '../../utils/app_theme.dart';
import '../../widgets/custom_button.dart';

class TechnicalReportScreen extends StatefulWidget {
  const TechnicalReportScreen({super.key});

  @override
  State<TechnicalReportScreen> createState() => _TechnicalReportScreenState();
}

class _TechnicalReportScreenState extends State<TechnicalReportScreen> {
  final _descController = TextEditingController();
  String _selectedCategory = 'Listrik';
  bool _isLoading = false;
  final List<String> _categories = ['Listrik', 'Air / Pipa', 'Perabotan', 'Kebersihan', 'Lainnya'];


  Future<void> _submitReport() async {
    if (_descController.text.trim().isEmpty) return;

    setState(() => _isLoading = true);
    
    final authService = AuthService();
    final user = authService.currentUser;
    
    if (user != null) {
      final userData = await authService.getUserData(user.uid);
      final reporterName = userData?['name'] ?? 'Penghuni';



      final report = ReportModel(
        id: '',
        reporterUid: user.uid,
        reporterName: reporterName,
        category: _selectedCategory,
        description: _descController.text.trim(),
        createdAt: DateTime.now(),
        mediaUrl: null,
        mediaType: null,
      );

      final success = await ReportService().createReport(report);

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (success) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.green),
                SizedBox(width: 8),
                Text('Laporan Terkirim'),
              ],
            ),
            content: const Text('Terima kasih, laporan teknis Anda sudah masuk ke sistem dan akan segera dicek oleh Admin / Penjaga Kos.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Tutup dialog
                  Navigator.pop(context); // Kembali ke Profil
                },
                child: Text('OK', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary)),
              )
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal mengirim laporan. Coba lagi.'), backgroundColor: Colors.redAccent),
        );
      }
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Lapor Masalah Teknis', style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: Theme.of(context).primaryColor),
        actions: [
          IconButton(
            icon: Icon(Icons.history, color: Theme.of(context).primaryColor),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ReportHistoryScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Kategori Masalah', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE5E7EB), width: 1.5),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedCategory,
                  isExpanded: true,
                  style: Theme.of(context).textTheme.bodyLarge,
                  icon: Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.textLight),
                  items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedCategory = val);
                  },
                ),
              ),
            ),

            const SizedBox(height: 24),
            Text('Deskripsi Detail', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            TextField(
              controller: _descController,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: 'Contoh: Keran air di kamar mandi kamar 15 bocor terus sejak kemarin malam.',
              ),
            ),

            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.secondary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, size: 24, color: AppTheme.secondary),
                  const SizedBox(width: 12),
                  Expanded(child: Text('Bisa juga melapor lewat curhat di AI Companion, AI akan otomatis meneruskan keluhan teknismu ke Admin / Penjaga Kos.', style: TextStyle(color: AppTheme.secondary, fontSize: 13, height: 1.4))),
                ],
              ),
            ),

            const SizedBox(height: 48),
            CustomButton(
              text: 'Kirim Laporan',
              isLoading: _isLoading,
              onPressed: _submitReport,
            )
          ],
        ),
      ),
    );
  }
}
