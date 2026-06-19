import 'dart:convert';
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/report_service.dart';
import '../auth/login_screen.dart';
import 'technical_report_screen.dart';
import 'settings_screen.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/responsive_layout.dart';
import '../../utils/app_theme.dart';
import '../../utils/app_translations.dart';
import '../../utils/app_state.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  Map<String, dynamic>? _userData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = _authService.currentUser;
    if (user != null) {
      final data = await _authService.getUserData(user.uid);
      if (mounted) {
        setState(() {
          _userData = data;
          _isLoading = false;
        });
      }
    }
  }

  void _goToSettings(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())).then((_) {
      _loadUserData();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return ValueListenableBuilder<bool>(
      valueListenable: AppState().isEnglishNotifier,
      builder: (context, isEnglish, child) {
        final name = _userData?['name'] ?? AppTranslations.t('Penghuni', isEnglish);
        final email = _userData?['email'] ?? '';
        final bloodType = _userData?['bloodType'] ?? '-';
        final allergies = _userData?['allergies'] ?? '-';
        final contactName = _userData?['emergencyContactName'] ?? '-';
        final contactPhone = _userData?['emergencyContactPhone'] ?? '-';
        final contactRelation = _userData?['emergencyRelation'] ?? '-';
        
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            title: Text(AppTranslations.t('Profil & Kesehatan', isEnglish)),
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            iconTheme: IconThemeData(color: Theme.of(context).primaryColor),
            actions: [
              IconButton(icon: Icon(Icons.settings_outlined, color: Theme.of(context).colorScheme.secondary), onPressed: () => _goToSettings(context)),
            ],
          ),
          body: ResponsiveLayout(
            mobile: _buildContent(context, name, email, bloodType, allergies, contactName, contactPhone, contactRelation, isEnglish),
            desktop: Center(
              child: SizedBox(
                width: 800,
                child: _buildContent(context, name, email, bloodType, allergies, contactName, contactPhone, contactRelation, isEnglish),
              ),
            ),
          ),
        );
      }
    );
  }

  Widget _buildContent(BuildContext context, String name, String email, String bloodType, String allergies, String contactName, String contactPhone, String contactRelation, bool isEnglish) {
    final String? base64Image = _userData?['profileImageBase64'];
    
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        // Info User
        Center(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Theme.of(context).colorScheme.secondary, width: 3),
                ),
                child: ClipOval(
                  child: base64Image != null && base64Image.isNotEmpty
                      ? Image.memory(
                          base64Decode(base64Image),
                          width: 96,
                          height: 96,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          width: 96,
                          height: 96,
                          color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF374151) : const Color(0xFFDFE5E7),
                          child: const Icon(Icons.person, size: 64, color: Colors.white),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              Text(name, style: Theme.of(context).textTheme.displayMedium?.copyWith(fontSize: 24, color: Theme.of(context).primaryColor)),
              const SizedBox(height: 4),
              Text(email, style: const TextStyle(color: AppTheme.textLight, fontSize: 16)),
            ],
          ),
        ),

        const SizedBox(height: 32),

        // Mood Tracker
        Text(AppTranslations.t('Mood Tracker Mingguan', isEnglish), style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Theme.of(context).primaryColor)),
        const SizedBox(height: 16),
        FutureBuilder<List<Map<String, dynamic>>>(
          future: ReportService().getWeeklyMood(_authService.currentUser!.uid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return GlassCard(
                color: Theme.of(context).cardColor.withOpacity(0.8),
                padding: const EdgeInsets.all(24),
                child: const Center(child: CircularProgressIndicator()),
              );
            }
            final data = snapshot.data ?? [];
            if (data.isEmpty) {
              return GlassCard(
                color: Theme.of(context).cardColor.withOpacity(0.8),
                padding: const EdgeInsets.all(24),
                child: Center(child: Text(AppTranslations.t('Belum ada riwayat mood. Ayo ngobrol sama Pipip!', isEnglish), style: const TextStyle(color: AppTheme.textLight))),
              );
            }
            
            final reversed = data.take(5).toList().reversed.toList();
            List<Widget> moodWidgets = reversed.map((mood) {
              final dateStr = mood['date'] as String; 
              final isStressed = mood['isStressed'] as bool;
              final date = DateTime.parse(dateStr);
              final dayNames = isEnglish ? ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'] : ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
              final dayName = dayNames[date.weekday - 1];
              final emoji = isStressed ? '😔' : '😄';
              return _buildMoodDay(dayName, emoji, context);
            }).toList();
            
            return GlassCard(
              color: Theme.of(context).cardColor.withOpacity(0.8),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: moodWidgets,
              ),
            );
          },
        ),

        const SizedBox(height: 32),

        // Darurat & Medis
        Text(AppTranslations.t('Info Medis & Darurat', isEnglish), style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Theme.of(context).primaryColor)),
        const SizedBox(height: 16),
        GlassCard(
          color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF3B1A1A).withOpacity(0.8) : const Color(0xFFFFF5F5).withOpacity(0.8),
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              _buildInfoRow(Icons.bloodtype_rounded, AppTranslations.t('Golongan Darah', isEnglish), bloodType, context),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Divider(color: Color(0xFFFFCDD2), thickness: 1),
              ),
              _buildInfoRow(Icons.coronavirus_rounded, AppTranslations.t('Alergi', isEnglish), allergies, context),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Divider(color: Color(0xFFFFCDD2), thickness: 1),
              ),
              _buildInfoRow(Icons.contact_phone_rounded, AppTranslations.t('Kontak Darurat', isEnglish) + ' ($contactRelation)', '$contactName\n$contactPhone', context),
            ],
          ),
        ),
        
        const SizedBox(height: 32),

        // Lapor Masalah Teknis
        Text(AppTranslations.t('Bantuan & Dukungan', isEnglish), style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Theme.of(context).primaryColor)),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TechnicalReportScreen()),
            );
          },
          icon: Icon(Icons.build_rounded, color: Theme.of(context).primaryColor),
          label: Text(AppTranslations.t('Lapor Masalah Teknis (Fasilitas)', isEnglish)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).cardColor,
            foregroundColor: Theme.of(context).primaryColor,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: Theme.of(context).dividerColor, width: 1.5),
            ),
            elevation: 0,
          ),
        ),

        const SizedBox(height: 32),

        // Hobi
        Text(AppTranslations.t('Hobi', isEnglish), style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Theme.of(context).primaryColor)),
        const SizedBox(height: 16),
        _buildHobbies(isEnglish, context),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildMoodDay(String day, String emoji, BuildContext context) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 28)),
        const SizedBox(height: 12),
        Text(day, style: TextStyle(fontSize: 14, color: Theme.of(context).textTheme.bodyLarge?.color, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String val, BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: Colors.redAccent, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: AppTheme.textLight, fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(val, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Theme.of(context).textTheme.bodyLarge?.color)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHobbies(bool isEnglish, BuildContext context) {
    final interests = _userData?['interests'] as List<dynamic>? ?? [];
    
    if (interests.isEmpty) {
      return Text(AppTranslations.t('Belum ada hobi yang ditambahkan.', isEnglish), style: const TextStyle(color: AppTheme.textLight, fontStyle: FontStyle.italic));
    }
    
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: interests.map((hobby) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Theme.of(context).primaryColor.withOpacity(0.3), width: 1.5)
          ),
          child: Text(hobby.toString(), style: TextStyle(fontWeight: FontWeight.w600, color: Theme.of(context).primaryColor, fontSize: 13)),
        );
      }).toList(),
    );
  }

  Widget _buildBadge(String emoji, String label, BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF3D3212) : const Color(0xFFFFF8E1), 
        borderRadius: BorderRadius.circular(24), 
        border: Border.all(color: const Color(0xFFFFD54F), width: 1.5)
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFFF57F17), fontSize: 13)),
        ],
      ),
    );
  }
}
