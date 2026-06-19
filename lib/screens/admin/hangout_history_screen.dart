import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../utils/app_theme.dart';
import '../../utils/app_state.dart';

class HangoutHistoryScreen extends StatelessWidget {
  const HangoutHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Riwayat Hangout', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color)),
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
            .where('status', isEqualTo: 'approved')
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
                  Icon(Icons.history_rounded, size: 60, color: Colors.grey.withOpacity(0.5)),
                  const SizedBox(height: 16),
                  Text('Belum ada riwayat agenda.', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
                ],
              ),
            );
          }

          final agendas = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            if (data['dateTime'] != null && data['dateTime'] is Timestamp) {
              final agendaDate = (data['dateTime'] as Timestamp).toDate();
              return agendaDate.isBefore(DateTime.now());
            }
            return false;
          }).toList();

          if (agendas.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_rounded, size: 60, color: Colors.grey.withOpacity(0.5)),
                  const SizedBox(height: 16),
                  Text('Belum ada agenda yang telah berlalu.', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: agendas.length,
            itemBuilder: (context, index) {
              final doc = agendas[index];
              final data = doc.data() as Map<String, dynamic>;
              
              final title = data['title'] ?? 'Tanpa Judul';
              final creator = data['creatorName'] ?? 'Anonim';
              final location = data['location'] ?? 'Tidak ditentukan';
              final participantsCount = (data['participants'] as List<dynamic>? ?? []).length;
              
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

              return _buildHistoryCard(
                context, 
                title, 
                creator, 
                '$timeStr\nLokasi: $location\nPeserta: $participantsCount orang',
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildHistoryCard(BuildContext context, String title, String creator, String detail) {
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
              Text('Diusulkan oleh: $creator', style: const TextStyle(color: AppTheme.textLight, fontSize: 13)),
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
        ],
      ),
    );
  }
}
