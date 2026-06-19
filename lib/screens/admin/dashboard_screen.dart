import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../../services/room_service.dart';
import '../../models/room_model.dart';
import '../../widgets/glass_card.dart';
import '../auth/welcome_screen.dart';
import 'room_management_screen.dart';
import 'verification_screen.dart';
import 'resident_management_screen.dart';
import 'package:kos_hub/screens/admin/resident_management_screen.dart';
import 'package:kos_hub/screens/admin/payment_tracking_screen.dart';
import 'hangout_history_screen.dart' as hangout_history;
import '../../widgets/responsive_layout.dart';
import '../../utils/app_theme.dart';
import '../../utils/app_state.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final AuthService _authService = AuthService();
  String _adminName = 'Admin';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAdminData();
  }

  Future<void> _loadAdminData() async {
    final user = _authService.currentUser;
    if (user != null) {
      final data = await _authService.getUserData(user.uid);
      if (mounted) {
        setState(() {
          _adminName = data?['name'] ?? 'Admin';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _logout(BuildContext context) async {
    await _authService.signOut();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Dashboard Admin', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color)),
        backgroundColor: Theme.of(context).cardColor,
        elevation: 0,
        actions: [
          ValueListenableBuilder<ThemeMode>(
            valueListenable: AppState().themeNotifier,
            builder: (context, theme, child) {
              bool isDark = theme == ThemeMode.dark;
              return IconButton(
                icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode, color: Theme.of(context).iconTheme.color),
                onPressed: () {
                  AppState().toggleTheme(!isDark);
                },
              );
            }
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent), 
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: ResponsiveLayout(
        mobile: _buildContent(context, isDesktop: false),
        desktop: Center(
          child: SizedBox(
            width: 900,
            child: _buildContent(context, isDesktop: true),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, {required bool isDesktop}) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('Halo, $_adminName 👋', style: Theme.of(context).textTheme.displayMedium),
        const SizedBox(height: 8),
        Text('Ringkasan operasional kos hari ini.', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppTheme.textLight)),
        const SizedBox(height: 32),

        // Statistik
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('rooms').snapshots(),
          builder: (context, roomSnapshot) {
            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'penghuni').snapshots(),
              builder: (context, userSnapshot) {
                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('reports').where('status', isNotEqualTo: 'Selesai').snapshots(),
                  builder: (context, reportSnapshot) {
                    
                    int totalKamar = 0;
                    int kamarTersedia = 0;
                    int totalPenghuni = 0;
                    int laporanAktif = 0;

                    if (roomSnapshot.hasData) {
                      totalKamar = roomSnapshot.data!.docs.length;
                      kamarTersedia = roomSnapshot.data!.docs.where((doc) => doc['status'] == 'Tersedia').length;
                    }
                    if (userSnapshot.hasData) {
                      totalPenghuni = userSnapshot.data!.docs.length;
                    }
                    if (reportSnapshot.hasData) {
                      laporanAktif = reportSnapshot.data!.docs.length;
                    }

                    if (isDesktop) {
                      return Row(
                        children: [
                          Expanded(child: _buildStatCard('Penghuni Aktif', totalPenghuni.toString(), Icons.people_rounded, Colors.blue)),
                          const SizedBox(width: 16),
                          Expanded(child: _buildStatCard('Kamar Kosong', kamarTersedia.toString(), Icons.meeting_room_rounded, Colors.green)),
                          const SizedBox(width: 16),
                          Expanded(child: _buildStatCard('Laporan Aktif', laporanAktif.toString(), Icons.warning_rounded, Colors.orange)),
                        ],
                      );
                    } else {
                      return Column(
                        children: [
                          Row(
                            children: [
                              Expanded(child: _buildStatCard('Penghuni Aktif', totalPenghuni.toString(), Icons.people_rounded, Colors.blue)),
                              const SizedBox(width: 16),
                              Expanded(child: _buildStatCard('Kamar Kosong', kamarTersedia.toString(), Icons.meeting_room_rounded, Colors.green)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildStatCard('Laporan Diproses', laporanAktif.toString(), Icons.warning_rounded, Colors.orange),
                        ],
                      );
                    }
                  }
                );
              }
            );
          }
        ),

        const SizedBox(height: 32),
        
        // Permintaan Kamar Masuk
        Text('Permintaan Kamar Masuk', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('rooms').where('requestedByUid', isNull: false).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            // Client side filter out those where requestedByUid might be empty string instead of null, if any
            final requests = snapshot.data?.docs.where((doc) {
              try {
                final data = doc.data() as Map<String, dynamic>;
                return data.containsKey('requestedByUid') && data['requestedByUid'] != null && data['requestedByUid'] != '';
              } catch (_) {
                return false;
              }
            }).toList() ?? [];

            if (requests.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle_outline, color: Colors.green, size: 28),
                    SizedBox(width: 16),
                    Expanded(child: Text('Tidak ada permintaan kamar baru saat ini.', style: TextStyle(color: AppTheme.textLight))),
                  ],
                ),
              );
            }

            return Column(
              children: requests.map((doc) {
                final room = RoomModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.orange.shade100, shape: BoxShape.circle),
                        child: const Icon(Icons.person_add_alt_1_rounded, color: Colors.orange),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(room.requestedByName ?? 'Tanpa Nama', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textDark)),
                            const SizedBox(height: 4),
                            Text('Meminta Kamar ${room.roomNumber}', style: const TextStyle(color: AppTheme.textLight, fontSize: 13)),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          // Arahkan ke Room Management
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const RoomManagementScreen()));
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Tinjau'),
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          }
        ),

        const SizedBox(height: 32),

        // Pintasan Admin
        Text('Pintasan Admin', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        Column(
          children: [
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RoomManagementScreen()),
                );
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Theme.of(context).dividerColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(AppState().isDarkMode ? 0.3 : 0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: Color(0xFFEFF6FF),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.meeting_room_rounded, color: AppTheme.secondary),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Manajemen Kamar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).textTheme.bodyLarge?.color)),
                          SizedBox(height: 4),
                          Text('Kelola status kamar dan fasilitas', style: TextStyle(color: AppTheme.textLight, fontSize: 13)),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppTheme.textLight),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ResidentManagementScreen()),
                );
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Theme.of(context).dividerColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(AppState().isDarkMode ? 0.3 : 0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF0FDF4),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.people_alt_rounded, color: Colors.green),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Manajemen Penghuni', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).textTheme.bodyLarge?.color)),
                          SizedBox(height: 4),
                          Text('Daftar penghuni, kamar, dan kontak darurat', style: TextStyle(color: AppTheme.textLight, fontSize: 13)),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppTheme.textLight),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PaymentTrackingScreen()),
                );
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Theme.of(context).dividerColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(AppState().isDarkMode ? 0.3 : 0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFEF2F2), // Light red/pink
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.payments_rounded, color: Colors.redAccent),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Tracking Iuran', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).textTheme.bodyLarge?.color)),
                          SizedBox(height: 4),
                          Text('Pantau jatuh tempo iuran bulanan penghuni', style: TextStyle(color: AppTheme.textLight, fontSize: 13)),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppTheme.textLight),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('agendas').where('status', isEqualTo: 'pending').snapshots(),
              builder: (context, snapshot) {
                int pendingCount = snapshot.data?.docs.length ?? 0;
                
                return InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const VerificationScreen()),
                    );
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Theme.of(context).dividerColor),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(AppState().isDarkMode ? 0.3 : 0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: const BoxDecoration(
                            color: Color(0xFFFFF7ED), // Light orange
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.event_available_rounded, color: Colors.orange),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Verifikasi Agenda', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).textTheme.bodyLarge?.color)),
                              const SizedBox(height: 4),
                              const Text('Tinjau usulan agenda hangout dari penghuni', style: TextStyle(color: AppTheme.textLight, fontSize: 13)),
                            ],
                          ),
                        ),
                        if (pendingCount > 0)
                          Container(
                            padding: const EdgeInsets.all(6),
                            margin: const EdgeInsets.only(right: 8),
                            decoration: const BoxDecoration(
                              color: Colors.redAccent,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '$pendingCount',
                              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                        const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppTheme.textLight),
                      ],
                    ),
                  ),
                );
              }
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const hangout_history.HangoutHistoryScreen()),
                );
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Theme.of(context).dividerColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(AppState().isDarkMode ? 0.3 : 0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF3E8FF), // Light purple
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.history_rounded, color: Colors.purple),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Riwayat Hangout', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).textTheme.bodyLarge?.color)),
                          SizedBox(height: 4),
                          Text('Lihat semua agenda yang telah berlalu', style: TextStyle(color: AppTheme.textLight, fontSize: 13)),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppTheme.textLight),
                  ],
                ),
              ),
            ),
          ],
        ),

      ],
    );
  }

  Widget _buildStatCard(String title, String count, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(AppState().isDarkMode ? 0.2 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 16),
          Text(count, style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(title, style: const  TextStyle(color: AppTheme.textLight, fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
