import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../utils/app_theme.dart';
import '../../utils/app_state.dart';

class VerificationScreen extends StatelessWidget {
  const VerificationScreen({super.key});

  Future<void> _updateAgendaStatus(BuildContext context, String agendaId, String newStatus) async {
    try {
      await FirebaseFirestore.instance.collection('agendas').doc(agendaId).update({
        'status': newStatus,
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Agenda ${newStatus == 'approved' ? 'disetujui' : 'ditolak'}')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Terjadi kesalahan: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Verifikasi Agenda', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color)),
        backgroundColor: Theme.of(context).cardColor,
        elevation: 1,
        iconTheme: IconThemeData(color: Theme.of(context).iconTheme.color),
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
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('agendas')
            .where('status', isEqualTo: 'pending')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline_rounded, size: 60, color: Colors.green.withOpacity(0.5)),
                  const SizedBox(height: 16),
                  Text('Belum ada usulan agenda baru.', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
                ],
              ),
            );
          }

          final agendas = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: agendas.length,
            itemBuilder: (context, index) {
              final doc = agendas[index];
              final data = doc.data() as Map<String, dynamic>;
              
              final title = data['title'] ?? 'Tanpa Judul';
              final creator = data['creatorName'] ?? 'Anonim';
              final location = data['location'] ?? 'Tidak ditentukan';
              
              // Handle dateTime
              String timeStr = '';
              if (data['dateTime'] != null) {
                if (data['dateTime'] is Timestamp) {
                  final dt = (data['dateTime'] as Timestamp).toDate();
                  timeStr = DateFormat('EEEE, dd MMM yyyy - HH:mm').format(dt);
                } else {
                  timeStr = data['dateTime'].toString();
                }
              }

              return _buildVerificationCard(
                context, 
                doc.id, 
                title, 
                creator, 
                '$timeStr\nLokasi: $location'
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildVerificationCard(BuildContext context, String agendaId, String title, String creator, String detail) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor, 
        borderRadius: BorderRadius.circular(16), 
        border: Border.all(color: Theme.of(context).dividerColor)
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Theme.of(context).textTheme.bodyLarge?.color)),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.person_outline, size: 16, color: AppTheme.textLight),
              const SizedBox(width: 4),
              Text('Diajukan oleh: $creator', style: const TextStyle(color: AppTheme.textLight, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline, size: 16, color: AppTheme.textLight),
              const SizedBox(width: 4),
              Expanded(child: Text(detail, style: const TextStyle(color: AppTheme.textLight, fontSize: 13))),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _updateAgendaStatus(context, agendaId, 'rejected'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent, 
                    side: const BorderSide(color: Colors.redAccent),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Tolak'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _updateAgendaStatus(context, agendaId, 'approved'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50), 
                    foregroundColor: Colors.white, 
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Setujui'),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}
