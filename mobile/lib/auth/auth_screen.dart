// lib/auth/auth_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'otp_screen.dart';
import 'package:app5/core/api_client.dart';

final _client = ApiClient();

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _phoneController = TextEditingController();
  bool _isLoading = false;

  String get _rawPhone => _phoneController.text.replaceAll(RegExp(r'\D'), '');

  bool get _isValid {
    final d = _rawPhone;
    return (d.startsWith('7') || d.startsWith('8')) && d.length == 11;
  }

  Future<void> _sendOtp() async {
    if (!_isValid) return;
    setState(() => _isLoading = true);

    // Приводим 8... -> 7...
    final phone = _rawPhone.startsWith('8')
        ? '7${_rawPhone.substring(1)}'
        : _rawPhone;

    try {
      final response = await _client.post('/auth/send-otp', {
              'phone': phone, 
            });
      // final response = await http.post(
      //   Uri.parse('$_baseUrl/auth/send-otp'),
      //   headers: {'Content-Type': 'application/json'},
      //   body: jsonEncode({'phone': phone}),
      // );

      if (!mounted) return;

      if (response.statusCode == 200) {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => OtpScreen(phone: phone)));
      } else {
        final msg = jsonDecode(response.body)['detail'] ?? 'Ошибка сервера';
        _showError(msg.toString());
      }
    } catch (_) {
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
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 80),
              Text(
                'Вход',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Введите номер телефона — мы пришлём код',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 40),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d\+\-\(\) ]')),
                ],
                autofocus: true,
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => _sendOtp(),
                decoration: InputDecoration(
                  labelText: 'Номер телефона',
                  hintText: '+7 900 000 00 00',
                  prefixIcon: const Icon(Icons.phone_outlined),
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
                  onPressed: (_isValid && !_isLoading) ? _sendOtp : null,
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
                      : const Text(
                          'Получить код',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
