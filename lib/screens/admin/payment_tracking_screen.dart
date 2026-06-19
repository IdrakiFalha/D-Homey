import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../utils/app_theme.dart';
import '../user/chat_room_screen.dart';
import '../../utils/app_state.dart';

class PaymentTrackingScreen extends StatefulWidget {
  const PaymentTrackingScreen({super.key});

  @override
  State<PaymentTrackingScreen> createState() => _PaymentTrackingScreenState();
}

class _PaymentTrackingScreenState extends State<PaymentTrackingScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  DateTime _calculateNextDueDate(Map<String, dynamic> data) {
    if (data['nextPaymentDueDate'] != null) {
      return (data['nextPaymentDueDate'] as Timestamp).toDate();
    }

    Timestamp? createdAtTs = data['createdAt'];
    DateTime joinedDate = createdAtTs?.toDate() ?? DateTime.now();

    final now = DateTime.now();
    // Cari jatuh tempo di bulan ini
    DateTime dueDateThisMonth;
    try {
      dueDateThisMonth = DateTime(now.year, now.month, joinedDate.day);
    } catch (e) {
      // Menangani kasus jika joinedDate.day adalah 31, namun bulan sekarang hanya sampai 30
      dueDateThisMonth = DateTime(now.year, now.month + 1, 0); // Hari terakhir bulan ini
    }

    return dueDateThisMonth;
  }

  Future<void> _markAsPaid(String uid, DateTime currentDueDate) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Pembayaran'),
        content: const Text('Tandai tagihan bulan ini sudah dibayar? Jatuh tempo berikutnya akan diperbarui.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true), 
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            child: const Text('Ya, Sudah Lunas'),
          ),
        ],
      )
    );

    if (confirm == true) {
      DateTime newDueDate;
      try {
        newDueDate = DateTime(currentDueDate.year, currentDueDate.month + 1, currentDueDate.day);
      } catch (e) {
        newDueDate = DateTime(currentDueDate.year, currentDueDate.month + 2, 0);
      }
      
      await _db.collection('users').doc(uid).update({
        'nextPaymentDueDate': Timestamp.fromDate(newDueDate),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pembayaran berhasil dicatat. Status menjadi Aman.')));
      }
    }
  }

  int _calculateDaysDifference(DateTime dueDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueDate.year, dueDate.month, dueDate.day);
    return due.difference(today).inDays;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Tracking Iuran Bulanan', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontWeight: FontWeight.bold)),
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
        stream: _db.collection('users').where('role', isEqualTo: 'penghuni').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('Belum ada penghuni terdaftar.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final uid = docs[index].id;
              final name = data['name'] ?? 'Tanpa Nama';
              
              DateTime dueDate = _calculateNextDueDate(data);
              int diffDays = _calculateDaysDifference(dueDate);

              Color statusColor;
              String statusText;
              IconData statusIcon;

              if (diffDays < 0) {
                statusColor = Colors.redAccent;
                statusText = 'Terlambat ${diffDays.abs()} Hari';
                statusIcon = Icons.warning_rounded;
              } else if (diffDays <= 7) {
                statusColor = Colors.orange;
                statusText = 'Jatuh Tempo H-$diffDays';
                statusIcon = Icons.info_outline_rounded;
              } else {
                statusColor = Colors.green;
                statusText = 'Aman (H-$diffDays)';
                statusIcon = Icons.check_circle_outline;
              }

              return Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: statusColor.withOpacity(0.5), width: 1.5),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Theme.of(context).textTheme.bodyLarge?.color)),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(statusIcon, color: statusColor, size: 16),
                                const SizedBox(width: 4),
                                Text(statusText, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12)),
                              ],
                            ),
                          )
                        ],
                      ),
                      const Divider(),
                      
                      FutureBuilder<QuerySnapshot>(
                        future: _db.collection('rooms').where('occupantUid', isEqualTo: uid).get(),
                        builder: (ctx, roomSnap) {
                          String roomText = 'Belum memiliki kamar';
                          if (roomSnap.hasData && roomSnap.data!.docs.isNotEmpty) {
                            roomText = 'Kamar ${roomSnap.data!.docs.first['roomNumber']}';
                          }
                          return Row(
                            children: [
                              const Icon(Icons.meeting_room_outlined, size: 16, color: AppTheme.textLight),
                              const SizedBox(width: 8),
                              Text(roomText, style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.calendar_month_outlined, size: 16, color: AppTheme.textLight),
                          const SizedBox(width: 8),
                          Text('Jatuh Tempo: ${DateFormat('dd MMM yyyy').format(dueDate)}', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.payments_outlined, size: 16, color: AppTheme.textLight),
                          const SizedBox(width: 8),
                          Text('Tagihan: Rp 1.500.000 / Bulan', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color)),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _markAsPaid(uid, dueDate),
                              icon: const Icon(Icons.check_circle_outline, size: 18),
                              label: const Text('Tandai Lunas'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                foregroundColor: Colors.green,
                                side: const BorderSide(color: Colors.green),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ChatRoomScreen(
                                      receiverUserId: uid,
                                      receiverUserName: name,
                                      isGroup: false,
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.chat_bubble_outline, size: 18),
                              label: const Text('Hubungi'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                backgroundColor: AppTheme.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
