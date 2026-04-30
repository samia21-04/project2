import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _uid = FirebaseAuth.instance.currentUser!.uid;
  final _nameController = TextEditingController();
  final _cityController = TextEditingController();
  bool _isEditing = false;
  bool _isSaving = false;
  bool _isUploadingPhoto = false;
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(_uid)
        .get();
    if (doc.exists && mounted) {
      setState(() {
        _userData = doc.data();
        _nameController.text = _userData?['displayName'] ?? '';
        _cityController.text = _userData?['homeCity'] ?? '';
      });
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);
    try {
      final name = _nameController.text.trim();
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_uid)
          .update({
        'displayName': name,
        'homeCity':    _cityController.text.trim(),
      });
      await FirebaseAuth.instance.currentUser?.updateDisplayName(name);
      setState(() {
        _userData?['displayName'] = name;
        _userData?['homeCity']    = _cityController.text.trim();
        _isEditing = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _pickAndUploadPhoto() async {
    final picker = ImagePicker();
    final picked =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picked == null) return;

    setState(() => _isUploadingPhoto = true);
    try {
      final file = File(picked.path);
      final ref = FirebaseStorage.instance
          .ref()
          .child('users/$_uid/profile.jpg');
      await ref.putFile(file);
      final url = await ref.getDownloadURL();

      await FirebaseFirestore.instance
          .collection('users')
          .doc(_uid)
          .update({'profilePhotoUrl': url});

      setState(() => _userData?['profilePhotoUrl'] = url);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  Future<void> _signOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF0F2820),
        title: const Text('Sign out?',
            style: TextStyle(color: Color(0xFFE8F5EF))),
        content: const Text('You\'ll need to sign back in to access your trips.',
            style: TextStyle(color: Color(0xFF4D7A6A))),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel',
                  style: TextStyle(color: Color(0xFF5A8A76)))),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Sign out',
                  style: TextStyle(color: Color(0xFFE24B4A)))),
        ],
      ),
    );
    if (confirm != true) return;
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(
          context, '/login', (route) => false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final photoUrl = _userData?['profilePhotoUrl'] as String?;
    final name     = _userData?['displayName'] as String? ?? '';
    final city     = _userData?['homeCity'] as String? ?? '';
    final email    = FirebaseAuth.instance.currentUser?.email ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFF0D1F18),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF0A2018), Color(0xFF0D1F18)],
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 34, height: 34,
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F2820),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: const Color(0xFF1E3D2E)),
                            ),
                            child: const Icon(
                                Icons.chevron_left_rounded,
                                color: Color(0xFF5A8A76),
                                size: 18),
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => setState(
                              () => _isEditing = !_isEditing),
                          child: Container(
                            width: 34, height: 34,
                            decoration: BoxDecoration(
                              color: _isEditing
                                  ? const Color(0xFF0D2518)
                                  : const Color(0xFF0F2820),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: _isEditing
                                    ? const Color(0xFF1D9E75)
                                    : const Color(0xFF1E3D2E),
                              ),
                            ),
                            child: Icon(
                              _isEditing
                                  ? Icons.close_rounded
                                  : Icons.edit_outlined,
                              color: _isEditing
                                  ? const Color(0xFF1D9E75)
                                  : const Color(0xFF5A8A76),
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Avatar
                    GestureDetector(
                      onTap: _pickAndUploadPhoto,
                      child: Stack(
                        children: [
                          Container(
                            width: 80, height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF1D9E75),
                                  Color(0xFF0D6B52)
                                ],
                              ),
                              image: (photoUrl != null &&
                                      photoUrl.isNotEmpty)
                                  ? DecorationImage(
                                      image: NetworkImage(photoUrl),
                                      fit: BoxFit.cover)
                                  : null,
                            ),
                            child: (photoUrl == null || photoUrl.isEmpty)
                                ? Center(
                                    child: Text(
                                      name.isNotEmpty
                                          ? name[0].toUpperCase()
                                          : '?',
                                      style: const TextStyle(
                                          fontSize: 28,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600),
                                    ),
                                  )
                                : null,
                          ),
                          Positioned(
                            bottom: 0, right: 0,
                            child: Container(
                              width: 24, height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF1D9E75),
                                border: Border.all(
                                    color: const Color(0xFF0D1F18),
                                    width: 2),
                              ),
                              child: _isUploadingPhoto
                                  ? const Padding(
                                      padding: EdgeInsets.all(4),
                                      child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 1.5))
                                  : const Icon(Icons.camera_alt_rounded,
                                      color: Colors.white, size: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(name,
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFE8F5EF))),
                    const SizedBox(height: 2),
                    Text(email,
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF4D7A6A))),
                  ],
                ),
              ),

              // Fields
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Display name'),
                    _isEditing
                        ? _textField(controller: _nameController,
                            hint: 'Your name')
                        : _readOnly(name),
                    const SizedBox(height: 16),

                    _label('Home city'),
                    _isEditing
                        ? _textField(
                            controller: _cityController,
                            hint: 'e.g. Atlanta, GA',
                            prefixIcon: Icons.location_on_outlined)
                        : _readOnly(
                            city.isNotEmpty ? city : 'Not set'),
                    const SizedBox(height: 16),

                    _label('Email'),
                    _readOnly(email),
                    const SizedBox(height: 28),

                    // Save button
                    if (_isEditing)
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _saveProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1D9E75),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(14)),
                            elevation: 0,
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  width: 20, height: 20,
                                  child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2))
                              : const Text('Save Changes',
                                  style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500)),
                        ),
                      ),

                    // Sign out
                    if (!_isEditing) ...[
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton.icon(
                          onPressed: _signOut,
                          icon: const Icon(Icons.logout_rounded,
                              size: 18,
                              color: Color(0xFFE24B4A)),
                          label: const Text('Sign Out',
                              style: TextStyle(
                                  color: Color(0xFFE24B4A))),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                                color: Color(0xFF3B0E0E)),
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _bottomNav(),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(text.toUpperCase(),
        style: const TextStyle(
            fontSize: 10,
            color: Color(0xFF5A8A76),
            letterSpacing: 1.0,
            fontWeight: FontWeight.w500)),
  );

  Widget _readOnly(String value) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
    decoration: BoxDecoration(
      color: const Color(0xFF0A1A14),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: const Color(0xFF1A3028)),
    ),
    child: Text(value,
        style: const TextStyle(
            fontSize: 14, color: Color(0xFF9AC8B4))),
  );

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    IconData? prefixIcon,
  }) =>
      TextField(
        controller: controller,
        style: const TextStyle(fontSize: 14, color: Color(0xFFC8E8D8)),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle:
              const TextStyle(color: Color(0xFF3A5A4A), fontSize: 13),
          prefixIcon: prefixIcon != null
              ? Icon(prefixIcon,
                  color: const Color(0xFF3A6A55), size: 18)
              : null,
          filled: true,
          fillColor: const Color(0xFF0F2820),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: Color(0xFF1E3D2E))),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: Color(0xFF1E3D2E))),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                  color: Color(0xFF1D9E75), width: 1.5)),
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 13),
        ),
      );

  Widget _bottomNav() => Container(
    height: 64,
    decoration: const BoxDecoration(
      color: Color(0xFF0A1510),
      border: Border(top: BorderSide(color: Color(0xFF1A3028))),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _navItem(Icons.home_rounded, 'Trips', false),
        _navItem(Icons.person_outline_rounded, 'Profile', true),
      ],
    ),
  );

  Widget _navItem(IconData icon, String label, bool active) =>
      GestureDetector(
        onTap: () {
          if (!active) Navigator.pop(context);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 24, vertical: 8),
          decoration: BoxDecoration(
            color: active
                ? const Color(0xFF0F2820)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon,
                color: active
                    ? const Color(0xFF1D9E75)
                    : const Color(0xFF3A6A55),
                size: 20),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                    fontSize: 10,
                    color: active
                        ? const Color(0xFF1D9E75)
                        : const Color(0xFF3A6A55))),
          ]),
        ),
      );
}