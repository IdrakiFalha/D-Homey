import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../services/auth_service.dart';
import 'technical_report_screen.dart';
import '../../utils/app_theme.dart';
import '../../utils/app_translations.dart';
import '../../utils/app_state.dart';

class HomeAgendaScreen extends StatefulWidget {
  const HomeAgendaScreen({super.key});

  @override
  State<HomeAgendaScreen> createState() => _HomeAgendaScreenState();
}

class _HomeAgendaScreenState extends State<HomeAgendaScreen> {
  String _userName = "Guest";
  String _userUid = "";
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserName();
  }

  Future<void> _fetchUserName() async {
    final authService = AuthService();
    final user = authService.currentUser;
    if (user != null) {
      _userUid = user.uid;
      final userData = await authService.getUserData(user.uid);
      if (userData != null && userData['name'] != null) {
        if (mounted) {
          setState(() {
            _userName = userData['name'].toString().split(' ')[0];
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _launchWhatsApp(String phoneNumber, String message) async {
    final Uri url = Uri.parse("https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}");
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak dapat membuka WhatsApp')),
        );
      }
    }
  }

  Future<void> _launchExternalUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak dapat membuka link tersebut')),
        );
      }
    }
  }

  void _showProposeAgendaDialog(BuildContext context) {
    final titleController = TextEditingController();
    final locationController = TextEditingController();
    DateTime? selectedDate;
    TimeOfDay? selectedTime;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateSB) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                left: 24, right: 24, top: 24
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Usulkan Agenda Baru", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: "Judul Agenda (contoh: Mabar ML)",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: locationController,
                    decoration: InputDecoration(
                      labelText: "Lokasi (contoh: Ruang TV)",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final date = await showDatePicker(
                              context: ctx,
                              initialDate: DateTime.now(),
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 30)),
                            );
                            if (date != null) {
                              setStateSB(() => selectedDate = date);
                            }
                          },
                          icon: const Icon(Icons.calendar_today),
                          label: Text(selectedDate == null ? "Pilih Tanggal" : DateFormat('dd MMM yyyy').format(selectedDate!)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final time = await showTimePicker(
                              context: ctx,
                              initialTime: TimeOfDay.now(),
                            );
                            if (time != null) {
                              setStateSB(() => selectedTime = time);
                            }
                          },
                          icon: const Icon(Icons.access_time),
                          label: Text(selectedTime == null ? "Pilih Waktu" : selectedTime!.format(ctx)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (titleController.text.isEmpty || locationController.text.isEmpty || selectedDate == null || selectedTime == null) {
                          ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Mohon lengkapi semua data.')));
                          return;
                        }
                        final dateTime = DateTime(
                          selectedDate!.year, selectedDate!.month, selectedDate!.day,
                          selectedTime!.hour, selectedTime!.minute,
                        );
                        
                        await FirebaseFirestore.instance.collection('agendas').add({
                          'title': titleController.text.trim(),
                          'location': locationController.text.trim(),
                          'dateTime': Timestamp.fromDate(dateTime),
                          'creatorUid': _userUid,
                          'creatorName': _userName,
                          'status': 'pending',
                          'participants': [_userUid],
                        });
                        
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Agenda berhasil diusulkan, menunggu verifikasi Admin.')));
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text("Usulkan", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          }
        );
      }
    );
  }

  void _showParticipantsDialog(BuildContext context, List<dynamic> participants) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          title: Text('Daftar Peserta', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: participants.length,
              itemBuilder: (context, index) {
                final uid = participants[index];
                return FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const ListTile(title: Text('Memuat...'));
                    final data = snapshot.data!.data() as Map<String, dynamic>?;
                    final name = data?['name'] ?? 'Penghuni';
                    return ListTile(
                      leading: CircleAvatar(backgroundColor: AppTheme.primary, child: const Icon(Icons.person, color: Colors.white)),
                      title: Text(name, style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
                    );
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tutup')),
          ],
        );
      }
    );
  }

  Future<void> _toggleRsvp(String agendaId, List<dynamic> participants) async {
    final isGoing = participants.contains(_userUid);
    try {
      await FirebaseFirestore.instance.collection('agendas').doc(agendaId).update({
        'participants': isGoing ? FieldValue.arrayRemove([_userUid]) : FieldValue.arrayUnion([_userUid])
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AppState().isEnglishNotifier,
      builder: (context, isEnglish, child) {
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // HEADER SECTION
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.home_outlined, color: Theme.of(context).colorScheme.secondary, size: 32),
                                const SizedBox(width: 8),
                                Text(
                                  "D'Homey",
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                    color: Theme.of(context).colorScheme.secondary,
                                  ),
                                ),
                              ],
                            ),
                            // Dark Mode Toggle
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
                        const SizedBox(height: 24),
                        Text(
                          _isLoading ? "Hi, ..." : "Hi, $_userName!",
                          style: TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.w900,
                            color: Theme.of(context).primaryColor,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          AppTranslations.t("Need a hand or want to hang out?", isEnglish),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                        const SizedBox(height: 40),
                        
                        // ICONS ROW
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 12,
                          runSpacing: 20,
                          children: [
                            _buildServiceIcon("Laundry", Icons.local_laundry_service, () {
                              _launchWhatsApp("6282220001189", "Halo, saya ingin menanyakan layanan Laundry kos.");
                            }, context),
                            _buildServiceIcon("Repairs", Icons.build_circle_outlined, () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const TechnicalReportScreen()));
                            }, context),
                            _buildServiceIcon("Shopping", Icons.shopping_bag_outlined, () {
                              _launchExternalUrl("https://shopee.co.id");
                            }, context),
                            _buildServiceIcon("Food", Icons.fastfood_outlined, () {
                              _launchExternalUrl("https://gofood.co.id");
                            }, context),
                            _buildServiceIcon("Toilet\nCleaning", Icons.cleaning_services_outlined, () {
                              _launchWhatsApp("6281232340661", "Halo pengurus, saya ingin request pembersihan Toilet kamar saya.");
                            }, context),
                            _buildServiceIcon("Room\nCleaning", Icons.bed_outlined, () {
                              _launchWhatsApp("6281232340661", "Halo pengurus, saya ingin request pembersihan Kamar saya.");
                            }, context),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),

                  // HANGOUT PLANS SECTION
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondary,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(40),
                        topRight: Radius.circular(40),
                      ),
                    ),
                    padding: const EdgeInsets.fromLTRB(24, 32, 24, 100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                AppTranslations.t("Hangout Plans", isEnglish),
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                  color: AppState().isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              onPressed: () => _showProposeAgendaDialog(context),
                              icon: const Icon(Icons.add, size: 18),
                              label: Text(AppTranslations.t("Usulkan", isEnglish)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).primaryColor,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        
                        StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance.collection('agendas').where('status', isEqualTo: 'approved').snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return Center(child: CircularProgressIndicator(color: AppState().isDarkMode ? const Color(0xFF1E1E1E) : Colors.white));
                            }
                            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                              return Text(AppTranslations.t("Belum ada agenda yang disetujui. Usulkan agenda baru sekarang!", isEnglish), style: TextStyle(color: AppState().isDarkMode ? const Color(0xFF1E1E1E) : Colors.white));
                            }
                            
                            final agendas = snapshot.data!.docs.where((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              if (data['dateTime'] != null && data['dateTime'] is Timestamp) {
                                final agendaDate = (data['dateTime'] as Timestamp).toDate();
                                return agendaDate.isAfter(DateTime.now());
                              }
                              return false;
                            }).toList();
                            
                            if (agendas.isEmpty) {
                              return Text(AppTranslations.t("Belum ada agenda yang disetujui. Usulkan agenda baru sekarang!", isEnglish), style: TextStyle(color: AppState().isDarkMode ? const Color(0xFF1E1E1E) : Colors.white));
                            }
                            
                            return Column(
                              children: agendas.map((doc) {
                                final data = doc.data() as Map<String, dynamic>;
                                final title = data['title'] ?? 'Tanpa Judul';
                                final location = data['location'] ?? 'Tidak ditentukan';
                                final participants = data['participants'] as List<dynamic>? ?? [];
                                
                                String timeStr = '';
                                if (data['dateTime'] != null && data['dateTime'] is Timestamp) {
                                  timeStr = DateFormat('dd MMM, HH:mm').format((data['dateTime'] as Timestamp).toDate());
                                }
                                
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 20),
                                  child: _buildHangoutCard(
                                    id: doc.id,
                                    title: title,
                                    time: timeStr,
                                    location: location,
                                    participants: participants,
                                    context: context,
                                    isEnglish: isEnglish,
                                  ),
                                );
                              }).toList(),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    );
  }

  Widget _buildServiceIcon(String label, IconData? icon, VoidCallback? onTap, BuildContext context) {
    return SizedBox(
      width: 75,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Column(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondary,
                  shape: BoxShape.circle,
                ),
                child: icon != null 
                  ? Icon(
                      icon, 
                      color: Theme.of(context).brightness == Brightness.dark 
                          ? Colors.white.withOpacity(0.9) 
                          : Theme.of(context).primaryColor.withOpacity(0.6), 
                      size: 28
                    ) 
                  : null,
              ),
              const SizedBox(height: 8),
              Text(
                AppTranslations.t(label, AppState().isEnglish),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Theme.of(context).primaryColor,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHangoutCard({
    required String id,
    required String title,
    required String time,
    required String location,
    required List<dynamic> participants,
    required BuildContext context,
    required bool isEnglish,
  }) {
    final goingCount = participants.length;
    final isGoing = participants.contains(_userUid);
    
    // Tumpukan avatar (maks 3)
    final int displayAvatars = goingCount > 3 ? 3 : goingCount;
    final List<Color> avatarColors = [
      Theme.of(context).primaryColor,
      Theme.of(context).colorScheme.secondary,
      AppTheme.accent,
    ];

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 90, height: 90,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.event, size: 40, color: Theme.of(context).colorScheme.secondary),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.person_outline, size: 14, color: Theme.of(context).colorScheme.secondary),
                  const SizedBox(width: 4),
                  Text(
                    "$goingCount ${AppTranslations.t('Going', isEnglish)}",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              if (goingCount > 0)
                GestureDetector(
                  onTap: () => _showParticipantsDialog(context, participants),
                  child: SizedBox(
                    width: 24.0 + (14.0 * (displayAvatars - 1)),
                    height: 24,
                    child: Stack(
                      children: List.generate(displayAvatars, (index) {
                        return Positioned(
                          left: index * 14.0,
                          child: _buildAvatarCircle(avatarColors[index % avatarColors.length], context)
                        );
                      }),
                    ),
                  ),
                )
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 18, color: Theme.of(context).colorScheme.secondary),
                    const SizedBox(width: 6),
                    Text(
                      time,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 18, color: Theme.of(context).colorScheme.secondary),
                    const SizedBox(width: 6),
                    Text(
                      location,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: () => _toggleRsvp(id, participants),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isGoing ? Colors.redAccent : Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                    ),
                    child: Text(
                      isGoing ? (isEnglish ? "Cancel" : "Batal Ikut") : AppTranslations.t("I'm in!", isEnglish),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarCircle(Color color, BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Theme.of(context).cardColor, width: 2),
      ),
      child: const Icon(Icons.person, size: 14, color: Colors.white),
    );
  }
}
