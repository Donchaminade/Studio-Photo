import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_app/contact_screen.dart';
import 'package:photo_app/edit_profile_page.dart';
import 'package:photo_app/history_screen.dart';
import 'package:photo_app/login_screen.dart';
import 'package:photo_app/utils/colors.dart';
import 'package:photo_app/utils/geometric_background.dart';

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
      setState(() {
        _currentAvatar = newAvatar;
      });
      widget.onAvatarChanged(newAvatar);
    }
  }
  
  Future<void> _navigateToEditPage() async {
    // Placeholder for phone since it's not managed in homescreen state yet
    const String placeholderPhone = '90123456'; 

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfilePage(
          currentName: _currentName,
          currentEmail: _currentEmail,
          currentPhone: placeholderPhone, // Pass placeholder
        ),
      ),
    );

    if (result != null && result is Map<String, String>) {
      setState(() {
        _currentName = result['name']!;
        _currentEmail = result['email']!;
        // Phone number is edited but not displayed on this page or stored higher up yet.
      });
      // The onProfileUpdated callback in home_screen only accepts name and email.
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
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: Colors.white,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.primary),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ),
        title: const Text('Mon Profil', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
      ),
      body: Stack(
        children: [
          const GeometricBackground(),
          Container(
            height: MediaQuery.of(context).padding.top + kToolbarHeight,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.black.withOpacity(0.4), Colors.transparent],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          SingleChildScrollView(
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + kToolbarHeight, bottom: 20),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 30),
                    _buildAvatar(),
                    const SizedBox(height: 20),
                    Text(
                      _currentName,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _currentEmail,
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 40),
                    _buildMenuItems(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return GestureDetector(
      onTap: _pickImage,
      child: Stack(
        children: [
          CircleAvatar(
            radius: 75,
            backgroundColor: AppColors.primary.withOpacity(0.5),
            child: CircleAvatar(
              radius: 70,
              backgroundImage: _currentAvatar != null
                  ? FileImage(_currentAvatar!) as ImageProvider
                  : const AssetImage('assets/images/pro1.png'), // A default placeholder
            ),
          ),
          Positioned(
            bottom: 2,
            right: 2,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: AppColors.accent,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: Offset(1, 1),
                  )
                ]
              ),
              child: const Icon(Icons.camera_alt, color: Colors.white, size: 22),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItems() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              _buildProfileMenuTile(
                icon: Icons.edit_outlined,
                title: 'Modifier le profil',
                onTap: _navigateToEditPage,
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              _buildProfileMenuTile(
                icon: Icons.history_outlined,
                title: 'Historique des commandes',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const HistoryScreen())),
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              _buildProfileMenuTile(
                icon: Icons.contact_support_outlined,
                title: 'Aide & Support',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ContactScreen())),
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
               _buildProfileMenuTile(
                icon: Icons.logout,
                title: 'Déconnexion',
                color: AppColors.error,
                onTap: _logout,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileMenuTile({required IconData icon, required String title, required VoidCallback onTap, Color? color}) {
    return ListTile(
      leading: Icon(icon, color: color ?? AppColors.textPrimary),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.w500, color: color ?? AppColors.textPrimary)),
      trailing: Icon(Icons.arrow_forward_ios, size: 16, color: color ?? AppColors.textSecondary),
      onTap: onTap,
    );
  }
}
