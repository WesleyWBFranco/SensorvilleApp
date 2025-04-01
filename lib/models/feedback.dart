import 'package:cloud_firestore/cloud_firestore.dart';

class FeedbackMessage {
  final String? userId;
  final String message;
  final Timestamp timestamp;
  String status;
  final List<String> imageUrls;
  String? id;

  FeedbackMessage({
    this.userId,
    required this.message,
    required this.timestamp,
    this.status = 'unread',
    this.imageUrls = const [],
    this.id,
  });

  factory FeedbackMessage.fromFirestore(Map<String, dynamic> data) {
    final statusFromData = data['status'];
    return FeedbackMessage(
      userId: data['userId'],
      message: data['message'] ?? '',
      timestamp: data['timestamp'] ?? Timestamp.now(),
      status: statusFromData is String ? statusFromData : 'unread',
      imageUrls: (data['imageUrls'] as List<dynamic>?)?.cast<String>() ?? [],
      id: null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'message': message,
      'timestamp': timestamp,
      'status': status,
      'imageUrls': imageUrls,
    };
  }
}

extension FeedbackMessageWithId on FeedbackMessage {
  FeedbackMessage copyWith({
    String? id,
    String? userId,
    String? message,
    Timestamp? timestamp,
    String? status,
    List<String>? imageUrls,
  }) {
    return FeedbackMessage(
      userId: userId ?? this.userId,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      imageUrls: imageUrls ?? this.imageUrls,
      id: id ?? this.id,
    );
  }
}
