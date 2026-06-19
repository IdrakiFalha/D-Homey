import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/app_state.dart';
import '../auth/welcome_screen.dart';
import 'edit_profile_screen.dart';
import 'privacy_security_screen.dart';
import 'notification_settings_screen.dart';
import 'help_center_screen.dart';
import 'language_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    await AuthService().signOut();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AppState().isEnglishNotifier,
      builder: (context, isEnglish, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text(isEnglish ? 'Settings' : 'Pengaturan'),
          ),
          body: ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              _buildSettingsGroup(isEnglish ? 'Account' : 'Akun'),
              _buildSettingsTile(
                context,
                icon: Icons.person_outline,
                title: isEnglish ? 'Edit Profile' : 'Edit Profil',
                subtitle: isEnglish ? 'Change name, photo, medical info' : 'Ubah nama, foto, info medis',
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen()));
                },
              ),
              _buildSettingsTile(
                context,
                icon: Icons.lock_outline,
                title: isEnglish ? 'Privacy & Security' : 'Privasi & Keamanan',
                subtitle: isEnglish ? 'Change email, password' : 'Ubah email, kata sandi',
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacySecurityScreen()));
                },
              ),
              const Divider(height: 32),
              
              _buildSettingsGroup(isEnglish ? 'Preferences' : 'Preferensi'),
              
              // Dark Mode Toggle
              ValueListenableBuilder<ThemeMode>(
                valueListenable: AppState().themeNotifier,
                builder: (context, themeMode, _) {
                  final isDark = themeMode == ThemeMode.dark;
                  return SwitchListTile(
                    secondary: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.secondary.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(isDark ? Icons.dark_mode : Icons.light_mode, color: AppTheme.primary),
                    ),
                    title: Text(isEnglish ? 'Dark Mode' : 'Mode Gelap', style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.primary)),
                    subtitle: Text(isEnglish ? 'Turn on dark theme' : 'Aktifkan tema gelap untuk kenyamanan mata', style: const TextStyle(color: AppTheme.textLight, fontSize: 12)),
                    value: isDark,
                    activeColor: AppTheme.primary,
                    onChanged: (val) {
                      AppState().toggleTheme(val);
                    },
                  );
                },
              ),

              _buildSettingsTile(
                context,
                icon: Icons.notifications_none_outlined,
                title: isEnglish ? 'Notifications' : 'Notifikasi',
                subtitle: isEnglish ? 'Chat, reports, promos' : 'Pesan chat, laporan, promo',
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationSettingsScreen()));
                },
              ),
              _buildSettingsTile(
                context,
                icon: Icons.language_outlined,
                title: isEnglish ? 'App Language' : 'Bahasa Aplikasi',
                subtitle: isEnglish ? 'English' : 'Indonesia',
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const LanguageScreen()));
                },
              ),
              const Divider(height: 32),

              _buildSettingsGroup(isEnglish ? 'Help & Support' : 'Bantuan'),
              _buildSettingsTile(
                context,
                icon: Icons.help_outline,
                title: isEnglish ? 'Help Center' : 'Pusat Bantuan',
                subtitle: isEnglish ? 'FAQ, contact admin' : 'FAQ, hubungi admin kos',
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpCenterScreen()));
                },
              ),
              const Divider(height: 32),

              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                ),
                title: Text(isEnglish ? 'Sign Out' : 'Keluar (Logout)', style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                onTap: () => _logout(context),
              ),
            ],
          ),
        );
      }
    );
  }

  Widget _buildSettingsGroup(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary, fontSize: 16),
      ),
    );
  }

  Widget _buildSettingsTile(BuildContext context, {required IconData icon, required String title, required String subtitle, required VoidCallback onTap}) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.secondary.withOpacity(0.2),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppTheme.primary),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.primary)),
      subtitle: Text(subtitle, style: const TextStyle(color: AppTheme.textLight, fontSize: 12)),
      trailing: const Icon(Icons.chevron_right, color: AppTheme.textLight),
      onTap: onTap,
    );
  }
}
