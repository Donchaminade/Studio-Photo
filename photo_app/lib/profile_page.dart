import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart'; // SQLite
import 'package:path/path.dart'; // Pour localiser la base de données
import 'package:image_picker/image_picker.dart'; // Pour choisir une image
import 'utils/colors.dart';

class ProfilePage extends StatefulWidget {
  final String userName;
  final int userId;

  const ProfilePage({
    super.key,
    required this.userName,
    required this.userId,
    required String userEmail,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String? userEmail;
  String? profilePhoto;
  late Database db;
  bool isDatabaseInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeDatabase();
  }

  Future<void> _initializeDatabase() async {
    // Initialisation de SQLite
    final databasePath = await getDatabasesPath();
    db = await openDatabase(
      join(databasePath, 'user_data.db'),
      onCreate: (db, version) async {
        await db.execute(
          '''
          CREATE TABLE users(
            id INTEGER PRIMARY KEY,
            name TEXT,
            email TEXT,
            photoPath TEXT
          )
          ''',
        );
      },
      version: 1,
    );

    setState(() {
      isDatabaseInitialized = true;
    });

    // Récupérer les données utilisateur après l'initialisation de la base de données
    await _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    if (!isDatabaseInitialized) return;

    final result = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [widget.userId],
    );

    if (result.isNotEmpty) {
      setState(() {
        userEmail = result.first['email'] as String?;
        profilePhoto = result.first['photoPath'] as String?;
      });
    }
  }

  Future<void> _updateProfilePhoto(String photoPath) async {
    if (!isDatabaseInitialized) return;

    await db.update(
      'users',
      {'photoPath': photoPath},
      where: 'id = ?',
      whereArgs: [widget.userId],
    );

    setState(() {
      profilePhoto = photoPath;
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      await _updateProfilePhoto(pickedFile.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profil"),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        elevation: 0,
      ),
      body: isDatabaseInitialized
          ? Container(
              color: AppColors.background,
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Affichage de la photo de profil
                  GestureDetector(
                    onTap:
                        _pickImage, // Sélectionner une image lorsqu'on clique sur l'avatar
                    child: CircleAvatar(
                      radius: 60,
                      backgroundImage: profilePhoto != null
                          ? FileImage(File(profilePhoto!))
                          : const AssetImage('assets/default_avatar.png')
                              as ImageProvider,
                      child: profilePhoto == null
                          ? const Icon(
                              Icons.add_a_photo,
                              size: 30,
                              color: AppColors.textOnPrimary,
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Nom de l'utilisateur
                  Text(
                    widget.userName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Email de l'utilisateur
                  Text(
                    userEmail ?? 'Email introuvable',
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 30),
                  // Boutons d'action
                  Expanded(
                    child: ListView(
                      children: [
                        _buildActionButton(
                          context,
                          icon: Icons.edit,
                          label: "Modifier le profil",
                          color: AppColors.accent,
                          onPressed: () {
                            // Ajoutez ici l'action pour modifier le profil
                          },
                        ),
                        _buildActionButton(
                          context,
                          icon: Icons.lock,
                          label: "Changer le mot de passe",
                          color: AppColors.accent,
                          onPressed: () {
                            // Ajoutez ici l'action pour changer le mot de passe
                          },
                        ),
                        _buildActionButton(
                          context,
                          icon: Icons.logout,
                          label: "Se déconnecter",
                          color: AppColors.error,
                          onPressed: () {
                            // Ajoutez ici l'action pour se déconnecter
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          : const Center(
              child: CircularProgressIndicator(),
            ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 3, // Correspond à l'onglet Profil
        onTap: (index) {
          if (index != 3) {
            Navigator.pop(context); // Retour à HomeScreen pour changer d'onglet
          }
        },
        backgroundColor: AppColors.primary,
        selectedItemColor: AppColors.textOnPrimary,
        unselectedItemColor: AppColors.textOnPrimary.withOpacity(0.7),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.photo_library),
            label: 'Photos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.collections),
            label: 'Mes Photos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Commandes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }

  // Widget pour un bouton d'action
  Widget _buildActionButton(BuildContext context,
      {required IconData icon,
      required String label,
      required Color color,
      required VoidCallback onPressed}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16.0),
        ),
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24, color: AppColors.textOnPrimary),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(fontSize: 16, color: AppColors.textOnPrimary),
            ),
          ],
        ),
      ),
    );
  }
}
