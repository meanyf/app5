// lib/profile/profile_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:app5/core/api_client.dart';
import 'package:app5/auth/auth_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _client = ApiClient();
  final _nameController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  String? _name;
  String? _phone;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _logout() async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthScreen()),
        (_) => false,
      );
    }

  Future<void> _loadProfile() async {
    try {
      final response = await _client.get('/users/me');
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        setState(() {
          _name = json['name'] as String?;
          _phone = json['phone'] as String?;
          _nameController.text = _name ?? '';
          _isLoading = false;
        });
      }
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveName() async {
    final newName = _nameController.text.trim();
    if (newName.length < 2) return;
    setState(() => _isSaving = true);

    try {
      final response = await _client.patch('/users/me', {'name': newName});
      if (!mounted) return;
      if (response.statusCode == 200) {
        setState(() => _name = newName);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Имя обновлено')));
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ошибка сохранения'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Профиль'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      backgroundColor: scheme.surface,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    Center(
                      child: CircleAvatar(
                        radius: 40,
                        backgroundColor: scheme.primaryContainer,
                        child: Text(
                          _name?.isNotEmpty == true
                              ? _name![0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            fontSize: 32,
                            color: scheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Телефон',
                      style: TextStyle(
                        fontSize: 12,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(_phone ?? '—', style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 24),
                    Text(
                      'Имя',
                      style: TextStyle(
                        fontSize: 12,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        hintText: 'Введите имя',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton(
                        onPressed: _isSaving ? null : _saveName,
                        style: FilledButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Сохранить',
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
