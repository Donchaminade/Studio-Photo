import 'dart:io';
import 'dart:ui';
import 'package:Picon/api_service.dart';
import 'package:Picon/contact_screen.dart';
import 'package:Picon/edit_profile_screen.dart';
import 'package:Picon/history_screen.dart';
import 'package:Picon/login_screen.dart';
import 'package:Picon/utils/colors.dart';
import 'package:Picon/utils/geometric_background.dart';
import 'package:flutter/material.dart';
import 'package:Picon/settings_screen.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';


class ProfilePage extends StatefulWidget {
  final String userName;
  final String userLastName;
  final String userEmail;
  final File? avatar;
  final Function(File) onAvatarChanged;
  final Function(String newName, String newLastName, String newEmail) onProfileUpdated;

  const ProfilePage({
    super.key,
    required this.userName,
    required this.userLastName,
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
  
  late String _currentLastName;
  late String _currentEmail;

  @override
  void initState() {
    super.initState();
    _currentAvatar = widget.avatar;
    _currentName = widget.userName;
    _currentLastName = widget.userLastName;
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
    // v5 : vrai numéro de la session (plus de numéro fictif).
    final String placeholderPhone = ApiService.userPhone ?? '';

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfilePage(
          currentName: _currentName,
          currentLastName: _currentLastName,
          currentEmail: _currentEmail,
          currentPhone: placeholderPhone, // Pass placeholder
        ),
      ),
    );

    if (result != null && result is Map<String, String>) {
      setState(() {
        _currentName = result['name']!;
        _currentLastName = result['lastName']!;
        _currentEmail = result['email']!;
        // Phone number is edited but not displayed on this page or stored higher up yet.
      });
      // The onProfileUpdated callback in home_screen only accepts name and email.
      widget.onProfileUpdated(result['name']!, result['lastName']!, result['email']!);
    }
  }

  void _logout() async {
    await ApiService.clearAuthDetails();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (Route<dynamic> route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent, // Le bandeau marine est peint dans le corps
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: Colors.white.withOpacity(0.2), // Subtle glassmorphic effect
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.textOnPrimary), // Icon color for contrast
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ),
        title: Text('Mon Profil', style: TextStyle(color: AppColors.textOnPrimary, fontWeight: FontWeight.bold)), // Use textOnPrimary
        foregroundColor: AppColors.textOnPrimary, // Ensure foreground elements (like icons) are white
      ),
      body: Stack(
        children: [
          GeometricBackground(),
          // Bandeau d'en-tête marine derrière l'avatar.
          Container(
            height: MediaQuery.of(context).padding.top + kToolbarHeight + 120,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primary, Color(0xFF0B3FA8)],
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
            ),
          ),
          RefreshIndicator(
            onRefresh: () async {
              // Trigger global refresh logic from here
              final details = await ApiService.getAuthDetails();
              if (details != null && mounted) {
                setState(() {
                  _currentName = details['firstname'] ?? _currentName;
                  _currentLastName = details['lastname'] ?? _currentLastName;
                  _currentEmail = details['email'] ?? _currentEmail;
                });
                widget.onProfileUpdated(_currentName, _currentLastName, _currentEmail);
              }
            },
            color: AppColors.primary,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
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
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '$_currentName $_currentLastName',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith( // Use headlineMedium for a more prominent name
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (_currentEmail.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(
                            _currentEmail,
                            style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                        ),
                      const SizedBox(height: 8),
                      // Text(
                      //   _currentEmail,
                      //   style: Theme.of(context).textTheme.bodyLarge?.copyWith( // Use bodyLarge for email
                      //     color: AppColors.textSecondary,
                      //   ),
                      // ),
                      const SizedBox(height: 40),
                      _buildMenuItems(),
                    ],
                  ),
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
                  : const AssetImage('assets/images/user.png'), // A default placeholder
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
    ).animate(onPlay: (controller) => controller.repeat(reverse: true, count: 2)).scale(
      delay: 2000.ms,
      duration: 1000.ms,
      begin: const Offset(1, 1),
      end: const Offset(1.05, 1.05),
      curve: Curves.easeInOut,
    );
  }


  Widget _buildMenuItems() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Material(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: AppColors.line),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              _buildProfileMenuTile(
                icon: Icons.edit_outlined,
                title: 'Modifier le profil',
                onTap: _navigateToEditPage,
              ).animate().fade(delay: 50.ms, duration: 300.ms).slideX(begin: 0.1, curve: Curves.easeOut),
              const Divider(height: 1, indent: 16, endIndent: 16),
              _buildProfileMenuTile(
                icon: Icons.history_outlined,
                title: 'Historique des commandes',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const HistoryScreen())),
              ).animate().fade(delay: 100.ms, duration: 300.ms).slideX(begin: 0.1, curve: Curves.easeOut),
              const Divider(height: 1, indent: 16, endIndent: 16),
              _buildProfileMenuTile(
                icon: Icons.contact_support_outlined,
                title: 'Aide & Support',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ContactScreen())),
              ).animate().fade(delay: 150.ms, duration: 300.ms).slideX(begin: 0.1, curve: Curves.easeOut),
              const Divider(height: 1, indent: 16, endIndent: 16),
              _buildProfileMenuTile(
                icon: Icons.tune_rounded,
                title: 'Paramètres',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen())),
              ).animate().fade(delay: 170.ms, duration: 300.ms).slideX(begin: 0.1, curve: Curves.easeOut),
              const Divider(height: 1, indent: 16, endIndent: 16),
              _buildProfileMenuTile(
                icon: Icons.info_outline_rounded,
                title: 'À propos',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AboutScreen())),
              ).animate().fade(delay: 185.ms, duration: 300.ms).slideX(begin: 0.1, curve: Curves.easeOut),              const Divider(height: 1, indent: 16, endIndent: 16),
               _buildProfileMenuTile(
                icon: Icons.logout,
                title: 'Déconnexion',
                color: AppColors.error,
                onTap: _logout,
              ).animate().fade(delay: 200.ms, duration: 300.ms).slideX(begin: 0.1, curve: Curves.easeOut),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileMenuTile({required IconData icon, required String title, required VoidCallback onTap, Color? color}) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: (color ?? AppColors.primary).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Icon(icon, color: color ?? AppColors.primary, size: 21),
      ),
      title: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Text(title, style: TextStyle(fontWeight: FontWeight.w500, color: color ?? AppColors.textPrimary)),
      ),
      trailing: Icon(Icons.arrow_forward_ios, size: 16, color: color ?? AppColors.textSecondary),
      onTap: onTap,
    );
  }
}
