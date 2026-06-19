import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// AuthService menangani autentikasi dan menyimpan data pengguna ke Firestore

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // FUNGSI DAFTAR AKUN BARU
  Future<User?> registerUser({
    required String email,
    required String password,
    required String name,
    required String role, // 'penghuni' atau 'admin'
    String bloodType = '-',
    String allergies = '-',
    String emergencyContactName = '-',
    String emergencyContactPhone = '-',
    String emergencyRelation = '-',
    String origin = 'Tidak diketahui',
  }) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = result.user;

      if (user != null) {
        // Simpan ke Firestore sesuai struktur UserModel
        await _db.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'name': name,
          'email': email,
          'role': role,
          'bloodType': bloodType,
          'allergies': allergies,
          'emergencyContactName': emergencyContactName,
          'emergencyContactPhone': emergencyContactPhone,
          'emergencyRelation': emergencyRelation,
          'origin': origin,
          'streakPoints': 0,
          'badges': [],
          'interests': [],

          'profileImageBase64': null, // Tambahkan default
          'createdAt': DateTime.now(),
        });

        if (role == 'penghuni') {
          await _addToCommunityGroup(user.uid, name);
        }
      }

      return user;
    } catch (e) {
      print('Error saat daftar: $e');
      return null;
    }
  }

  // FUNGSI LOGIN
  Future<User?> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } catch (e) {
      print('Error saat login: $e');
      return null;
    }
  }

  // FUNGSI LOGOUT
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // AMBIL DATA PROFIL USER (Untuk cek role saat login)
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      DocumentSnapshot doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('Error ambil data user: $e');
      return null;
    }
  }

  // UPDATE PROFIL USER (termasuk foto Base64)
  Future<bool> updateUserProfile({
    required String name,
    required String emergencyContactName,
    required String emergencyContactPhone,
    required String emergencyRelation,
    String? profileImageBase64,
    List<String>? interests,
    String? bloodType,
    String? allergies,
    String? origin,
  }) async {
    try {
      final user = currentUser;
      if (user == null) return false;

      Map<String, dynamic> updateData = {
        'name': name,
        'emergencyContactName': emergencyContactName,
        'emergencyContactPhone': emergencyContactPhone,
        'emergencyRelation': emergencyRelation,
      };

      if (profileImageBase64 != null) {
        updateData['profileImageBase64'] = profileImageBase64;
      }
      if (interests != null) {
        updateData['interests'] = interests;
      }
      if (bloodType != null) {
        updateData['bloodType'] = bloodType;
      }
      if (allergies != null) {
        updateData['allergies'] = allergies;
      }
      if (origin != null) {
        updateData['origin'] = origin;
      }

      await _db.collection('users').doc(user.uid).update(updateData);
      return true;
    } catch (e) {
      print('Error update profile: $e');
      return false;
    }
  }

  // MASUKKAN PENGHUNI BARU KE COMMUNITY GROUP
  Future<void> _addToCommunityGroup(String uid, String name) async {
    try {
      DocumentReference groupRef = _db.collection('chats').doc('community_group');
      DocumentSnapshot groupDoc = await groupRef.get();

      if (!groupDoc.exists) {
        await groupRef.set({
          'isGroup': true,
          'groupName': 'Grup Komunitas Kos',
          'participants': [uid],
          'lastMessage': '$name bergabung ke grup',
          'lastMessageTime': FieldValue.serverTimestamp(),
          'streakCount': 0,
        });
      } else {
        await groupRef.update({
          'participants': FieldValue.arrayUnion([uid]),
        });
      }
    } catch (e) {
      print('Error menambahkan ke grup: $e');
    }
  }

  // MENGAMBIL AGREGAT HOBI SEMUA PENGHUNI
  Future<Map<String, int>> getAggregateInterests() async {
    try {
      final snapshot = await _db.collection('users').where('role', isEqualTo: 'penghuni').get();
      Map<String, int> aggregate = {};
      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (data.containsKey('interests')) {
          List<dynamic> interests = data['interests'];
          for (var interest in interests) {
            final String key = interest.toString();
            aggregate[key] = (aggregate[key] ?? 0) + 1;
          }
        }
      }
      return aggregate;
    } catch (e) {
      print('Error get aggregate interests: $e');
      return {};
    }
  }
}