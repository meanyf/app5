// lib/profile/profile_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:app5/core/api_client.dart';
import 'package:app5/auth/auth_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../user/user.dart';
import '../user/user_service.dart';
import '../core/media_service.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _client = ApiClient();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();


  bool _isLoading = true;
  bool _isSaving = false;
  UserProfile? _profile; 


  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

Future<void> _pickAndUploadAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked == null) return;

    setState(() => _isLoading = true);
    try {
      final media = await MediaService.uploadMedia(File(picked.path));
      final patch = await _client.patch('/users/me', {'avatar_url': media.url});
      if (patch.statusCode == 200 && mounted) {
        setState(() => _profile = UserProfile.fromJson(jsonDecode(patch.body)));
        UserService.invalidate(_profile!.id);
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ошибка загрузки фото'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
        setState(() {
          _profile = UserProfile.fromJson(jsonDecode(response.body));
          _nameController.text = _profile?.name ?? '';
          _descriptionController.text = _profile?.description ?? '';
          _isLoading = false;
        });
      }
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

Future<void> _saveProfile() async {
    final newName = _nameController.text.trim();
    if (newName.length < 2) return;
    setState(() => _isSaving = true);

    try {
      final response = await _client.patch('/users/me', {
        'name': newName,
        'description': _descriptionController.text.trim(),
      });
      if (!mounted) return;
      if (response.statusCode == 200) {
        setState(
          () => _profile = UserProfile.fromJson(jsonDecode(response.body)),
        );
        UserService.invalidate(_profile!.id);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Профиль обновлён')));
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
                child: SingleChildScrollView(
                  child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    Center(
                      child: GestureDetector(
                        onTap: _pickAndUploadAvatar,
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 40,
                              backgroundColor: scheme.primaryContainer,
                              backgroundImage: _profile?.avatarUrl != null
                                  ? NetworkImage(_profile!.avatarUrl!)
                                  : null,
                              child: _profile?.avatarUrl == null
                                  ? Text(
                                      _profile?.name?.isNotEmpty == true
                                          ? _profile!.name![0].toUpperCase()
                                          : '?',
                                      style: TextStyle(
                                        fontSize: 32,
                                        color: scheme.onPrimaryContainer,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )
                                  : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: CircleAvatar(
                                radius: 12,
                                backgroundColor: scheme.primary,
                                child: Icon(
                                  Icons.edit,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
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
                    Text(
                      _profile?.phone ?? '—', style: const TextStyle(fontSize: 16)),
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
                    Text(
                      'О себе',
                      style: TextStyle(
                        fontSize: 12,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: _descriptionController,
                      maxLines: 3,
                      maxLength: 1000,
                      decoration: InputDecoration(
                        hintText: 'Расскажите о себе',
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
                        onPressed: _isSaving ? null : _saveProfile,
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
            ),
    );
  }
}
 