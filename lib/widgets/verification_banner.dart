// lib/widgets/verification_banner.dart
import 'package:civic_report_app/services/auth_service.dart';
import 'package:flutter/material.dart';

class VerificationBanner extends StatefulWidget {
  const VerificationBanner({super.key});

  @override
  State<VerificationBanner> createState() => _VerificationBannerState();
}

class _VerificationBannerState extends State<VerificationBanner> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  void _resendEmail() async {
    setState(() => _isLoading = true);
    try {
      await _authService.resendVerificationEmail();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A new verification email has been sent!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send email: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.yellow[100],
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Text(
            'Please verify your email address.',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.yellow[800],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'You cannot submit new reports until your email is verified.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.yellow[800]),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _isLoading ? null : _resendEmail,
            child: Text(_isLoading ? 'Sending...' : 'Resend Verification Email'),
          ),
        ],
      ),
    );
  }
}