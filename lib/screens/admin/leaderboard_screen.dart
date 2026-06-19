import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/app_theme.dart';
import '../../utils/app_state.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Leaderboard Peduli', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color)),
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFFFFF8E1), borderRadius: BorderRadius.circular(16)),
              child: const Text('💡 Penghuni dengan poin streak tertinggi bulan ini berhak mendapat apresiasi, seperti diskon biaya kos atau camilan gratis.', style: TextStyle(color: Color(0xFFF57F17))),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('chats').snapshots(),
              builder: (context, chatsSnapshot) {
                if (chatsSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!chatsSnapshot.hasData || chatsSnapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('Belum ada data streak chat.', style: TextStyle(color: AppTheme.textLight)));
                }

                final chatsDocs = chatsSnapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return data['streakCount'] != null && data['streakCount'] > 0;
                }).toList();
                
                chatsDocs.sort((a, b) {
                  final pointsA = (a.data() as Map<String, dynamic>)['streakCount'] ?? 0;
                  final pointsB = (b.data() as Map<String, dynamic>)['streakCount'] ?? 0;
                  return pointsB.compareTo(pointsA);
                });
                
                final topChats = chatsDocs.take(2).toList();
                
                if (topChats.isEmpty) {
                  return const Center(child: Text('Belum ada data streak chat aktif.', style: TextStyle(color: AppTheme.textLight)));
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: topChats.length,
                  itemBuilder: (context, index) {
                    final data = topChats[index].data() as Map<String, dynamic>;
                    final points = data['streakCount'] ?? 0;
                    final participants = data['participants'] as List<dynamic>? ?? [];
                    final isGroup = data['isGroup'] ?? false;
                    
                    if (isGroup) {
                      return _buildLeaderboardTile(context, index + 1, 'Grup Komunitas Kos', points);
                    }
                    
                    if (participants.isEmpty) return const SizedBox();
                    
                    return FutureBuilder<List<DocumentSnapshot>>(
                      future: Future.wait(participants.map((uid) => FirebaseFirestore.instance.collection('users').doc(uid).get())),
                      builder: (ctx, snap) {
                        if (!snap.hasData) return const SizedBox();
                        final names = snap.data!.map((doc) {
                          if (doc.exists) {
                            return (doc.data() as Map<String, dynamic>)['name'] ?? 'Anonim';
                          }
                          return 'Anonim';
                        }).toList();
                        
                        String titleName = names.join(' / ');
                        return _buildLeaderboardTile(context, index + 1, titleName, points);
                      }
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardTile(BuildContext context, int rank, String name, int points) {
    Color rankColor = rank == 1 ? const Color(0xFFFFD700) : (rank == 2 ? const Color(0xFFC0C0C0) : (rank == 3 ? const Color(0xFFCD7F32) : Colors.transparent));
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
      leading: CircleAvatar(
        backgroundColor: rank <= 3 ? rankColor : const Color(0xFFE5E7EB),
        child: Text('#$rank', style: TextStyle(fontWeight: FontWeight.bold, color: rank <= 3 ? Colors.white : AppTheme.textLight)),
      ),
      title: Text(name, style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🔥', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 4),
          Text('$points', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.accent)),
        ],
      ),
    );
  }
}
