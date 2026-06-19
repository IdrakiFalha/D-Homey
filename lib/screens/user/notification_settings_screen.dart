import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _chatEnabled = true;
  bool _reportEnabled = true;
  bool _promoEnabled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifikasi')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          SwitchListTile(
            title: const Text('Pesan Chat Baru', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('Notifikasi saat ada pesan dari penghuni lain atau grup.', style: TextStyle(color: AppTheme.textLight, fontSize: 12)),
            activeColor: AppTheme.primary,
            value: _chatEnabled,
            onChanged: (val) => setState(() => _chatEnabled = val),
          ),
          const Divider(),
          SwitchListTile(
            title: const Text('Pembaruan Laporan Fasilitas', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('Notifikasi saat laporan teknis Anda ditindaklanjuti admin.', style: TextStyle(color: AppTheme.textLight, fontSize: 12)),
            activeColor: AppTheme.primary,
            value: _reportEnabled,
            onChanged: (val) => setState(() => _reportEnabled = val),
          ),
          const Divider(),
          SwitchListTile(
            title: const Text('Promo & Event Kos', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('Notifikasi mengenai acara kebersamaan atau diskon kos.', style: TextStyle(color: AppTheme.textLight, fontSize: 12)),
            activeColor: AppTheme.primary,
            value: _promoEnabled,
            onChanged: (val) => setState(() => _promoEnabled = val),
          ),
        ],
      ),
    );
  }
}
