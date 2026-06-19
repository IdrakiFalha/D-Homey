import 'package:cloud_firestore/cloud_firestore.dart';

class ReportModel {
  final String id;
  final String reporterUid;
  final String reporterName;
  final String category;
  final String description;
  final String status; // 'pending', 'proses', 'selesai'
  final DateTime createdAt;
  final String? mediaUrl;
  final String? mediaType; // 'image' or 'video'

  ReportModel({
    required this.id,
    required this.reporterUid,
    required this.reporterName,
    required this.category,
    required this.description,
    this.status = 'pending',
    required this.createdAt,
    this.mediaUrl,
    this.mediaType,
  });

  factory ReportModel.fromMap(String id, Map<String, dynamic> data) {
    return ReportModel(
      id: id,
      reporterUid: data['reporterUid'] ?? '',
      reporterName: data['reporterName'] ?? 'Anonim',
      category: data['category'] ?? 'Lainnya',
      description: data['description'] ?? '',
      status: data['status'] ?? 'pending',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      mediaUrl: data['mediaUrl'],
      mediaType: data['mediaType'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'reporterUid': reporterUid,
      'reporterName': reporterName,
      'category': category,
      'description': description,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      if (mediaUrl != null) 'mediaUrl': mediaUrl,
      if (mediaType != null) 'mediaType': mediaType,
    };
  }
}
