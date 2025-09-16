// lib/models/report.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Report {
  final String id;
  final String category;
  final String description;
  final String location;
  final String status;
  final String? imageUrl;
  final Timestamp submittedAt;

  Report({
    required this.id,
    required this.category,
    required this.description,
    required this.location,
    required this.status,
    this.imageUrl,
    required this.submittedAt,
  });

  // Factory constructor to create a Report from a Firestore document
  factory Report.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Report(
      id: doc.id,
      category: data['category'] ?? 'Unknown',
      description: data['description'] ?? '',
      location: data['location'] ?? 'No location provided',
      status: data['status'] ?? 'New',
      imageUrl: data['imageUrl'], // Can be null
      submittedAt: data['submittedAt'] ?? Timestamp.now(),
    );
  }
}