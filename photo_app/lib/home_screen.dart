import 'dart:async';
import 'dart:io';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:photo_app/api_service.dart';
import 'package:photo_app/booking_screen.dart';
import 'package:photo_app/contact_screen.dart';
import 'package:photo_app/history_screen.dart';
import 'package:photo_app/no_connection_screen.dart';
import 'package:photo_app/notifications_screen.dart';
import 'package:photo_app/order_summary_screen.dart';
import 'package:photo_app/portfolio_screen.dart';
import 'package:photo_app/pricing_screen.dart';
import 'package:photo_app/profile_page.dart';
import 'package:photo_app/utils/colors.dart';
import 'package:photo_app/utils/connectivity_service.dart';
import 'package:photo_app/widgets/picon_photo.dart';
import 'package:photo_app/widgets/picon_ui.dart';

class RecentRequest {
  final String title;
  final DateTime date;
  final IconData icon;

  RecentRequest({required this.title, required this.date, required this.icon});
}

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

  late String _currentUserName;
  late String _currentUserEmail;

  CartMode _selectedMode = CartMode.detail;
  bool _isExpress = false;
  double _totalPrice = 0.0;

  /// Tarifs utilisables dans le panier ; un format choisi dans « Prix &
  /// dimensions » y est ajouté.
  final Map<String, double> _prices = {
    '10x15 cm': 150,
    '15x20 cm': 300,
    '20x30 cm': 500,
  };

  /// Tirages ajoutés depuis l'écran des tarifs (format → quantité).
  final Map<String, int> _formatLines = {};

  final List<RecentRequest> _mockHistory = [
    RecentRequest(
      title: 'Commande de 15 photos',
      date: DateTime.now().subtract(const Duration(days: 1)),
      icon: Icons.photo_camera,
    ),
    RecentRequest(
      title: 'Réservation - Mariage',
      date: DateTime.now().subtract(const Duration(days: 3)),
      icon: Icons.calendar_today,
    ),
    RecentRequest(
      title: 'Tirage 20x30',
      date: DateTime.now().subtract(const Duration(days: 6)),
      icon: Icons.print,
    ),
    RecentRequest(
      title: 'Commande Album',
      date: DateTime.now().subtract(const Duration(days: 10)),
      icon: Icons.book,
    ),
    RecentRequest(
      title: "Photos d'identité",
      date: DateTime.now().subtract(const Duration(days: 4)),
      icon: Icons.person,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _currentUserName = widget.userName;
    _currentUserEmail = 'user-test@email.com';
    _albumImagesFuture = ApiService.getAlbumImages(widget.userId);
    _connectivitySubscription =
        _connectivityService.connectivityStream.listen((result) {
      if (result == ConnectivityResult.none) {
        if (!_isOffline && mounted) {
          setState(() => _isOffline = true);
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const NoConnectionScreen()),
          );
        }
      } else {
        if (_isOffline && mounted) {
          setState(() => _isOffline = false);
        }
      }
    });
    _syncTotal();
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }

  void _syncTotal() {
    for (final imageUrl in _selectedImages) {
      _photoDetails.putIfAbsent(
          imageUrl, () => {'size': '10x15 cm', 'quantity': 1});
    }
    var total = 0.0;
    for (final imageUrl in _selectedImages) {
      final details = _photoDetails[imageUrl];
      if (details != null) {
        final price = _prices[details['size']] ?? 0;
        total += price * ((details['quantity'] as num?)?.toInt() ?? 1);
      }
    }
    _formatLines.forEach((size, qty) => total += (_prices[size] ?? 0) * qty);
    if (_isExpress && _selectedImages.length <= 10) {
      total += 1500;
    }
    _totalPrice = total;
  }

  Future<void> _openPricing() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (context) => const PricingScreen()),
    );
    if (!mounted || result == null) return;
    final size = '${result['dimension']}';
    final price = (result['price'] as num?)?.toDouble() ?? 0;
    setState(() {
      _prices[size] = price;
      _formatLines[size] = (_formatLines[size] ?? 0) + 1;
      _syncTotal();
      _currentIndex = 2;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Tirage $size ajouté au panier')),
    );
  }

  void _changeFormatQuantity(String size, int delta) {
    setState(() {
      final next = (_formatLines[size] ?? 0) + delta;
      if (next <= 0) {
        _formatLines.remove(size);
      } else {
        _formatLines[size] = next;
      }
      _syncTotal();
    });
  }

  /// Photos + tirages choisis, transmis au récapitulatif.
  Map<String, Map<String, dynamic>> get _orderDetails => {
        ..._photoDetails,
        for (final e in _formatLines.entries)
          'format:${e.key}': {'size': e.key, 'quantity': e.value},
      };

  bool get _cartEmpty => _selectedImages.isEmpty && _formatLines.isEmpty;

  void _onTabTapped(int index) {
    if (index == 3) {
      _openProfile();
    } else {
      setState(() => _currentIndex = index);
    }
  }

  void _openProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfilePage(
          userName: _currentUserName,
          userEmail: _currentUserEmail,
          avatar: _avatar,
          onAvatarChanged: (newAvatar) {
            setState(() => _avatar = newAvatar);
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
  }

  Future<void> _quickPhotoOrder() async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage(imageQuality: 50);
    if (pickedFiles.isEmpty || !mounted) return;
    setState(() {
      for (final file in pickedFiles) {
        _selectedImages.add(file.path);
        _photoDetails.putIfAbsent(
            file.path, () => {'size': '10x15 cm', 'quantity': 1});
      }
      _syncTotal();
      _currentIndex = 2;
    });
  }

  void _toggleImage(String imageUrl) {
    setState(() {
      if (_selectedImages.contains(imageUrl)) {
        _selectedImages.remove(imageUrl);
        _photoDetails.remove(imageUrl);
      } else {
        _selectedImages.add(imageUrl);
        _photoDetails.putIfAbsent(
            imageUrl, () => {'size': '10x15 cm', 'quantity': 1});
      }
      _syncTotal();
    });
  }

  void _removeImage(String imageUrl) {
    setState(() {
      _selectedImages.remove(imageUrl);
      _photoDetails.remove(imageUrl);
      _syncTotal();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: true,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: [
                _buildHomeTab(),
                _buildPhotosTab(),
                _buildCommandsTab(),
                const SizedBox.shrink(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar:
          _FloatingNav(index: _currentIndex, onTap: _onTabTapped),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 76),
        child: TapScale(
          tooltip: 'Commande rapide',
          onTap: _quickPhotoOrder,
          child: const Material(
            color: AppColors.primary,
            elevation: 3,
            shape: CircleBorder(),
            child: SizedBox(
              width: 58,
              height: 58,
              child: Icon(Icons.add_a_photo, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final initials = _initials(_currentUserName);
    final avatar = CircleAvatar(
      radius: 22,
      backgroundColor: AppColors.accent,
      backgroundImage: _avatar != null ? FileImage(_avatar!) : null,
      child: _avatar == null
          ? Text(
              initials,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 14),
            )
          : null,
    );
    return Padding(
      padding:
          EdgeInsets.fromLTRB(16, MediaQuery.paddingOf(context).top + 8, 4, 6),
      child: Row(
        children: [
          TapScale(
            onTap: _openProfile,
            child: reduceMotion(context)
                ? avatar
                : Hero(tag: 'picon-avatar', child: avatar),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ravi de vous revoir',
                  style:
                      TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
                Text(
                  _currentUserName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Notifications',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const NotificationsScreen()),
              );
            },
            icon: const Icon(Icons.notifications_none_rounded,
                color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeTab() {
    final recent = _mockHistory
        .where((req) =>
            req.date.isAfter(DateTime.now().subtract(const Duration(days: 7))))
        .take(3)
        .toList();
    final count = _selectedImages.length;
    final progress = (count / 10).clamp(0.0, 1.0);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 140),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Reveal(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Image.asset(
                        'assets/images/pro.png',
                        height: 28,
                        cacheWidth: 120,
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          count <= 1 ? '$count photo' : '$count photos',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Panier',
                      style: TextStyle(color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 4),
                  AnimatedFcfa(value: _totalPrice),
                  const SizedBox(height: 8),
                  Text(
                    _isExpress
                        ? 'Livraison Xpress incluse'
                        : 'Impression à domicile, au Togo',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Reveal(index: 1, child: _buildQuickActions()),
          const SizedBox(height: 16),
          Reveal(index: 2, child: _buildFeaturedCard()),
          const SizedBox(height: 16),
          Reveal(
            index: 3,
            child: PiconCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Commande en cours',
                      style:
                          TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(
                    count == 0
                        ? 'Votre panier est vide. Sélectionnez des photos pour commencer.'
                        : count > 10
                            ? 'Le surplus sera discuté avec le propriétaire'
                            : 'Livraison Xpress : $count/10 photos',
                    style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        height: 1.3),
                  ),
                  const SizedBox(height: 12),
                  FillBar(progress: progress, color: AppColors.primary),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Reveal(
            index: 4,
            child: SectionTitle(
              title: 'Historique récent',
              trailing: OutlinedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const HistoryScreen()),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  shape: const StadiumBorder(),
                  visualDensity: VisualDensity.compact,
                ),
                child: const Text('Voir tout'),
              ),
            ),
          ),
          const SizedBox(height: 8),
          for (var i = 0; i < recent.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Reveal(
                index: 5 + i,
                child: PiconCard(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const HistoryScreen()),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor:
                            AppColors.primary.withValues(alpha: 0.08),
                        child: Icon(recent[i].icon,
                            color: AppColors.primary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(recent[i].title,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700)),
                            Text(
                              DateFormat('dd MMM yyyy').format(recent[i].date),
                              style: const TextStyle(
                                  color: AppColors.textSecondary, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios,
                          size: 14, color: AppColors.textSecondary),
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: 8),
          const Reveal(index: 8, child: _PromoCarousel()),
          if (_isOffline)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'Impossible de charger les promotions. Mode hors-ligne.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFeaturedCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: SizedBox(
        height: 210,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/carousel/mxx.jpeg',
              fit: BoxFit.cover,
              cacheWidth: 900,
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x00000000), Color(0xCC071433)],
                ),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 14,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Le studio',
                    style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Vos souvenirs, imprimés avec soin',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 10),
                  FilledButton.icon(
                    onPressed: _showHowItWorksDialog,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primary,
                      visualDensity: VisualDensity.compact,
                      minimumSize: const Size(48, 44),
                    ),
                    icon: const Icon(Icons.help_outline, size: 18),
                    label: const Text('Comment ça marche ?'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    final actions = <({IconData icon, String label, VoidCallback onTap})>[
      (
        icon: Icons.photo_album,
        label: 'Portfolio',
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (context) => const PortfolioScreen())),
      ),
      (
        icon: Icons.archive_outlined,
        label: 'Mes commandes',
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (context) => const HistoryScreen())),
      ),
      (
        icon: Icons.straighten,
        label: 'Prix & dimensions',
        onTap: _openPricing,
      ),
      (
        icon: Icons.event_available_outlined,
        label: 'Réserver',
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (context) => const BookingScreen())),
      ),
      (
        icon: Icons.flash_on,
        label: 'Commande rapide',
        onTap: () => _onTabTapped(1),
      ),
      (
        icon: Icons.chat_bubble_outline,
        label: 'Nous contacter',
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (context) => const ContactScreen())),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: actions.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 10,
        childAspectRatio: 0.92,
      ),
      itemBuilder: (context, index) {
        final action = actions[index];
        return TapScale(
          onTap: action.onTap,
          child: Column(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                        color: AppColors.cardShadow,
                        blurRadius: 10,
                        offset: Offset(0, 4)),
                  ],
                ),
                child: Icon(action.icon, color: AppColors.primary, size: 24),
              ),
              const SizedBox(height: 6),
              Text(
                action.label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w600, height: 1.15),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPhotosTab() {
    return ColoredBox(
      color: AppColors.background,
      child: FutureBuilder<List<String>>(
        future: _albumImagesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: AppColors.primary));
          }
          if (snapshot.hasError) {
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Text('Erreur: ${snapshot.error}',
                    textAlign: TextAlign.center),
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const PiconEmpty(
              icon: Icons.photo_library_outlined,
              title: 'Aucune image trouvée.',
            );
          }
          final images = snapshot.data!;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Text('Photos',
                    style:
                        TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
              ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 140),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1,
                  ),
                  itemCount: images.length,
                  itemBuilder: (context, index) {
                    final imageUrl = images[index];
                    final selected = _selectedImages.contains(imageUrl);
                    return TapScale(
                      onTap: () => _toggleImage(imageUrl),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            PiconPhoto(source: imageUrl, cachePixels: 480),
                            if (selected)
                              const DecoratedBox(
                                decoration:
                                    BoxDecoration(color: Color(0x55032A85)),
                              ),
                            if (selected)
                              const Positioned(
                                top: 8,
                                right: 8,
                                child: Icon(Icons.check_circle,
                                    color: Colors.white, size: 28),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCommandsTab() {
    return ColoredBox(
      color: AppColors.background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Text('Panier',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SegmentedButton<CartMode>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(
                    value: CartMode.detail, label: Text('Par détail')),
                ButtonSegment(value: CartMode.batch, label: Text('Par lot')),
              ],
              selected: {_selectedMode},
              onSelectionChanged: (selection) {
                setState(() {
                  _selectedMode = selection.first;
                  _syncTotal();
                });
              },
              style: ButtonStyle(
                visualDensity: VisualDensity.comfortable,
                shape: WidgetStatePropertyAll(
                  RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _cartEmpty
                ? const PiconEmpty(
                    icon: Icons.shopping_cart_outlined,
                    title: 'Votre panier est vide.',
                    subtitle:
                        'Sélectionnez des photos pour commencer une commande !',
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_formatLines.isNotEmpty) _buildFormatLines(),
                      Expanded(
                        child: _selectedImages.isEmpty
                            ? const SizedBox.shrink()
                            : _selectedMode == CartMode.detail
                                ? _buildDetailCart()
                                : _buildBatchCart(),
                      ),
                    ],
                  ),
          ),
          if (!_cartEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Total : ${_totalPrice.toStringAsFixed(0)} FCFA',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, color: AppColors.primary),
                  ),
                  const SizedBox(height: 8),
                  PiconButton(
                    label: 'Valider',
                    icon: Icons.check_circle_outline,
                    onPressed: _showValidationPopup,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFormatLines() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: PiconCard(
        padding: const EdgeInsets.fromLTRB(14, 12, 6, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Tirages choisis',
                style: TextStyle(fontWeight: FontWeight.w800)),
            for (final e in _formatLines.entries)
              Row(
                key: ValueKey('format-${e.key}'),
                children: [
                  const Icon(Icons.print_outlined,
                      size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${e.key} · ${((_prices[e.key] ?? 0) * e.value).toStringAsFixed(0)} FCFA',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Retirer un tirage',
                    visualDensity: VisualDensity.compact,
                    onPressed: () => _changeFormatQuantity(e.key, -1),
                    icon: const Icon(Icons.remove_circle_outline,
                        color: AppColors.textSecondary),
                  ),
                  Text('${e.value}',
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                  IconButton(
                    tooltip: 'Ajouter un tirage',
                    visualDensity: VisualDensity.compact,
                    onPressed: () => _changeFormatQuantity(e.key, 1),
                    icon: const Icon(Icons.add_circle_outline,
                        color: AppColors.primary),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailCart() {
    final images = _selectedImages.toList(growable: false);
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      itemCount: images.length,
      itemBuilder: (context, index) {
        final imageUrl = images[index];
        final photoDetails =
            _photoDetails[imageUrl] ?? {'size': '10x15 cm', 'quantity': 1};
        final price = _prices[photoDetails['size']] ?? 0;
        final quantity = (photoDetails['quantity'] as num?)?.toInt() ?? 1;
        final subtotal = price * quantity;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            clipBehavior: Clip.antiAlias,
            child: ExpansionTile(
              key: ValueKey(imageUrl),
              tilePadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              title: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: 56,
                      height: 56,
                      child: PiconPhoto(source: imageUrl, cachePixels: 180),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Photo ${index + 1}',
                            style:
                                const TextStyle(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 2),
                        Text(
                          '${subtotal.toStringAsFixed(0)} FCFA',
                          style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Retirer',
                    onPressed: () => _removeImage(imageUrl),
                    icon: const CircleAvatar(
                      radius: 14,
                      backgroundColor: AppColors.error,
                      child: Icon(Icons.delete, size: 16, color: Colors.white),
                    ),
                  ),
                ],
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Text('Taille :'),
                          const Spacer(),
                          DropdownButton<String>(
                            value:
                                photoDetails['size'] as String? ?? '10x15 cm',
                            borderRadius: BorderRadius.circular(12),
                            items: _prices.keys
                                .map((size) => DropdownMenuItem(
                                    value: size, child: Text(size)))
                                .toList(),
                            onChanged: (value) {
                              if (value == null) return;
                              setState(() {
                                _photoDetails.putIfAbsent(imageUrl,
                                    () => {'size': value, 'quantity': 1});
                                _photoDetails[imageUrl]!['size'] = value;
                                _syncTotal();
                              });
                            },
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          const Text('Quantité :'),
                          const Spacer(),
                          IconButton(
                            onPressed: quantity > 1
                                ? () {
                                    setState(() {
                                      _photoDetails[imageUrl]!['quantity'] =
                                          quantity - 1;
                                      _syncTotal();
                                    });
                                  }
                                : null,
                            icon: const Icon(Icons.remove_circle_outline),
                          ),
                          Text('$quantity',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w800)),
                          IconButton(
                            onPressed: () {
                              setState(() {
                                _photoDetails.putIfAbsent(imageUrl,
                                    () => {'size': '10x15 cm', 'quantity': 1});
                                _photoDetails[imageUrl]!['quantity'] =
                                    quantity + 1;
                                _syncTotal();
                              });
                            },
                            icon: const Icon(Icons.add_circle_outline),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBatchCart() {
    String? commonSize;
    if (_photoDetails.isNotEmpty) {
      final sizes =
          _photoDetails.values.map((d) => d['size'] as String).toSet();
      if (sizes.length == 1) commonSize = sizes.first;
    }
    final images = _selectedImages.toList(growable: false);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: DropdownButtonFormField<String>(
            initialValue: commonSize,
            isExpanded: true,
            decoration: piconField('Dimension', icon: Icons.straighten),
            items: _prices.keys
                .map((size) => DropdownMenuItem(value: size, child: Text(size)))
                .toList(),
            onChanged: (value) {
              if (value == null) return;
              setState(() {
                for (final key in _selectedImages) {
                  _photoDetails.putIfAbsent(
                      key, () => {'size': value, 'quantity': 1});
                  _photoDetails[key]!['size'] = value;
                }
                _syncTotal();
              });
            },
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            itemCount: images.length,
            itemBuilder: (context, index) {
              final imageUrl = images[index];
              return ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    PiconPhoto(source: imageUrl, cachePixels: 280),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () => _removeImage(imageUrl),
                        child: const CircleAvatar(
                          radius: 12,
                          backgroundColor: AppColors.error,
                          child:
                              Icon(Icons.close, size: 14, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showValidationPopup() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                  bottom: MediaQuery.viewInsetsOf(context).bottom),
              child: Container(
                constraints: BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(context).height * 0.72),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 42,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.line,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: IconButton(
                          tooltip: 'Fermer',
                          onPressed: () => Navigator.of(sheetContext).pop(),
                          icon: const Icon(Icons.close),
                        ),
                      ),
                      const Text(
                        'Résumé de la commande',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 14),
                      Card(
                        margin: EdgeInsets.zero,
                        elevation: 0,
                        color: AppColors.fieldFill,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        child: SwitchListTile(
                          title: const Text('Livraison Xpress',
                              style: TextStyle(fontWeight: FontWeight.w800)),
                          subtitle: Text(
                            _selectedImages.length > 10
                                ? 'Le surplus sera discuté avec le propriétaire'
                                : 'Livraison rapide (+ 1500 FCFA)',
                          ),
                          value: _isExpress,
                          onChanged: (value) {
                            setState(() {
                              _isExpress = value;
                              _syncTotal();
                            });
                            setSheetState(() {});
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text('Montant Total',
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 16)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Text(
                          '${_totalPrice.toStringAsFixed(0)} FCFA',
                          style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 18),
                      PiconButton(
                        label: 'Voir le récapitulatif complet',
                        onPressed: () {
                          Navigator.of(sheetContext).pop();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => OrderSummaryScreen(
                                  orderDetails: _orderDetails),
                            ),
                          );
                        },
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(sheetContext).pop(),
                        child: const Text(
                          'Modifier la commande',
                          style: TextStyle(
                              color: AppColors.textPrimary, fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
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
            "Pour chaque photo, sélectionnez la taille d'impression et le nombre de copies désirées.",
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
            "Nous préparons vos photos avec soin et vous notifions dès qu'elles sont prêtes !",
      },
    ];

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          backgroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: ConstrainedBox(
            constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(dialogContext).height * 0.82),
            child: Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(18, 28, 18, 18),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Comment ça marche ?',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 22, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 12),
                      for (var i = 0; i < steps.length; i++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Reveal(
                            index: i,
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color:
                                    AppColors.primary.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                    color: AppColors.primary
                                        .withValues(alpha: 0.12)),
                              ),
                              child: Row(
                                children: [
                                  Icon(steps[i]['icon'] as IconData,
                                      color: AppColors.primary, size: 32),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          steps[i]['title'] as String,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w800),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          steps[i]['subtitle'] as String,
                                          style: const TextStyle(
                                              color: AppColors.textSecondary,
                                              fontSize: 13,
                                              height: 1.3),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 6),
                      PiconButton(
                        label: "J'ai compris !",
                        onPressed: () => Navigator.of(dialogContext).pop(),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: IconButton(
                    tooltip: 'Fermer',
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    icon: const Icon(Icons.close),
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

String _initials(String name) {
  final parts =
      name.trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  return parts.take(2).map((s) => s[0]).join().toUpperCase();
}

/// Visuels du carrousel promo, préchargés pendant le splash.
const List<String> kPromoImages = [
  'assets/carousel/Ajouter un sous-titre.png',
  'assets/carousel/car.jpg',
  'assets/carousel/car1.jpg',
  'assets/carousel/pflex.jpeg',
  'assets/carousel/Pink Modern Pink October Instagram Post  (1).png',
  'assets/carousel/Pink Modern Pink October Instagram Post  (2).png',
  'assets/carousel/Pink Modern Pink October Instagram Post .png',
  'assets/images/pro.png',
];

class _PromoCarousel extends StatelessWidget {
  const _PromoCarousel();

  static const List<String> _localImages = kPromoImages;

  @override
  Widget build(BuildContext context) {
    final reduced = reduceMotion(context);
    return RepaintBoundary(
      child: CarouselSlider.builder(
        itemCount: _localImages.length,
        itemBuilder: (context, index, realIndex) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: ColoredBox(
                color: AppColors.primary.withValues(alpha: 0.05),
                child: Image.asset(
                  _localImages[index],
                  fit: BoxFit.cover,
                  width: double.infinity,
                  cacheWidth: 800,
                  errorBuilder: (_, __, ___) =>
                      const Icon(Icons.image_not_supported_outlined),
                ),
              ),
            ),
          );
        },
        options: CarouselOptions(
          height: 150,
          viewportFraction: 0.86,
          enlargeCenterPage: !reduced,
          autoPlay: !reduced,
          autoPlayInterval: const Duration(seconds: 4),
        ),
      ),
    );
  }
}

class _FloatingNav extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;

  const _FloatingNav({required this.index, required this.onTap});

  static const _items = <(IconData, String)>[
    (Icons.home_rounded, 'Accueil'),
    (Icons.photo_album_outlined, 'Photos'),
    (Icons.shopping_cart_outlined, 'Commandes'),
    (Icons.person_outline_rounded, 'Profil'),
  ];

  @override
  Widget build(BuildContext context) {
    final reduced = reduceMotion(context);
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, bottom > 0 ? bottom : 12),
      child: Material(
        color: Colors.white,
        elevation: 8,
        shadowColor: AppColors.cardShadow,
        borderRadius: BorderRadius.circular(28),
        child: SizedBox(
          height: 68,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final tab = constraints.maxWidth / _items.length;
              return Stack(
                children: [
                  AnimatedPositioned(
                    duration: Duration(milliseconds: reduced ? 1 : 280),
                    curve: Curves.easeOutCubic,
                    left: tab * index + 6,
                    top: 8,
                    bottom: 8,
                    width: tab - 12,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(22),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      for (var i = 0; i < _items.length; i++)
                        Expanded(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => onTap(i),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _items[i].$1,
                                  size: 22,
                                  color: i == index
                                      ? Colors.white
                                      : AppColors.textSecondary,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _items[i].$2,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: i == index
                                        ? Colors.white
                                        : AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
