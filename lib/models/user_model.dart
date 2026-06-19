// Model Data untuk Pengguna (Penghuni & Admin)

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String role; // 'penghuni' atau 'admin'

  // Data Medis (Penting untuk keadaan darurat)
  final String bloodType;
  final String allergies;

  // Kontak Darurat
  final String emergencyContactName;
  final String emergencyContactPhone;
  final String emergencyRelation; // contoh: 'Ayah', 'Ibu', 'Wali'

  // Sistem Gamifikasi / Kesejahteraan
  final int streakPoints; // Poin keaktifan sosial (Tanya Kabar)
  final List<String> badges; // Lencana penghargaan dari pemilik kos
  final List<String> interests; // Minat/hobi penghuni
  final DateTime createdAt;

  const UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.bloodType = '-',
    this.allergies = '-',
    this.emergencyContactName = '-',
    this.emergencyContactPhone = '-',
    this.emergencyRelation = '-',
    this.streakPoints = 0,
    this.badges = const [],
    this.interests = const [],
    required this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String docId) {
    return UserModel(
      uid: docId,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? 'penghuni',
      bloodType: map['bloodType'] ?? '-',
      allergies: map['allergies'] ?? '-',
      emergencyContactName: map['emergencyContactName'] ?? '-',
      emergencyContactPhone: map['emergencyContactPhone'] ?? '-',
      emergencyRelation: map['emergencyRelation'] ?? '-',
      streakPoints: map['streakPoints'] ?? 0,
      badges: List<String>.from(map['badges'] ?? []),
      interests: List<String>.from(map['interests'] ?? []),
      createdAt: map['createdAt'] != null 
          ? (map['createdAt'] as dynamic).toDate() 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'role': role,
      'bloodType': bloodType,
      'allergies': allergies,
      'emergencyContactName': emergencyContactName,
      'emergencyContactPhone': emergencyContactPhone,
      'emergencyRelation': emergencyRelation,
      'streakPoints': streakPoints,
      'badges': badges,
      'interests': interests,
      'createdAt': createdAt,
    };
  }
}
