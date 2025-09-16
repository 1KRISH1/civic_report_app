// lib/screens/report_list_screen.dart
import 'package:civic_report_app/screens/report_submission_screen.dart';
import 'package:civic_report_app/services/auth_service.dart';
import 'package:flutter/material.dart';
import '../models/report.dart';
import '../services/firestore_service.dart';
import '../widgets/report_card.dart';
import '../widgets/verification_banner.dart';

class ReportListScreen extends StatefulWidget {
  const ReportListScreen({super.key});

  @override
  State<ReportListScreen> createState() => _ReportListScreenState();
}

class _ReportListScreenState extends State<ReportListScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();

  /// Navigates to the submission screen in "edit mode" for the given report.
  void _navigateToEditScreen(Report report) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ReportSubmissionScreen(report: report),
      ),
    );
  }

  /// Deletes a report and shows a confirmation or error message.
  void _deleteReport(String reportId, String? imageUrl) async {
    try {
      await _firestoreService.deleteReport(reportId: reportId, imageUrl: imageUrl);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Report deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete report: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    final isVerified = user?.emailVerified ?? false;

    return Column(
      children: [
        // Show banner if the user's email is not verified
        if (!isVerified) const VerificationBanner(),

        // Use Expanded to make the list scrollable within the Column
        Expanded(
          child: StreamBuilder<List<Report>>(
            stream: _firestoreService.getReports(),
            builder: (context, snapshot) {
              // 1. Handle loading state
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              // 2. Handle error state
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              // 3. Handle no data state
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(
                  child: Text(
                    'You have no submitted reports yet.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                );
              }

              // 4. Display the list of reports
              final reports = snapshot.data!;
              return ListView.builder(
                itemCount: reports.length,
                itemBuilder: (context, index) {
                  final report = reports[index];
                  // Pass the handler functions to the ReportCard
                  return ReportCard(
                    report: report,
                    onEditPressed: () => _navigateToEditScreen(report),
                    onDeletePressed: () => _deleteReport(report.id, report.imageUrl),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}