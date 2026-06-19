// Model Data untuk Mood Tracker (Kesejahteraan Mental)

class MoodModel {
  final String id;
  final String userUid;
  final int moodScore; // 1 (Sangat Buruk) s.d 5 (Sangat Baik)
  final String note; // Catatan opsional kenapa merasa demikian
  final DateTime date; // Tanggal pengisian (biasanya 1x sehari)

  const MoodModel({
    required this.id,
    required this.userUid,
    required this.moodScore,
    this.note = '',
    required this.date,
  });

  factory MoodModel.fromMap(Map<String, dynamic> map, String docId) {
    return MoodModel(
      id: docId,
      userUid: map['userUid'] ?? '',
      moodScore: map['moodScore'] ?? 3,
      note: map['note'] ?? '',
      date: (map['date'] as dynamic).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userUid': userUid,
      'moodScore': moodScore,
      'note': note,
      'date': date,
    };
  }
}
