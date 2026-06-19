import 'package:flutter/material.dart';
import '../../models/report_model.dart';
import '../../services/report_service.dart';
import '../../utils/app_theme.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class ReportDetailScreen extends StatefulWidget {
  final ReportModel report;
  final bool isAdmin;

  const ReportDetailScreen({super.key, required this.report, this.isAdmin = true});

  @override
  State<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends State<ReportDetailScreen> {
  bool _isUpdating = false;

  Future<void> _markAsDone() async {
    setState(() => _isUpdating = true);
    await ReportService().updateReportStatus(widget.report.id, 'Selesai');
    setState(() => _isUpdating = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Laporan ditandai sebagai Selesai!'), backgroundColor: Colors.green),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _markAsProses() async {
    setState(() => _isUpdating = true);
    await ReportService().updateReportStatus(widget.report.id, 'proses');
    setState(() => _isUpdating = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Laporan ditandai Sedang Diproses!'), backgroundColor: Colors.blue),
      );
      Navigator.pop(context);
    }
  }

  void _launchMedia() async {
    if (widget.report.mediaUrl != null && widget.report.mediaUrl!.isNotEmpty) {
      final url = Uri.parse(widget.report.mediaUrl!);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tidak dapat membuka media.')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final report = widget.report;
    final isDone = report.status == 'Selesai';
    final dateStr = DateFormat('dd MMMM yyyy, HH:mm').format(report.createdAt);

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

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Detail Laporan', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: AppTheme.primary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(report.category, style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(statusText, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text('Deskripsi Laporan', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Text(report.description, style: const TextStyle(fontSize: 15, height: 1.5, color: AppTheme.textDark)),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                const Icon(Icons.person_outline, color: AppTheme.textLight, size: 20),
                const SizedBox(width: 8),
                Text('Pelapor: ${report.reporterName}', style: const TextStyle(color: AppTheme.textLight, fontSize: 14)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.access_time, color: AppTheme.textLight, size: 20),
                const SizedBox(width: 8),
                Text('Waktu: $dateStr', style: const TextStyle(color: AppTheme.textLight, fontSize: 14)),
              ],
            ),
            const SizedBox(height: 32),
            if (report.mediaUrl != null && report.mediaUrl!.isNotEmpty) ...[
              Text('Lampiran Media', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              InkWell(
                onTap: _launchMedia,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(16),
                    image: report.mediaType == 'image' 
                      ? DecorationImage(image: NetworkImage(report.mediaUrl!), fit: BoxFit.cover)
                      : null,
                  ),
                  child: report.mediaType == 'video' 
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.play_circle_fill, color: Colors.white, size: 64),
                            SizedBox(height: 8),
                            Text('Putar Video', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      )
                    : null,
                ),
              ),
              const SizedBox(height: 8),
              const Text('*Tekan gambar/video di atas untuk melihat layar penuh.', style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 32),
            ],

            if (!isDone && widget.isAdmin)
              Column(
                children: [
                  if (report.status == 'pending')
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isUpdating ? null : _markAsProses,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: _isUpdating 
                          ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Tandai Sedang Diproses', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  if (report.status == 'pending') const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isUpdating ? null : _markAsDone,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: _isUpdating 
                        ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Tandai Sebagai Selesai', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
