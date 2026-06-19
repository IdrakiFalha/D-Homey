import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

class MigrationService {
  static Future<void> runMigrations() async {
    final prefs = await SharedPreferences.getInstance();
    final bool hasRunMigration = prefs.getBool('origin_migration_done') ?? false;

    if (!hasRunMigration) {
      try {
        final _db = FirebaseFirestore.instance;
        final usersSnap = await _db.collection('users').where('role', isEqualTo: 'penghuni').get();
        
        final List<String> cities = ['Jakarta', 'Bandung', 'Surabaya', 'Medan', 'Makassar', 'Yogyakarta', 'Semarang', 'Malang', 'Palembang', 'Denpasar'];
        final random = Random();

        for (var doc in usersSnap.docs) {
          final data = doc.data();
          if (!data.containsKey('origin') || data['origin'] == null || data['origin'] == '') {
            final randomCity = cities[random.nextInt(cities.length)];
            await doc.reference.update({
              'origin': randomCity,
            });
          }
        }
        
        await prefs.setBool('origin_migration_done', true);
        print("Migration for 'origin' completed successfully.");
      } catch (e) {
        print("Error running migration: $e");
      }
    }
  }
}
