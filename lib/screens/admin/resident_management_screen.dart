import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/app_theme.dart';
import '../../utils/app_state.dart';
import 'edit_resident_screen.dart';

class ResidentManagementScreen extends StatefulWidget {
  const ResidentManagementScreen({super.key});

  @override
  State<ResidentManagementScreen> createState() => _ResidentManagementScreenState();
}

class _ResidentManagementScreenState extends State<ResidentManagementScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Fungsi edit dipindahkan ke layar terpisah

  void _deleteResident(String uid, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keluarkan Penghuni?'),
        content: Text('Apakah Anda yakin ingin mengeluarkan $name dari kos? Data profil, chat, dan riwayat akan tetap ada, tetapi ia tidak akan bisa masuk aplikasi lagi dan kamarnya akan dikosongkan.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () async {
              await _db.collection('users').doc(uid).update({'role': 'mantan_penghuni'});
              // Opsional: Hapus dari tabel kamar jika mereka menempati kamar.
              final rooms = await _db.collection('rooms').where('occupantUid', isEqualTo: uid).get();
              for (var room in rooms.docs) {
                await room.reference.update({
                  'status': 'Tersedia',
                  'occupantUid': null,
                  'occupantName': null,
                });
              }
              if (mounted) Navigator.pop(ctx);
            },
            child: const Text('Keluarkan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Manajemen Penghuni', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color)),
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
              final email = data['email'] ?? '-';
              final emName = data['emergencyContactName'] ?? '-';
              final emPhone = data['emergencyContactPhone'] ?? '-';
              final origin = data['origin'] ?? 'Tidak diketahui';

              return Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Theme.of(context).dividerColor),
                ),
                color: Theme.of(context).cardColor,
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
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () {
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => EditResidentScreen(uid: uid, initialData: data)));
                                },
                                tooltip: 'Edit',
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.redAccent),
                                onPressed: () => _deleteResident(uid, name),
                                tooltip: 'Keluarkan',
                              ),
                            ],
                          )
                        ],
                      ),
                      const Divider(),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.email_outlined, size: 16, color: AppTheme.textLight),
                          const SizedBox(width: 8),
                          Text(email, style: const TextStyle(color: AppTheme.textDark)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.location_city_outlined, size: 16, color: AppTheme.textLight),
                          const SizedBox(width: 8),
                          Text('Asal: $origin', style: const TextStyle(color: AppTheme.textDark)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.contact_emergency_outlined, size: 16, color: AppTheme.textLight),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text('Darurat: $emName ($emPhone)', style: const TextStyle(color: AppTheme.textDark)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      
                      // Cari kamar yang ditempati penghuni ini
                      FutureBuilder<QuerySnapshot>(
                        future: _db.collection('rooms').where('occupantUid', isEqualTo: uid).get(),
                        builder: (ctx, roomSnap) {
                          if (roomSnap.connectionState == ConnectionState.waiting) {
                            return const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2));
                          }
                          final roomDocs = roomSnap.data?.docs ?? [];
                          if (roomDocs.isEmpty) {
                            return const Text('Kamar: Belum menempati kamar', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold));
                          }
                          final roomNumber = roomDocs.first['roomNumber'];
                          return Text('Menempati Kamar: $roomNumber', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold));
                        },
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
