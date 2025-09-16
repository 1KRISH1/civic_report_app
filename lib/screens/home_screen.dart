// lib/screens/home_screen.dart
import 'package:civic_report_app/screens/report_list_screen.dart';
// THIS IS THE CORRECTED LINE vvvv
import 'package:civic_report_app/screens/report_submission_screen.dart';
import 'package:civic_report_app/services/auth_service.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();
    final user = authService.currentUser;
    final isVerified = user?.emailVerified ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Reports'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => authService.signOut(),
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: const ReportListScreen(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (!isVerified) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please verify your email to submit a new report.'),
                backgroundColor: Colors.orange,
              ),
            );
            return;
          }
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const ReportSubmissionScreen(),
            ),
          );
        },
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        tooltip: 'Submit a new report',
        child: const Icon(Icons.add),
      ),
    );
  }
}