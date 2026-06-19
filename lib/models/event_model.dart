// Model Data untuk Agenda Sosial (Kegiatan Bersama)

class EventModel {
  final String id;
  final String title;
  final String description;
  final DateTime dateTime;
  final String location;
  
  final String creatorUid;
  final String creatorName;
  
  final List<String> participantsUid; // Daftar UID penghuni yang ikut
  final bool isVerified; // True jika disetujui Admin / Penjaga Kos
  final bool isAiGenerated; // True jika direkomendasikan oleh AI
  final DateTime createdAt;

  const EventModel({
    required this.id,
    required this.title,
    required this.description,
    required this.dateTime,
    required this.location,
    required this.creatorUid,
    required this.creatorName,
    this.participantsUid = const [],
    this.isVerified = false,
    this.isAiGenerated = false,
    required this.createdAt,
  });

  factory EventModel.fromMap(Map<String, dynamic> map, String docId) {
    return EventModel(
      id: docId,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      dateTime: (map['dateTime'] as dynamic).toDate(),
      location: map['location'] ?? '',
      creatorUid: map['creatorUid'] ?? '',
      creatorName: map['creatorName'] ?? '',
      participantsUid: List<String>.from(map['participantsUid'] ?? []),
      isVerified: map['isVerified'] ?? false,
      isAiGenerated: map['isAiGenerated'] ?? false,
      createdAt: (map['createdAt'] as dynamic).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'dateTime': dateTime,
      'location': location,
      'creatorUid': creatorUid,
      'creatorName': creatorName,
      'participantsUid': participantsUid,
      'isVerified': isVerified,
      'isAiGenerated': isAiGenerated,
      'createdAt': createdAt,
    };
  }
}
