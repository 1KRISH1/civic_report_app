// lib/services/firestore_service.dart
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../models/report.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // This must match your Firebase project's collection path structure.
  final String _collectionPath =
      'artifacts/civicreporting-b8d33/public/data/reports';

  /// Fetches a real-time stream of reports for the currently logged-in user.
  Stream<List<Report>> getReports() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value([]); // Return empty stream if no user is logged in
    }

    return _db
        .collection(_collectionPath)
        .where('userId', isEqualTo: user.uid)
        .orderBy('submittedAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Report.fromFirestore(doc)).toList());
  }

  /// Creates a new report, uploads an image if provided, and saves it to Firestore.
  Future<void> submitReport({
    required String category,
    required String description,
    required String location,
    XFile? imageFile,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    String? imageUrl;

    // 1. Upload image to Firebase Storage if one is provided
    if (imageFile != null) {
      final filePath =
          'reports/${user.uid}/${DateTime.now().millisecondsSinceEpoch}_${imageFile.name}';
      final storageRef = _storage.ref().child(filePath);
      await storageRef.putFile(File(imageFile.path));
      imageUrl = await storageRef.getDownloadURL();
    }

    // 2. Add the report data to Firestore
    await _db.collection(_collectionPath).add({
      'category': category,
      'description': description,
      'location': location,
      'imageUrl': imageUrl,
      'userId': user.uid,
      'userEmail': user.email,
      'status': 'New',
      'submittedAt': FieldValue.serverTimestamp(),
      'log': [
        // Corrected the typo in the timestamp method below
        {'type': 'Submitted', 'timestamp': DateTime.now().toIso8601String()}
      ],
    });
  }

  /// Updates an existing report's text fields in Firestore.
  Future<void> updateReport({
    required String reportId,
    required String category,
    required String description,
    required String location,
  }) async {
    final reportRef = _db.collection(_collectionPath).doc(reportId);
    await reportRef.update({
      'category': category,
      'description': description,
      'location': location,
    });
  }

  /// Deletes a report document from Firestore and its associated image from Storage.
  Future<void> deleteReport(
      {required String reportId, String? imageUrl}) async {
    // 1. Delete the document from Firestore
    final reportRef = _db.collection(_collectionPath).doc(reportId);
    await reportRef.delete();

    // 2. Delete the associated image from Firebase Storage if it exists
    if (imageUrl != null && imageUrl.isNotEmpty) {
      try {
        final storageRef = _storage.refFromURL(imageUrl);
        await storageRef.delete();
      } catch (e) {
        // Removed the print statement to follow best practices.
        // You can add more robust logging here if needed.
      }
    }
  }
}