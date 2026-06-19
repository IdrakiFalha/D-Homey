import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';
import '../../utils/app_state.dart';

class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppState().isEnglish ? 'App Language' : 'Bahasa Aplikasi')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            AppState().isEnglish 
              ? 'Select your preferred language.\n(Note: Currently only affects the Settings area).' 
              : 'Pilih bahasa preferensi Anda.\n(Catatan: Saat ini terjemahan baru berefek di area Pengaturan).',
            style: const TextStyle(color: AppTheme.textLight, fontSize: 13),
          ),
          const SizedBox(height: 24),
          _buildLanguageTile('Indonesian (Bahasa Indonesia)', false),
          const Divider(),
          _buildLanguageTile('English', true),
        ],
      ),
    );
  }

  Widget _buildLanguageTile(String title, bool isEnglishValue) {
    final isSelected = AppState().isEnglish == isEnglishValue;
    return ListTile(
      title: Text(title, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? AppTheme.primary : null)),
      trailing: isSelected ? const Icon(Icons.check_circle, color: AppTheme.primary) : null,
      onTap: () async {
        await AppState().toggleLanguage(isEnglishValue);
        if (mounted) setState(() {});
      },
    );
  }
}
