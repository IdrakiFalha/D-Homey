import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/room_model.dart';

class RoomService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _collectionPath = 'rooms';

  // Inisialisasi 21 kamar (3 lantai x 7 kamar) jika belum ada
  Future<void> initializeRooms() async {
    final snapshot = await _db.collection(_collectionPath).limit(1).get();
    
    // Jika belum ada data kamar sama sekali
    if (snapshot.docs.isEmpty) {
      WriteBatch batch = _db.batch();
      
      for (int floor = 1; floor <= 3; floor++) {
        for (int roomIndex = 1; roomIndex <= 7; roomIndex++) {
          // Format nomor kamar: misal Lantai 1 Kamar 1 -> '101'
          String roomNumber = '${floor}0$roomIndex';
          
          DocumentReference docRef = _db.collection(_collectionPath).doc(roomNumber);
          
          RoomModel newRoom = RoomModel(
            id: roomNumber,
            floor: floor,
            roomNumber: roomNumber,
            status: 'Tersedia', // Default status
          );
          
          batch.set(docRef, newRoom.toMap());
        }
      }
      
      await batch.commit();
    }
  }

  // Alokasikan pengguna lama (penghuni) ke kamar secara acak
  Future<void> assignExistingUsersToRandomRooms() async {
    // 1. Ambil semua penghuni
    final usersSnapshot = await _db.collection('users').where('role', isEqualTo: 'penghuni').get();
    if (usersSnapshot.docs.isEmpty) return;

    List<Map<String, dynamic>> users = usersSnapshot.docs.map((doc) => {
      'uid': doc.id,
      'name': doc.data()['name'] ?? 'Tanpa Nama',
    }).toList();

    // 2. Cek penghuni mana saja yang sudah ada di kamar
    final allRoomsSnapshot = await _db.collection(_collectionPath).get();
    final occupiedUids = allRoomsSnapshot.docs
        .map((doc) => doc.data()['occupantUid'])
        .where((uid) => uid != null)
        .toSet();

    // 3. Filter penghuni yang belum punya kamar
    users.removeWhere((u) => occupiedUids.contains(u['uid']));
    if (users.isEmpty) return; // Semua sudah punya kamar

    // 4. Cari kamar yang masih tersedia
    final availableRooms = allRoomsSnapshot.docs
        .where((doc) => doc.data()['status'] == 'Tersedia')
        .toList();

    // Acak ketersediaan kamar
    availableRooms.shuffle();

    // 5. Alokasikan
    WriteBatch batch = _db.batch();
    int assignedCount = 0;

    for (var user in users) {
      if (assignedCount >= availableRooms.length) break; // Kamar penuh
      
      var roomDoc = availableRooms[assignedCount];
      batch.update(roomDoc.reference, {
        'status': 'Terisi',
        'occupantUid': user['uid'],
        'occupantName': user['name'],
      });
      assignedCount++;
    }

    if (assignedCount > 0) {
      await batch.commit();
      print('$assignedCount penghuni lama telah dialokasikan ke kamar secara otomatis.');
    }
  }

  // Mengambil stream data kamar berdasarkan lantai
  Stream<List<RoomModel>> getRoomsByFloor(int floor) {
    return _db
        .collection(_collectionPath)
        .where('floor', isEqualTo: floor)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => RoomModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  // Memperbarui data kamar
  Future<void> updateRoom(RoomModel room) async {
    await _db.collection(_collectionPath).doc(room.id).update(room.toMap());
  }
}
