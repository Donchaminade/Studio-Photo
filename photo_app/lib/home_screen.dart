// ignore_for_file: unused_import

import 'dart:async';
import 'dart:ui';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:photo_app/no_connection_screen.dart';
import 'package:photo_app/notifications_screen.dart';
import 'package:photo_app/utils/colors.dart';
import 'package:photo_app/utils/connectivity_service.dart';
import 'package:photo_app/api_service.dart';
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:photo_app/portfolio_screen.dart';
import 'package:photo_app/pricing_screen.dart';
import 'package:photo_app/contact_screen.dart';
import 'package:photo_app/booking_screen.dart';
import 'package:photo_app/history_screen.dart';
import 'package:photo_app/utils/geometric_background.dart';
import 'package:photo_app/profile_page.dart';
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

enum CartMode { detail, batch }

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final Set<String> _selectedImages = {};
  Future<List<String>>? _albumImagesFuture;
  File? _avatar;
  final Map<String, Map<String, dynamic>> _photoDetails = {};

  final ConnectivityService _connectivityService = ConnectivityService();
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;
  bool _isOffline = false;

  // --- Updatable profile info ---
  late String _currentUserName;
  late String _currentUserEmail;

  // --- New state variables for cart ---
  CartMode _selectedMode = CartMode.detail;
  bool _isExpress = false;
  double _totalPrice = 0.0;
  final Map<String, double> _prices = const {
    '10x15 cm': 150,
    '15x20 cm': 300,
    '20x30 cm': 500,
  };
  // --- End of new state variables ---

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
    _currentUserName = widget.userName;
    _currentUserEmail = 'user-test@email.com'; // Initialize placeholder
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
    _calculateTotal();
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }

  void _onTabTapped(int index) {
    if (index == 3) { // Index 3 is for Profile
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProfilePage(
            userName: _currentUserName,
            userEmail: _currentUserEmail,
            avatar: _avatar,
            onAvatarChanged: (newAvatar) {
              setState(() {
                _avatar = newAvatar;
              });
            },
            onProfileUpdated: (newName, newEmail) {
              setState(() {
                _currentUserName = newName;
                _currentUserEmail = newEmail;
              });
            },
          ),
        ),
      );
    } else {
      setState(() {
        _currentIndex = index;
      });
    }
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

  void _quickPhotoOrder() async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage(imageQuality: 50);
    if (pickedFiles.isNotEmpty) {
      setState(() {
        for (var file in pickedFiles) {
          // In a real app, you would upload the file and get a URL.
          // For this mock, we are using local paths, which might not render with Image.network.
          // Let's assume the selection is for demonstration and the cart handles paths.
          _selectedImages.add(file.path);
        }
        _calculateTotal();
      });
      _onTabTapped(2); // Switch to the Commands tab
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          // const AnimatedBackground(),
          _buildFixedTopBar(context),
          Padding(
            padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top +
                    60), // Adjusted top padding
            child: _buildBody(),
          ),
        ],
      ),
      bottomNavigationBar: _buildFloatingBottomNavBar(),
      floatingActionButton: FloatingActionButton(
        onPressed: _quickPhotoOrder,
        backgroundColor: AppColors.accent,
        child: const Icon(Icons.add_a_photo, color: Colors.white),
      )
          .animate(
            onComplete: (controller) => controller.repeat(reverse: true),
          )
          .scale(
            delay: 1000.ms,
            duration: 500.ms,
            begin: const Offset(1, 1),
            end: const Offset(1.1, 1.1),
            curve: Curves.easeInOut,
          ),
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
            padding: EdgeInsets.fromLTRB(
                10.0, MediaQuery.of(context).padding.top + 2, 10.0, 2.0),
            child: Stack(
              alignment: Alignment.center, // Centrer le contenu principal
              children: [
                Column(
                  mainAxisSize:
                      MainAxisSize.min, // Prend juste l'espace nécessaire
                  children: [
                    Image.asset(
                      'assets/images/pro.png',
                      height: 35, // Taille réduite pour le logo
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(
                        height: 4), // Petit espace entre le logo et le texte
                    Text(
                      'Ravi de vous revoir, $_currentUserName',
                      textAlign: TextAlign.center, // Centrer le texte
                      style: const TextStyle(
                        color: Colors.white,
                        // fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  child: IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const NotificationsScreen()),
                      );
                    },
                    icon: const Icon(Icons.notifications_none,
                        color: Colors.white, size: 24),
                  ),
                ),
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProfilePage(
                            userName: _currentUserName,
                            userEmail: _currentUserEmail,
                            avatar: _avatar,
                            onAvatarChanged: (newAvatar) {
                              setState(() {
                                _avatar = newAvatar;
                              });
                            },
                            onProfileUpdated: (newName, newEmail) {
                              setState(() {
                                _currentUserName = newName;
                                _currentUserEmail = newEmail;
                              });
                            },
                          ),
                        ),
                      );
                    },
                    icon: CircleAvatar(
                      radius: 18,
                      backgroundImage: _avatar != null ? FileImage(_avatar!) as ImageProvider : null,
                      backgroundColor: _avatar == null ? AppColors.accent : Colors.transparent,
                      child: _avatar == null
                          ? Text(
                              _currentUserName.trim().split(' ').where((s) => s.isNotEmpty).map((s) => s[0]).take(2).join().toUpperCase(),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14),
                            )
                          : null,
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
                    _calculateTotal();
                  }),
                  child: Stack(
                    children: [
                      Card(
                        clipBehavior: Clip.antiAlias,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0)),
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, progress) =>
                              progress == null
                                  ? child
                                  : const Center(
                                      child: CircularProgressIndicator()),
                          errorBuilder: (context, error, stack) =>
                              const Icon(Icons.broken_image, size: 50),
                        ),
                      ),
                      if (isSelected)
                        const Positioned(
                          top: 8,
                          right: 8,
                          child: Icon(Icons.check_circle,
                              color: AppColors.accent, size: 30),
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
      padding:
          const EdgeInsets.only(bottom: 120, top: 5), // Adjusted bottom padding
      child: Stack(
        // Added Stack for background
        children: [
          const Positioned.fill(
            child: GeometricBackground(), // Apply geometric background here
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: SegmentedButton<CartMode>(
                  segments: const [
                    ButtonSegment(
                        value: CartMode.detail, label: Text('Par détail')),
                    ButtonSegment(
                        value: CartMode.batch, label: Text('Par lot')),
                  ],
                  selected: {_selectedMode},
                  onSelectionChanged: (Set<CartMode> newSelection) {
                    setState(() {
                      _selectedMode = newSelection.first;
                      _calculateTotal();
                    });
                  },
                ),
              ),
              Expanded(
                child: _selectedImages.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.shopping_cart_outlined,
                                size: 80, color: AppColors.textSecondary),
                            SizedBox(height: 16),
                            Text(
                              'Votre panier est vide.\nSélectionnez des photos pour commencer une commande !',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 18, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      )
                    : _selectedMode == CartMode.detail
                        ? _buildDetailCart()
                        : _buildBatchCart(),
              ),
              if (_selectedImages.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: ElevatedButton.icon(
                    onPressed: _showValidationPopup,
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Valider'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _calculateTotal() {
    double total = 0;
    for (final imageUrl in _selectedImages) {
      final details = _photoDetails[imageUrl];
      if (details != null) {
        final price = _prices[details['size']] ?? 0;
        total += price * (details['quantity'] as int);
      }
    }

    if (_isExpress && _selectedImages.length <= 10) {
      total += 1500;
    }

    setState(() {
      _totalPrice = total;
    });
  }

  Widget _buildDetailCart() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      itemCount: _selectedImages.length,
      itemBuilder: (context, index) {
        final imageUrl = _selectedImages.elementAt(index);
        if (!_photoDetails.containsKey(imageUrl)) {
          _photoDetails[imageUrl] = {'size': '10x15 cm', 'quantity': 1};
        }
        final photoDetails = _photoDetails[imageUrl]!;
        final price = _prices[photoDetails['size']] ?? 0;
        final subtotal = price * (photoDetails['quantity'] as int);

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          clipBehavior: Clip.antiAlias,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ExpansionTile(
            key: ValueKey(imageUrl),
            title: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: (imageUrl.startsWith('http'))
                      ? Image.network(imageUrl,
                          width: 60, height: 60, fit: BoxFit.cover)
                      : Image.file(File(imageUrl),
                          width: 60, height: 60, fit: BoxFit.cover),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Photo ${index + 1}',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(
                        '${subtotal.toStringAsFixed(0)} FCFA',
                        style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color.fromARGB(255, 236, 7, 7), // Blue background
                      shape: BoxShape.circle, // Circular shape
                    ),
                    child: const Icon(Icons.delete,
                        size: 18, color: Colors.white), // White icon
                  ),
                  onPressed: () {
                    setState(() {
                      _selectedImages.remove(imageUrl);
                      _photoDetails.remove(imageUrl);
                      _calculateTotal();
                    });
                  },
                ),
              ],
            ),
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Taille :'),
                        DropdownButton<String>(
                          value: photoDetails['size'],
                          items: _prices.keys
                              .map((size) => DropdownMenuItem(
                                  value: size, child: Text(size)))
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _photoDetails[imageUrl]!['size'] = value;
                                _calculateTotal();
                              });
                            }
                          },
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Quantité :'),
                        Row(
                          children: [
                            IconButton(
                                icon: const Icon(Icons.remove),
                                onPressed: () {
                                  if (photoDetails['quantity'] > 1) {
                                    setState(() {
                                      _photoDetails[imageUrl]!['quantity'] -= 1;
                                      _calculateTotal();
                                    });
                                  }
                                }),
                            Text('${photoDetails['quantity']}'),
                            IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: () {
                                  setState(() {
                                    _photoDetails[imageUrl]!['quantity'] += 1;
                                    _calculateTotal();
                                  });
                                }),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBatchCart() {
    // For batch mode, we need a way to set dimensions for all photos
    String? commonSize;
    if (_photoDetails.isNotEmpty) {
      final sizes =
          _photoDetails.values.map((d) => d['size'] as String).toSet();
      if (sizes.length == 1) {
        commonSize = sizes.first;
      }
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(5.0),
          child: Align(
            alignment: Alignment.centerRight, // Align to the right
            child: SizedBox(
              width: 180, // Reduced width
              child: DropdownButtonFormField<String>(
                value: commonSize,
                decoration: InputDecoration(
                  labelText: 'Dimension', // Shorter label for smaller input
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12), // Rounded borders
                  ),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  prefixIcon:
                      const Icon(Icons.straighten, size: 20), // Added icon
                ),
                items: _prices.keys
                    .map((size) =>
                        DropdownMenuItem(value: size, child: Text(size)))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      for (final key in _photoDetails.keys) {
                        _photoDetails[key]!['size'] = value;
                      }
                      _calculateTotal();
                    });
                  }
                },
              ),
            ),
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: _selectedImages.length,
            itemBuilder: (context, index) {
              final imageUrl = _selectedImages.elementAt(index);
              return Stack(
                children: [
                  (imageUrl.startsWith('http'))
                      ? Image.network(imageUrl, fit: BoxFit.cover)
                      : Image.file(File(imageUrl), fit: BoxFit.cover),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedImages.remove(imageUrl);
                          _photoDetails.remove(imageUrl);
                          _calculateTotal();
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(
                              255, 238, 33, 6), // Blue background
                          borderRadius:
                              BorderRadius.circular(10), // Keep rounded corners
                        ),
                        padding: const EdgeInsets.all(4),
                        child: const Icon(Icons.close,
                            size: 12, color: Colors.white), // White icon
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  void _showValidationPopup() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      pageBuilder: (context, animation, secondaryAnimation) => Container(),
      transitionBuilder: (context, anim1, anim2, child) {
        return Align(
          alignment: Alignment.topCenter,
          child: SlideTransition(
            position: Tween(begin: const Offset(0, -1), end: const Offset(0, 0))
                .animate(anim1),
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: MediaQuery.of(context).size.width, // Full width
                height: MediaQuery.of(context).size.height *
                    0.35, // Reduced screen height further
                decoration: const BoxDecoration(
                  color: AppColors
                      .background, // Set a background color for the container
                  borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(30)), // Rounded bottom border
                ),
                child: Stack(
                  children: [
                    const Positioned.fill(
                      child: ClipRRect(
                        borderRadius:
                            BorderRadius.vertical(bottom: Radius.circular(30)),
                        child: GeometricBackground(),
                      ),
                    ),
                    SingleChildScrollView(
                      // Make content scrollable
                      padding:
                          const EdgeInsets.all(30.0), // Reduced padding further
                      child: ConstrainedBox(
                        // Constrain width for better readability in landscape
                        constraints: const BoxConstraints(
                            maxWidth: 600), // Max width for content
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Résumé de la commande',
                              textAlign: TextAlign.center, // Centered title
                              style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary), // Darker text
                            ),
                            const SizedBox(height: 15), // Reduced height
                            // Delivery Options
                            Card(
                              color: Colors.white.withOpacity(0.9),
                              margin: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              child: SwitchListTile(
                                title: const Text('Livraison Xpress',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text(_selectedImages.length > 10
                                    ? 'Le surplus sera discuté avec le propriétaire'
                                    : 'Livraison rapide (+ 1500 FCFA)'),
                                value: _isExpress,
                                onChanged: (value) {
                                  setState(() {
                                    _isExpress = value;
                                    _calculateTotal();
                                  });
                                },
                              ),
                            ),
                            const SizedBox(height: 15), // Reduced height
                            const Text('Montant Total',
                                style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 16)), // Darker text
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
                              decoration: BoxDecoration(
                                color: AppColors.accent.withOpacity(
                                    0.9), // Distinct background color
                                borderRadius:
                                    BorderRadius.circular(30), // Rounded badge
                              ),
                              child: Text(
                                '${_totalPrice.toStringAsFixed(0)} FCFA',
                                style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        Colors.white), // White text for badge
                              ),
                            )
                                .animate(key: ValueKey(_totalPrice))
                                .fadeIn(duration: 300.ms)
                                .scale(begin: const Offset(0.8, 0.8)),
                            const SizedBox(height: 20), // Reduced height
                            ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).pop(); // Close the dialog
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            OrderSummaryScreen(
                                                orderDetails: _photoDetails)));
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                minimumSize: const Size(double.infinity, 50),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text(
                                'Voir le récapitulatif complet',
                                style: TextStyle(fontSize: 16),
                                textAlign: TextAlign.center,
                              ), // Centered button text
                            ),
                            const SizedBox(height: 8), // Reduced height
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text(
                                'Modifier la commande',
                                style: TextStyle(
                                    color: AppColors.textPrimary, fontSize: 16),
                                textAlign: TextAlign.center,
                              ), // Darker text and centered
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      // Close button
                      top: 20,
                      left: 10,
                      child: GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close,
                              color: AppColors.textPrimary),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileTab() {
    return Container(); // This tab is no longer shown, replaced by ProfilePage
  }

  Widget _buildTopCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6.0, 0, 6.0, 30.0), // Ajout de padding en bas pour le bouton
      child: Card(
        clipBehavior: Clip.none, // Permet au bouton de déborder
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
        child: SizedBox(
          height: 150,
          child: Stack(
            clipBehavior: Clip.none, // Permet au bouton de déborder
            alignment: Alignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(color: AppColors.primary, width: 2),
                ),
                child: Image.asset(
                  'assets/carousel/mxx.jpeg', //image dans le card d'accueil au homescreen
                  height: double.infinity,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                bottom: -25.0, // Descendu pour chevaucher la bordure
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.help_outline, size: 24),
                  label: const Text("Comment ça marche ?",
                      style: TextStyle(fontSize: 16)),
                  onPressed: () => _showHowItWorksDialog(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                )
                    .animate(
                      onComplete: (controller) => controller.repeat(),
                    )
                    .shimmer(
                      delay: 2000.milliseconds,
                      duration: 1000.milliseconds,
                      color: Colors.white.withOpacity(0.5),
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
      child: Wrap(
        spacing: 16.0,
        runSpacing: 16.0,
        alignment: WrapAlignment.spaceAround,
        children: [
          _buildQuickActionButton(
            icon: Icons.photo_album,
            label: 'Portfolio',
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const PortfolioScreen())),
          ),
          _buildQuickActionButton(
            icon: Icons.archive_outlined,
            label: 'Mes commandes',
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (context) => const HistoryScreen())),
          ),
          _buildQuickActionButton(
            icon: Icons.straighten,
            label: 'Prix & dimensions',
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (context) => const PricingScreen())),
          ),
          _buildQuickActionButton(
            icon: Icons.flash_on,
            label: 'Commande rapide',
            onTap: () => _onTabTapped(1), // Switch to Photos tab
          ),
          _buildQuickActionButton(
            icon: Icons.chat_bubble_outline,
            label: 'Nous contacter',
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (context) => const ContactScreen())),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton(
      {required IconData icon,
      required String label,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 80, // Constrain width to encourage wrapping
        child: Column(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: AppColors.primary.withOpacity(0.1),
              child: Icon(icon, color: AppColors.primary, size: 28),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center, // Center the text
              style:
                  const TextStyle(color: AppColors.textPrimary, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistorySection() {
    final recentHistory = _mockHistory
        .where((req) =>
            req.date.isAfter(DateTime.now().subtract(const Duration(days: 7))))
        .take(3)
        .toList();

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
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                OutlinedButton(
                  onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const HistoryScreen())),
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
                            Text(item.title,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w500)),
                            Text(DateFormat('dd MMM yyyy').format(item.date),
                                style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12)),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios,
                          size: 16, color: AppColors.textSecondary),
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
      )
          .animate(
            onComplete: (controller) => controller.repeat(),
          )
          .shimmer(
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
            itemBuilder: (context, index, realIndex) =>
                buildItem(localImages[index], true),
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
        ? buildLocalCarousel(
            "Impossible de charger les promotions. Mode hors-ligne.")
        : FutureBuilder<List<String>>(
            future: Future.delayed(const Duration(seconds: 2), () => []),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                    height: 140,
                    child: Center(child: CircularProgressIndicator()));
              }
              if (snapshot.hasError ||
                  !snapshot.hasData ||
                  snapshot.data!.isEmpty) {
                return buildLocalCarousel(
                    "Impossible de charger les promotions en ligne.");
              }
              final onlineImages = snapshot.data!;
              return CarouselSlider.builder(
                itemCount: onlineImages.length,
                itemBuilder: (context, index, realIndex) =>
                    buildItem(onlineImages[index], false),
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
              BottomNavigationBarItem(
                  icon: Icon(Icons.person), label: 'Profil'),
            ],
          ),
        ),
      ),
    );
  }

  void _showHowItWorksDialog() {
    final steps = [
      {
        'icon': Icons.photo_library_outlined,
        'title': 'Étape 1: Sélectionnez vos photos',
        'subtitle':
            'Parcourez votre galerie et choisissez les souvenirs que vous souhaitez immortaliser.',
      },
      {
        'icon': Icons.straighten_outlined,
        'title': 'Étape 2: Choisissez format et quantité',
        'subtitle':
            'Pour chaque photo, sélectionnez la taille d\'impression et le nombre de copies désirées.',
      },
      {
        'icon': Icons.payment_outlined,
        'title': 'Étape 3: Validez et payez',
        'subtitle':
            'Vérifiez votre commande, choisissez votre mode de paiement et réglez en toute sécurité.',
      },
      {
        'icon': Icons.local_shipping_outlined,
        'title': 'Étape 4: Recevez votre commande',
        'subtitle':
            'Nous préparons vos photos avec soin et vous notifions dès qu\'elles sont prêtes !',
      },
    ];

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, animation, secondaryAnimation) => Container(),
      transitionBuilder: (context, anim1, anim2, child) {
        return ScaleTransition(
          scale: anim1,
          child: AlertDialog(
            backgroundColor: Colors.transparent,
            contentPadding: EdgeInsets.zero,
            insetPadding: const EdgeInsets.symmetric(horizontal: 16.0),
            content: Stack(
              children: [
                const ClipRRect(
                  borderRadius: BorderRadius.all(Radius.circular(20)),
                  child: GeometricBackground(),
                ),
                SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Comment ça marche ?",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 20),
                      ...steps.asMap().entries.map((entry) {
                        int idx = entry.key;
                        Map<String, Object> step = entry.value;
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8.0),
                          color: AppColors.primary.withOpacity(0.05),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                            side: BorderSide(
                                color: AppColors.primary.withOpacity(0.2)),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                Icon(step['icon'] as IconData,
                                    color: AppColors.primary, size: 40),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        step['title'] as String,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        step['subtitle'] as String,
                                        style: const TextStyle(
                                            color: AppColors.textSecondary,
                                            fontSize: 14),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                            .animate()
                            .fadeIn(
                                delay: (200 * (idx + 1)).ms,
                                duration: 500.ms)
                            .slideX(begin: -0.2, curve: Curves.easeOut);
                      }).toList(),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: Colors.white,
                          shape: const StadiumBorder(),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 32, vertical: 12),
                        ),
                        child: const Text("J'ai compris !",
                            style: TextStyle(fontSize: 16)),
                      )
                    ],
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child:
                          const Icon(Icons.close, color: AppColors.textPrimary),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
