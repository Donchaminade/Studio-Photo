import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_app/contact_screen.dart';
import 'package:photo_app/edit_profile_page.dart';
import 'package:photo_app/history_screen.dart';
import 'package:photo_app/login_screen.dart';
import 'package:photo_app/utils/colors.dart';
import 'package:photo_app/utils/geometric_background.dart';
import 'package:photo_app/widgets/picon_ui.dart';

class ProfilePage extends StatefulWidget {
  final String userName;
  final String userEmail;
  final File? avatar;
  final Function(File) onAvatarChanged;
  final Function(String newName, String newEmail) onProfileUpdated;

  const ProfilePage({
    super.key,
    required this.userName,
    required this.userEmail,
    required this.avatar,
    required this.onAvatarChanged,
    required this.onProfileUpdated,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late File? _currentAvatar;
  late String _currentName;
  late String _currentEmail;

  @override
  void initState() {
    super.initState();
    _currentAvatar = widget.avatar;
    _currentName = widget.userName;
    _currentEmail = widget.userEmail;
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);

    if (pickedFile != null) {
      final newAvatar = File(pickedFile.path);
      setState(() => _currentAvatar = newAvatar);
      widget.onAvatarChanged(newAvatar);
    }
  }

  Future<void> _navigateToEditPage() async {
    const String placeholderPhone = '90123456';

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfilePage(
          currentName: _currentName,
          currentEmail: _currentEmail,
          currentPhone: placeholderPhone,
        ),
      ),
    );

    if (result != null && result is Map<String, String>) {
      setState(() {
        _currentName = result['name']!;
        _currentEmail = result['email']!;
      });
      widget.onProfileUpdated(result['name']!, result['email']!);
    }
  }

  void _logout() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final photo = CircleAvatar(
      radius: 64,
      backgroundColor: AppColors.primary.withValues(alpha: 0.2),
      backgroundImage: _currentAvatar != null
          ? FileImage(_currentAvatar!)
          : const AssetImage('assets/images/pro1.png') as ImageProvider,
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: piconBar('Mon Profil'),
      body: Stack(
        children: [
          const GeometricBackground(),
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            child: Column(
              children: [
                Reveal(
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        reduceMotion(context) ? photo : Hero(tag: 'picon-avatar', child: photo),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: AppColors.accent,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  _currentName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  _currentEmail,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 15, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 22),
                Reveal(
                  index: 1,
                  child: PiconCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        _tile(Icons.edit_outlined, 'Modifier le profil', _navigateToEditPage),
                        const Divider(height: 1, indent: 16, endIndent: 16),
                        _tile(
                          Icons.history_outlined,
                          'Historique des commandes',
                          () => Navigator.push(context, MaterialPageRoute(builder: (context) => const HistoryScreen())),
                        ),
                        const Divider(height: 1, indent: 16, endIndent: 16),
                        _tile(
                          Icons.contact_support_outlined,
                          'Aide & Support',
                          () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ContactScreen())),
                        ),
                        const Divider(height: 1, indent: 16, endIndent: 16),
                        _tile(Icons.logout, 'Déconnexion', _logout, color: AppColors.error),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tile(IconData icon, String title, VoidCallback onTap, {Color? color}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Icon(icon, color: color ?? AppColors.primary),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.w700, color: color ?? AppColors.textPrimary)),
      trailing: Icon(Icons.arrow_forward_ios, size: 14, color: color ?? AppColors.textSecondary),
      onTap: onTap,
    );
  }
}
