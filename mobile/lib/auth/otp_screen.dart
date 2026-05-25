// lib/auth/otp_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../map/map_screen.dart';
import 'package:app5/core/api_client.dart';
import 'setup_profile_screen.dart';
import 'package:app5/user/user_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

final _client = ApiClient();

class OtpScreen extends StatefulWidget {
  final String phone;

  const OtpScreen({super.key, required this.phone});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _codeController = TextEditingController();
  bool _isLoading = false;

  bool get _isValid => _codeController.text.length == 6;

  Future<void> _verifyOtp() async {
    if (!_isValid) return;
    setState(() => _isLoading = true);

    try {
      final response = await _client.post('/auth/verify-otp', {
              'phone': widget.phone,
              'code': _codeController.text.trim(),
            });


      if (!mounted) return;
      
      if (response.statusCode == 200) {
        final token = jsonDecode(response.body)['access_token'] as String;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_token', token);

        if (!mounted) return;

          // Получаем профиль
        final userResponse = await _client.get('/users/me');
        final user = jsonDecode(userResponse.body);
        await prefs.setString('user_id', user['id'].toString()); // вот сюда

        final fcmToken = await FirebaseMessaging.instance.getToken();
        print('FCM token to save: $fcmToken');
        if (fcmToken != null) {
                  final result = await UserService.updateFcmToken(fcmToken);
                  print('Update FCM result: ${result.statusCode} ${result.body}');
                }

        if (!mounted) return;

        if (user['name'] == null) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const SetupProfileScreen()),
            (_) => false,
          );
        } else {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const MapScreen()),
            (_) => false,
          );
        }
      }
} catch (e) {
      print('Error: $e');
      _showError('Нет соединения с сервером');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
    );
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              Text(
                'Введите код',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Код отправлен на +${widget.phone}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 40),
              TextField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                autofocus: true,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 28, letterSpacing: 12),
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => _verifyOtp(),
                decoration: InputDecoration(
                  hintText: '------',
                  hintStyle: TextStyle(
                    fontSize: 28,
                    letterSpacing: 12,
                    color: scheme.onSurfaceVariant.withOpacity(0.4),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: (_isValid && !_isLoading) ? _verifyOtp : null,
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Войти', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
