import 'dart:async';
import 'dart:ui';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:photo_app/no_connection_screen.dart';
import 'package:photo_app/utils/colors.dart';
import 'package:photo_app/utils/connectivity_service.dart';
import 'package:photo_app/api_service.dart';
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'login_screen.dart';
import 'order_summary_screen.dart';
import 'package:photo_app/utils/lines_background.dart';

// --- Model Class for Mock Data ---
class RecentRequest {
  final String title;
  final DateTime date;
  final IconData icon;

  RecentRequest({required this.title, required this.date, required this.icon});
}
// --- End of Model Class ---

class HomeScreen extends StatefulWidget {
  final String userName;
  final int userId;

  const HomeScreen({
    super.key,
    required this.userName,
    required this.userId,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final Set<String> _selectedImages = {};
  Future<List<String>>? _albumImagesFuture;
  File? _avatar;
  final Map<String, Map<String, dynamic>> _photoDetails = {};

  final ConnectivityService _connectivityService = ConnectivityService();
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;
  bool _isOffline = false;

  // --- Mock Data for History ---
  final List<RecentRequest> _mockHistory = [
    RecentRequest(
        title: "Commande de 15 photos",
        date: DateTime.now().subtract(const Duration(days: 1)),
        icon: Icons.photo_camera),
    RecentRequest(
        title: "Réservation - Mariage",
        date: DateTime.now().subtract(const Duration(days: 3)),
        icon: Icons.calendar_today),
    RecentRequest(
        title: "Tirage 20x30",
        date: DateTime.now().subtract(const Duration(days: 6)),
        icon: Icons.print),
    RecentRequest(
        title: "Commande Album",
        date: DateTime.now().subtract(const Duration(days: 10)),
        icon: Icons.book),
    RecentRequest(
        title: "Photos d'identité",
        date: DateTime.now().subtract(const Duration(days: 4)),
        icon: Icons.person),
  ];
  // --- End of Mock Data ---

  @override
  void initState() {
    super.initState();
    _albumImagesFuture = ApiService.getAlbumImages(widget.userId);
    _connectivitySubscription =
        _connectivityService.connectivityStream.listen((result) {
      if (result == ConnectivityResult.none) {
        if (!_isOffline && mounted) {
          setState(() {
            _isOffline = true;
          });
          Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => const NoConnectionScreen()));
        }
      } else {
        if (_isOffline && mounted) {
          setState(() {
            _isOffline = false;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _changeAvatar() async {
    final picker = ImagePicker();
    final pickedFile =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (pickedFile != null) {
      setState(() {
        _avatar = File(pickedFile.path);
      });
    }
  }

  void _logout() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          const AnimatedBackground(),
          _buildFixedTopBar(context),
          Padding(
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 60), // Adjusted top padding
            child: _buildBody(),
          ),
        ],
      ),
      bottomNavigationBar: _buildFloatingBottomNavBar(),
    );
  }

  Widget _buildFixedTopBar(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(6)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            color: AppColors.primary,
            padding: EdgeInsets.fromLTRB(24.0, MediaQuery.of(context).padding.top + 4, 10.0, 4.0), // Adjusted vertical padding
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Ravi de vous revoir, ${widget.userName}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16, //taille du texte dans le topbar
                  ),
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.notifications_none, color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    final List<Widget> tabs = [
      _buildHomeTab(),
      _buildPhotosTab(),
      _buildCommandsTab(),
      _buildProfileTab(),
    ];
    return IndexedStack(
      index: _currentIndex,
      children: tabs,
    );
  }

  Widget _buildHomeTab() {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            children: [
              const SizedBox(height: 2), // Reduced space above the card
              _buildTopCard(),
            ],
          ),
        ),
        SliverToBoxAdapter(child: _buildQuickActions()),
        _buildHistorySection(),
        SliverToBoxAdapter(child: _buildAdCarousel()),
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  Widget _buildPhotosTab() {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.only(top: 100),
      child: FutureBuilder<List<String>>(
        future: _albumImagesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Aucune image trouvée.'));
          } else {
            final images = snapshot.data!;
            return GridView.builder(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16.0,
                crossAxisSpacing: 16.0,
              ),
              itemCount: images.length,
              itemBuilder: (context, index) {
                final imageUrl = images[index];
                final isSelected = _selectedImages.contains(imageUrl);
                return GestureDetector(
                  onTap: () => setState(() {
                    if (isSelected) {
                      _selectedImages.remove(imageUrl);
                    } else {
                      _selectedImages.add(imageUrl);
                    }
                  }),
                  child: Stack(
                    children: [
                      Card(
                        clipBehavior: Clip.antiAlias,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, progress) => progress == null ? child : const Center(child: CircularProgressIndicator()),
                          errorBuilder: (context, error, stack) => const Icon(Icons.broken_image, size: 50),
                        ),
                      ),
                      if (isSelected)
                        const Positioned(
                          top: 8,
                          right: 8,
                          child: Icon(Icons.check_circle, color: AppColors.accent, size: 30),
                        ),
                    ],
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }

  Widget _buildCommandsTab() {
     return Container(
      color: AppColors.background,
      padding: const EdgeInsets.only(bottom: 80, top: 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Vos Commandes', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          ),
          Expanded(
            child: _selectedImages.isEmpty
                ? const Center(child: Text('Aucune photo sélectionnée pour la commande.'))
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              itemCount: _selectedImages.length,
              itemBuilder: (context, index) {
                final imageUrl = _selectedImages.elementAt(index);
                if (!_photoDetails.containsKey(imageUrl)) {
                  _photoDetails[imageUrl] = {'size': '10x15 cm', 'quantity': 1};
                }
                final photoDetails = _photoDetails[imageUrl]!;
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Image.network(imageUrl, height: 150, width: double.infinity, fit: BoxFit.cover),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Taille :'),
                            DropdownButton<String>(
                              value: photoDetails['size'],
                              items: ['10x15 cm', '15x20 cm', '20x30 cm'].map((size) => DropdownMenuItem(value: size, child: Text(size))).toList(),
                              onChanged: (value) => setState(() {
                                if (value != null) _photoDetails[imageUrl]!['size'] = value;
                              }),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Quantité :'),
                            Row(
                              children: [
                                IconButton(icon: const Icon(Icons.remove), onPressed: () => setState(() { if (photoDetails['quantity'] > 1) _photoDetails[imageUrl]!['quantity'] -= 1; })),
                                Text('${photoDetails['quantity']}'),
                                IconButton(icon: const Icon(Icons.add), onPressed: () => setState(() => _photoDetails[imageUrl]!['quantity'] += 1)),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          if (_selectedImages.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton.icon(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => OrderSummaryScreen(orderDetails: _photoDetails))),
                icon: const Icon(Icons.shopping_cart),
                label: const Text('Voir le récapitulatif'),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProfileTab() {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.only(top: 100),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: _changeAvatar,
              child: CircleAvatar(
                radius: 60,
                backgroundImage: _avatar != null ? FileImage(_avatar!) as ImageProvider : const AssetImage('assets/images/pro.png'),
                child: _avatar == null ? const Icon(Icons.camera_alt, size: 30, color: AppColors.textOnPrimary) : null,
              ),
            ),
            const SizedBox(height: 20),
            Text(widget.userName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              label: const Text('Déconnexion'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8.0, 0, 8.0, 4.0),
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
        child: SizedBox(
          height: 220, // Enlarged card height
          child: Stack(
            alignment: Alignment.center, // Center the button
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary, width: 2),
                ),
                child: Image.asset(
                  'assets/images/pro.png',
                  height: 280,
                  width: double.infinity,
                  fit: BoxFit.contain, // Ensure image is fully visible
                ),
              ),
              Positioned(
                bottom: 12,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.play_arrow, size: 20), // Play icon
                  label: const Text("Comment ça marche ?", style: TextStyle(fontSize: 10)), // Smaller text
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text("Comment ça marche ?"),
                        content: const Text("Ici, nous afficherions une vidéo tutoriel pour guider l'utilisateur."),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text("Fermer"),
                          )
                        ],
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), // Smaller padding
                  ),
                ).animate(
                  onComplete: (controller) => controller.repeat(),
                ).shimmer(
                  delay: 2000.milliseconds,
                  duration: 1000.milliseconds,
                  color: Colors.white.withOpacity(0.5), // Glimmer effect
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildQuickActionButton(icon: Icons.calendar_today, label: 'Réserver', onTap: () {}),
          _buildQuickActionButton(icon: Icons.photo_album, label: 'Portfolio', onTap: () {}),
          _buildQuickActionButton(icon: Icons.price_change, label: 'Tarifs', onTap: () {}),
          _buildQuickActionButton(icon: Icons.contact_phone, label: 'Contact', onTap: () {}),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton({required IconData icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: AppColors.primary.withOpacity(0.1),
            child: Icon(icon, color: AppColors.primary, size: 30),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: AppColors.textPrimary)),
        ],
      ),
    );
  }

  Widget _buildHistorySection() {
    final recentHistory = _mockHistory.where((req) => req.date.isAfter(DateTime.now().subtract(const Duration(days: 7)))).take(3).toList();

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 16.0),
      sliver: SliverToBoxAdapter(
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Historique récent',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.primary),
                    shape: const StadiumBorder(),
                  ),
                  child: const Text("Voir tout"),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...recentHistory.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    child: Icon(item.icon, color: AppColors.primary),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.title, style: const TextStyle(fontWeight: FontWeight.w500)),
                        Text(DateFormat('dd MMM yyyy').format(item.date), style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textSecondary),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildAdCarousel() {
    final List<String> localImages = [
      'assets/carousel/Ajouter un sous-titre.png',
      'assets/carousel/car.jpg',
      'assets/carousel/car1.jpg',
      'assets/carousel/pflex.jpeg',
      'assets/carousel/Pink Modern Pink October Instagram Post  (1).png',
      'assets/carousel/Pink Modern Pink October Instagram Post  (2).png',
      'assets/carousel/Pink Modern Pink October Instagram Post .png',
      'assets/images/pro.png',
    ];

    Widget buildItem(String path, bool isAsset) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 5.0),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: isAsset
              ? Image.asset(path, fit: BoxFit.contain)
              : Image.network(path, fit: BoxFit.contain),
        ),
      ).animate(
        onComplete: (controller) => controller.repeat(),
      ).shimmer(
        delay: 2000.milliseconds,
        duration: 1000.milliseconds,
        color: AppColors.background.withOpacity(0.5),
      );
    }

    Widget buildLocalCarousel(String message) {
      return Column(
        children: [
          CarouselSlider.builder(
            itemCount: localImages.length,
            itemBuilder: (context, index, realIndex) => buildItem(localImages[index], true),
            options: CarouselOptions(
                height: 140.0,
                viewportFraction: 0.8,
                enlargeCenterPage: false,
                autoPlay: true,
                autoPlayInterval: const Duration(seconds: 4)),
          ),
          if (message.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(message,
                  style: const TextStyle(color: AppColors.textSecondary)),
            )
        ],
      );
    }

    return _isOffline
        ? buildLocalCarousel("Impossible de charger les promotions. Mode hors-ligne.")
        : FutureBuilder<List<String>>(
            future: Future.delayed(const Duration(seconds: 2), () => []),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                    height: 140,
                    child: Center(child: CircularProgressIndicator()));
              }
              if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                return buildLocalCarousel("Impossible de charger les promotions en ligne.");
              }
              final onlineImages = snapshot.data!;
              return CarouselSlider.builder(
                itemCount: onlineImages.length,
                itemBuilder: (context, index, realIndex) => buildItem(onlineImages[index], false),
                options: CarouselOptions(
                    height: 140.0,
                    autoPlay: true,
                    autoPlayInterval: const Duration(seconds: 5),
                    enlargeCenterPage: false,
                    viewportFraction: 0.8),
              );
            },
          );
  }

  Widget _buildFloatingBottomNavBar() {
    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary, width: 2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: _onTabTapped,
            backgroundColor: Colors.white.withOpacity(0.3),
            selectedItemColor: AppColors.primary,
            unselectedItemColor: AppColors.textPrimary.withOpacity(0.6),
            elevation: 0,
            type: BottomNavigationBarType.fixed,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Accueil'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.photo_album), label: 'Photos'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.shopping_cart), label: 'Commandes'),
              BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
            ],
          ),
        ),
      ),
    );
  }
}