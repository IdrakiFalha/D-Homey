import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rxdart/rxdart.dart';

class ChatService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Mendapatkan daftar semua user kecuali user saat ini
  Stream<List<Map<String, dynamic>>> getUsersStream() {
    return _db.collection('users').snapshots().map((snapshot) {
      return snapshot.docs
          .where((doc) => doc.id != _auth.currentUser?.uid)
          .map((doc) => doc.data())
          .toList();
    });
  }

  // Menggabungkan users dan chat terakhir mereka, lalu mengurutkannya
  Stream<List<Map<String, dynamic>>> getUsersWithChatStream() {
    if (_auth.currentUser == null) return const Stream.empty();
    final String currentUserId = _auth.currentUser!.uid;

    Stream<List<Map<String, dynamic>>> usersStream = _db.collection('users').snapshots().map((snapshot) {
      return snapshot.docs
          .where((doc) => doc.id != currentUserId)
          .map((doc) => doc.data())
          .toList();
    });

    Stream<List<Map<String, dynamic>>> chatsStream = _db
        .collection('chats')
        .where('participants', arrayContains: currentUserId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());

    return Rx.combineLatest2(usersStream, chatsStream, (List<Map<String, dynamic>> users, List<Map<String, dynamic>> chats) {
      for (var user in users) {
        var chat = chats.firstWhere(
            (c) => (c['participants'] as List).contains(user['uid']), 
            orElse: () => <String, dynamic>{});
        
        user['lastMessage'] = chat['lastMessage'];
        user['lastMessageTime'] = chat['lastMessageTime'] as Timestamp?;
        user['streakCount'] = chat['streakCount'] ?? 0;
      }

      users.sort((a, b) {
        Timestamp? timeA = a['lastMessageTime'];
        Timestamp? timeB = b['lastMessageTime'];
        if (timeA == null && timeB == null) return 0;
        if (timeA == null) return 1;
        if (timeB == null) return -1;
        return timeB.compareTo(timeA); // descending
      });

      return users;
    });
  }

  // Membuat ID chat room yang unik untuk dua user
  String getChatRoomId(String userId1, String userId2) {
    List<String> ids = [userId1, userId2];
    ids.sort(); // Memastikan urutan selalu sama (misal A_B selalu sama dengan B_A)
    return ids.join('_');
  }

  // Mengirim pesan
  Future<void> sendMessage(String receiverId, String message) async {
    final String currentUserId = _auth.currentUser!.uid;
    final String chatRoomId = getChatRoomId(currentUserId, receiverId);

    // Cek role pengirim dan penerima
    DocumentSnapshot senderDoc = await _db.collection('users').doc(currentUserId).get();
    DocumentSnapshot receiverDoc = await _db.collection('users').doc(receiverId).get();
    
    String senderRole = 'penghuni';
    if (senderDoc.exists) {
      senderRole = (senderDoc.data() as Map<String, dynamic>)['role'] ?? 'penghuni';
    }
    String receiverRole = 'penghuni';
    if (receiverDoc.exists) {
      receiverRole = (receiverDoc.data() as Map<String, dynamic>)['role'] ?? 'penghuni';
    }

    bool isAdminChat = senderRole == 'admin' || receiverRole == 'admin';

    // Buat data pesan
    Map<String, dynamic> messageData = {
      'senderId': currentUserId,
      'receiverId': receiverId,
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
    };

    // Tambahkan pesan ke subkoleksi messages
    await _db
        .collection('chats')
        .doc(chatRoomId)
        .collection('messages')
        .add(messageData);

    // Ambil metadata chatroom untuk perbarui streak dan info pesan terakhir
    DocumentReference chatRoomRef = _db.collection('chats').doc(chatRoomId);
    
    await _db.runTransaction((transaction) async {
      DocumentSnapshot chatSnapshot = await transaction.get(chatRoomRef);
      
      int currentStreak = 0;
      String trackingDate = '';
      List<dynamic> senders = [];
      String streakDate = '';

      if (chatSnapshot.exists) {
        var data = chatSnapshot.data() as Map<String, dynamic>;
        currentStreak = data['streakCount'] ?? 0;
        trackingDate = data['currentTrackingDate'] ?? '';
        senders = data['dailySenders'] ?? [];
        streakDate = data['lastStreakDate'] ?? '';
      }

      DateTime now = DateTime.now();
      String todayStr = "\${now.year}-\${now.month.toString().padLeft(2, '0')}-\${now.day.toString().padLeft(2, '0')}";
      DateTime yesterday = now.subtract(const Duration(days: 1));
      String yesterdayStr = "\${yesterday.year}-\${yesterday.month.toString().padLeft(2, '0')}-\${yesterday.day.toString().padLeft(2, '0')}";

      if (!isAdminChat) {
        if (trackingDate != todayStr) {
          if (streakDate != yesterdayStr && streakDate != todayStr && streakDate.isNotEmpty) {
            currentStreak = 0; // Terlewat 1 hari, padam
          }
          trackingDate = todayStr;
          senders = [];
        }

        if (!senders.contains(currentUserId)) {
          senders.add(currentUserId);
        }

        if (senders.length >= 2 && streakDate != todayStr) {
          currentStreak++;
          streakDate = todayStr;
          
          // Tambahkan streakPoints di koleksi users
          transaction.update(_db.collection('users').doc(currentUserId), {'streakPoints': FieldValue.increment(1)});
          transaction.update(_db.collection('users').doc(receiverId), {'streakPoints': FieldValue.increment(1)});
        }
      }

      // Perbarui dokumen chat room
      transaction.set(chatRoomRef, {
        'lastMessage': message,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastSenderId': currentUserId,
        if (!isAdminChat) 'streakCount': currentStreak,
        if (!isAdminChat) 'currentTrackingDate': trackingDate,
        if (!isAdminChat) 'dailySenders': senders,
        if (!isAdminChat) 'lastStreakDate': streakDate,
        'participants': [currentUserId, receiverId],
      }, SetOptions(merge: true));
    });
  }

  // Mendapatkan stream pesan dari chat room
  Stream<QuerySnapshot> getMessagesStream(String receiverId) {
    if (_auth.currentUser == null) return const Stream.empty();
    
    final String currentUserId = _auth.currentUser!.uid;
    final String chatRoomId = getChatRoomId(currentUserId, receiverId);

    return _db
        .collection('chats')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  // Mendapatkan stream metadata chat room (seperti streak dan pesan terakhir)
  Stream<DocumentSnapshot> getChatRoomStream(String receiverId) {
    if (_auth.currentUser == null) return const Stream.empty();

    final String currentUserId = _auth.currentUser!.uid;
    final String chatRoomId = getChatRoomId(currentUserId, receiverId);

    return _db.collection('chats').doc(chatRoomId).snapshots();
  }

  // --- LOGIKA GROUP CHAT COMMUNITY ---

  Future<void> sendGroupMessage(String message) async {
    final String currentUserId = _auth.currentUser!.uid;
    const String groupId = 'community_group';

    Map<String, dynamic> messageData = {
      'senderId': currentUserId,
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
    };

    await _db
        .collection('chats')
        .doc(groupId)
        .collection('messages')
        .add(messageData);

    DocumentReference groupRef = _db.collection('chats').doc(groupId);

    await _db.runTransaction((transaction) async {
      DocumentSnapshot groupSnapshot = await transaction.get(groupRef);

      DateTime now = DateTime.now();
      String todayStr = "\${now.year}-\${now.month.toString().padLeft(2, '0')}-\${now.day.toString().padLeft(2, '0')}";
      DateTime yesterday = now.subtract(const Duration(days: 1));
      String yesterdayStr = "\${yesterday.year}-\${yesterday.month.toString().padLeft(2, '0')}-\${yesterday.day.toString().padLeft(2, '0')}";

      String trackingDate = '';
      List<dynamic> senders = [];
      String streakDate = '';
      int streakCount = 0;

      if (groupSnapshot.exists) {
        var data = groupSnapshot.data() as Map<String, dynamic>;
        trackingDate = data['currentTrackingDate'] ?? '';
        senders = data['dailySenders'] ?? [];
        streakDate = data['lastStreakDate'] ?? '';
        streakCount = data['streakCount'] ?? 0;
      }

      if (trackingDate != todayStr) {
        if (streakDate != yesterdayStr && streakDate != todayStr && streakDate.isNotEmpty) {
          streakCount = 0; // Streak broken
        }
        trackingDate = todayStr;
        senders = [];
      }

      if (!senders.contains(currentUserId)) {
        senders.add(currentUserId);
      }

      if (senders.length >= 3 && streakDate != todayStr) {
        streakCount++;
        streakDate = todayStr;
      }

      transaction.set(groupRef, {
        'lastMessage': message,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'streakCount': streakCount,
        'currentTrackingDate': trackingDate,
        'dailySenders': senders,
        'lastStreakDate': streakDate,
        'isGroup': true,
      }, SetOptions(merge: true));
    });
  }

  Stream<QuerySnapshot> getGroupMessagesStream() {
    return _db
        .collection('chats')
        .doc('community_group')
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  Stream<DocumentSnapshot> getGroupChatStream() {
    return _db.collection('chats').doc('community_group').snapshots();
  }

  // --- LOGIKA TAMBAHAN (HAPUS, BERSIHKAN, BLOKIR, TEMA) ---

  Future<void> deleteMessage(String receiverId, String messageId, {bool isGroup = false}) async {
    final String currentUserId = _auth.currentUser!.uid;
    final String chatRoomId = isGroup ? 'community_group' : getChatRoomId(currentUserId, receiverId);

    await _db
        .collection('chats')
        .doc(chatRoomId)
        .collection('messages')
        .doc(messageId)
        .delete();
  }

  Future<void> clearChat(String receiverId, {bool isGroup = false}) async {
    final String currentUserId = _auth.currentUser!.uid;
    final String chatRoomId = isGroup ? 'community_group' : getChatRoomId(currentUserId, receiverId);

    var snapshots = await _db.collection('chats').doc(chatRoomId).collection('messages').get();
    for (var doc in snapshots.docs) {
      await doc.reference.delete();
    }
    
    await _db.collection('chats').doc(chatRoomId).set({
      'lastMessage': 'Obrolan telah dibersihkan',
    }, SetOptions(merge: true));
  }

  Future<void> toggleBlockUser(String blockUserId) async {
    final String currentUserId = _auth.currentUser!.uid;
    var userDoc = await _db.collection('users').doc(currentUserId).get();
    List<dynamic> blockedUsers = [];
    if (userDoc.exists) {
      blockedUsers = userDoc.data()?['blockedUsers'] ?? [];
    }
    
    if (blockedUsers.contains(blockUserId)) {
      blockedUsers.remove(blockUserId);
    } else {
      blockedUsers.add(blockUserId);
    }
    
    await _db.collection('users').doc(currentUserId).update({
      'blockedUsers': blockedUsers,
    });
  }

  Stream<bool> isUserBlockedStream(String targetUserId) {
    if (_auth.currentUser == null) return Stream.value(false);
    return _db.collection('users').doc(_auth.currentUser!.uid).snapshots().map((doc) {
      if (!doc.exists) return false;
      List<dynamic> blockedUsers = doc.data()?['blockedUsers'] ?? [];
      return blockedUsers.contains(targetUserId);
    });
  }
  
  Stream<bool> amIBlockedStream(String targetUserId) {
    if (_auth.currentUser == null) return Stream.value(false);
    return _db.collection('users').doc(targetUserId).snapshots().map((doc) {
      if (!doc.exists) return false;
      List<dynamic> blockedUsers = doc.data()?['blockedUsers'] ?? [];
      return blockedUsers.contains(_auth.currentUser!.uid);
    });
  }

  Future<void> updateChatTheme(String receiverId, int themeIndex, {bool isGroup = false}) async {
    final String currentUserId = _auth.currentUser!.uid;
    final String chatRoomId = isGroup ? 'community_group' : getChatRoomId(currentUserId, receiverId);
    
    await _db.collection('chats').doc(chatRoomId).set({
      'themeIndex': themeIndex,
    }, SetOptions(merge: true));
  }
}
