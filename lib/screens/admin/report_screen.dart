import 'package:flutter/material.dart';
import '../../models/report_model.dart';
import '../../services/report_service.dart';
import '../../utils/app_theme.dart';
import 'package:intl/intl.dart';
import 'report_detail_screen.dart';
import '../../utils/app_state.dart';

class ReportScreen extends StatelessWidget {
  const ReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Laporan Teknis', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color)),
        backgroundColor: Theme.of(context).cardColor,
        elevation: 0,
        actions: [
          ValueListenableBuilder<ThemeMode>(
            valueListenable: AppState().themeNotifier,
            builder: (context, theme, child) {
              bool isDark = theme == ThemeMode.dark;
              return IconButton(
                icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode, color: Theme.of(context).iconTheme.color),
                onPressed: () => AppState().toggleTheme(!isDark),
              );
            }
          ),
        ],
      ),
      body: StreamBuilder<List<ReportModel>>(
        stream: ReportService().getReports(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.accent));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle_outline_rounded, size: 60, color: Color(0xFF4CAF50)),
                  const SizedBox(height: 16),
                  Text('Semua beres! Belum ada laporan teknis saat ini.', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
                ],
              ),
            );
          }

          final reports = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: reports.length,
            itemBuilder: (context, index) {
              final report = reports[index];
              return _buildReportCard(context, report);
            },
          );
        },
      ),
    );
  }

  Widget _buildReportCard(BuildContext context, ReportModel report) {
    // Tentukan warna badge berdasarkan status
    Color statusColor;
    String statusText;
    if (report.status == 'pending') {
      statusColor = Colors.orange;
      statusText = 'Menunggu';
    } else if (report.status == 'proses') {
      statusColor = Colors.blue;
      statusText = 'Diproses';
    } else {
      statusColor = Colors.green;
      statusText = 'Selesai';
    }

    final dateStr = DateFormat('dd MMM yyyy, HH:mm').format(report.createdAt);

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ReportDetailScreen(report: report)),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(report.category, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).textTheme.bodyLarge?.color)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(statusText, style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              report.description, 
              style: const TextStyle(color: AppTheme.textDark, fontSize: 14),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (report.mediaUrl != null && report.mediaUrl!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(report.mediaType == 'video' ? Icons.videocam : Icons.image, color: AppTheme.primary, size: 16),
                  const SizedBox(width: 6),
                  const Text('Mempunyai Lampiran', style: TextStyle(color: AppTheme.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              )
            ],
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Pelapor: ${report.reporterName}', style: const TextStyle(color: AppTheme.textLight, fontSize: 12)),
                    Text(dateStr, style: const TextStyle(color: AppTheme.textLight, fontSize: 12)),
                  ],
                ),
                const Icon(Icons.arrow_forward_ios_rounded, color: AppTheme.textLight, size: 16),
              ],
            )
          ],
        ),
      ),
    );
  }
}
