// lib/widgets/auth_wrapper.dart
import 'package:civic_report_app/screens/auth_screen.dart';
import 'package:civic_report_app/screens/home_screen.dart'; // We will create this
import 'package:civic_report_app/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          final User? user = snapshot.data;
          return user == null ? const AuthScreen() : const HomeScreen();
        }
        // Show a loading spinner while waiting for auth state
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
    );
  }
}