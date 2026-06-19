class RoomModel {
  final String id;
  final int floor;
  final String roomNumber;
  final String status; // 'Tersedia', 'Terisi', 'Perbaikan'
  final int price;
  final String? occupantName;
  final String? occupantUid;
  final String? requestedByName;
  final String? requestedByUid;

  const RoomModel({
    required this.id,
    required this.floor,
    required this.roomNumber,
    this.status = 'Tersedia',
    this.price = 1500000,
    this.occupantName,
    this.occupantUid,
    this.requestedByName,
    this.requestedByUid,
  });

  factory RoomModel.fromMap(Map<String, dynamic> map, String documentId) {
    return RoomModel(
      id: documentId,
      floor: map['floor'] ?? 1,
      roomNumber: map['roomNumber'] ?? '',
      status: map['status'] ?? 'Tersedia',
      price: map['price'] ?? 1500000,
      occupantName: map['occupantName'],
      occupantUid: map['occupantUid'],
      requestedByName: map['requestedByName'],
      requestedByUid: map['requestedByUid'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'floor': floor,
      'roomNumber': roomNumber,
      'status': status,
      'price': price,
      'occupantName': occupantName,
      'occupantUid': occupantUid,
      'requestedByName': requestedByName,
      'requestedByUid': requestedByUid,
    };
  }

  RoomModel copyWith({
    String? id,
    int? floor,
    String? roomNumber,
    String? status,
    int? price,
    String? occupantName,
    String? occupantUid,
    String? requestedByName,
    String? requestedByUid,
    bool clearRequest = false,
    bool clearOccupant = false,
  }) {
    return RoomModel(
      id: id ?? this.id,
      floor: floor ?? this.floor,
      roomNumber: roomNumber ?? this.roomNumber,
      status: status ?? this.status,
      price: price ?? this.price,
      occupantName: clearOccupant ? null : (occupantName ?? this.occupantName),
      occupantUid: clearOccupant ? null : (occupantUid ?? this.occupantUid),
      requestedByName: clearRequest ? null : (requestedByName ?? this.requestedByName),
      requestedByUid: clearRequest ? null : (requestedByUid ?? this.requestedByUid),
    );
  }
}
