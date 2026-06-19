import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/report_model.dart';

class ReportService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Membuat laporan baru (Untuk Penghuni)
  Future<bool> createReport(ReportModel report) async {
    try {
      await _db.collection('reports').add(report.toMap());
      return true;
    } catch (e) {
      print('Error membuat laporan: $e');
      return false;
    }
  }

  // Mengambil daftar laporan (Untuk Admin)
  Stream<List<ReportModel>> getReports() {
    return _db
        .collection('reports')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ReportModel.fromMap(doc.id, doc.data()))
            .toList());
  }

  // Mengambil daftar laporan spesifik untuk satu penghuni
  Stream<List<ReportModel>> getReportsByUser(String uid) {
    return _db
        .collection('reports')
        .where('reporterUid', isEqualTo: uid)
        .snapshots()
        .map((snapshot) {
          final reports = snapshot.docs
              .map((doc) => ReportModel.fromMap(doc.id, doc.data()))
              .toList();
          reports.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return reports;
        });
  }

  // Mengubah status laporan (Untuk Admin)
  Future<void> updateReportStatus(String reportId, String newStatus) async {
    try {
      await _db.collection('reports').doc(reportId).update({'status': newStatus});
    } catch (e) {
      print('Error update status: $e');
    }
  }

  // ==============================================================
  // FITUR AI: Mencatat tren mood (stres/tidak) secara anonim
  // ==============================================================
  Future<void> logAnonymousMood(bool isStressed) async {
    try {
      await _db.collection('mood_logs').add({
        'isStressed': isStressed,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error log mood: $e');
    }
  }

  // ==============================================================
  // FITUR AI: Mencatat tren mood personal (untuk Mood Tracker Profil)
  // ==============================================================
  Future<void> logPersonalMood(String uid, bool isStressed) async {
    try {
      final dateStr = DateTime.now().toIso8601String().split('T')[0];
      await _db.collection('users').doc(uid).collection('mood_logs').doc(dateStr).set({
        'isStressed': isStressed,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error log personal mood: $e');
    }
  }

  // Mengambil 5 mood terakhir pengguna
  Future<List<Map<String, dynamic>>> getWeeklyMood(String uid) async {
    try {
      final snapshot = await _db.collection('users').doc(uid)
        .collection('mood_logs')
        .orderBy('timestamp', descending: true)
        .limit(5)
        .get();
      
      return snapshot.docs.map((doc) {
        return {
          'date': doc.id,
          'isStressed': doc.data()['isStressed'] ?? false,
        };
      }).toList();
    } catch (e) {
      print('Error get weekly mood: $e');
      return [];
    }
  }

  // Mengambil agregat mood untuk dashboard (Menghitung jumlah stres vs positif)
  Stream<Map<String, int>> getAggregateMood() {
    return _db.collection('mood_logs').snapshots().map((snapshot) {
      int stressedCount = 0;
      int positiveCount = 0;
      
      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (data['isStressed'] == true) {
          stressedCount++;
        } else {
          positiveCount++;
        }
      }
      
      return {'stressed': stressedCount, 'positive': positiveCount};
    });
  }
}
