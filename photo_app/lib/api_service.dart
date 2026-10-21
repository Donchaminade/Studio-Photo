import 'dart:convert';
import 'dart:io';
import 'package:Picon/models/booking.dart';
import 'package:Picon/models/contact_info.dart';
import 'package:Picon/models/featured_content.dart';
import 'package:Picon/models/photo_format.dart';
import 'package:Picon/models/photo_frame.dart';
import 'package:Picon/models/app_notification.dart';
import 'package:Picon/models/order.dart';
import 'package:Picon/models/promotion.dart';
import 'package:Picon/utils/app_error.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static final String baseUrl = _resolveApiBaseUrl();
  static final String rootUrl = _resolveRootUrl(baseUrl);
  static SharedPreferences? _preferences;

  static const String _productionApiBaseUrl = 'https://api.photopicon.com/api';

  static String _resolveApiBaseUrl() {
    const envApiBaseUrl = String.fromEnvironment('API_BASE_URL');
    if (envApiBaseUrl.isNotEmpty) {
      return _normalizeApiBaseUrl(envApiBaseUrl);
    }

    if (kDebugMode) {
      debugPrint('API: production ($_productionApiBaseUrl). '
          'Backend local : --dart-define=API_BASE_URL=http://IP:8081/api');
    }

    return _productionApiBaseUrl;
  }

  static String _normalizeApiBaseUrl(String value) {
    final trimmed = value.trim().replaceFirst(RegExp(r'/$'), '');
    if (trimmed.endsWith('/api')) return trimmed;
    return '$trimmed/api';
  }

  static String _resolveRootUrl(String apiBase) {
    final normalized = apiBase.trim().replaceFirst(RegExp(r'/$'), '');
    if (normalized.endsWith('/api')) {
      return normalized.substring(0, normalized.length - 4);
    }
    return normalized;
  }

  /// Construit une URL absolue à partir d'une URL relative ou absolue.
  /// Ex: '/uploads/user_3/xxx/photo.jpg' → 'https://api.photopicon.com/uploads/user_3/xxx/photo.jpg'
  /// Les chemins locaux Android (/storage/..., /data/...) sont retournés tels quels.
  static String getFullImageUrl(String url) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return trimmed;
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    // Chemins serveur relatifs (photos commandées / album)
    if (trimmed.startsWith('/uploads/') || trimmed.startsWith('/api/')) {
      return '$rootUrl$trimmed';
    }
    if (trimmed.startsWith('uploads/')) {
      return '$rootUrl/$trimmed';
    }
    // Chemin local Android/iOS → tel quel
    return trimmed;
  }

  /// Headers HTTP pour charger les images protégées (/uploads/**).
  static Map<String, String> get imageAuthHeaders {
    final headers = <String, String>{};
    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    return headers;
  }

  // User details
  static String? _authToken;
  static String? _refreshToken;
  static bool _refreshing = false;

  /// Résultat du dernier essai de renouvellement. Un 401 n'est une session
  /// morte que si le serveur a explicitement rejeté le jeton de renouvellement.
  static _RefreshOutcome _lastRefreshOutcome = _RefreshOutcome.skipped;
  static int? _userId;
  static String? _userName;
  static String? _userLastName;
  static String? _userEmail;
  static String? _userPhone;
  // Pending payment data
  static Map<String, Map<String, dynamic>>? _pendingOrderDetails;
  static Map<String, double>? _pendingPrices;
  static String? _pendingPaymentMethod;
  static String? _pendingOrderId;

  // Commandes masquées localement (Soft Delete côté client)
  static List<String> _hiddenOrders = [];

  // Flag pour demander la réinitialisation du panier dans HomeScreen
  static bool shouldClearCart = false;

  static Future<void> init() async {
    _preferences = await SharedPreferences.getInstance();
    _authToken = _preferences?.getString('authToken');
    _refreshToken = _preferences?.getString('refreshToken');
    _userId = _preferences?.getInt('userId');
    _userName = _preferences?.getString('userName');
    _userLastName = _preferences?.getString('userLastName');
    _userEmail = _preferences?.getString('userEmail');
    _userPhone = _preferences?.getString('userPhone');
    _hiddenOrders = _preferences?.getStringList('hiddenOrders') ?? [];
  }

  // Getters for user details
  static String? get authToken => _authToken;
  static int? get userId => _userId;
  static String? get userName => _userName;
  static String? get userLastName => _userLastName;
  static String? get userEmail => _userEmail;
  static String? get userPhone => _userPhone;
  static List<String> get hiddenOrders => _hiddenOrders;
  static Map<String, Map<String, dynamic>>? get pendingOrderDetails =>
      _pendingOrderDetails;
  static Map<String, double>? get pendingPrices => _pendingPrices;
  static String? get pendingPaymentMethod => _pendingPaymentMethod;
  static String? get pendingOrderId => _pendingOrderId;

  static void setPendingPayment({
    required Map<String, Map<String, dynamic>> orderDetails,
    required Map<String, double> prices,
    required String paymentMethod,
    required String orderId,
  }) {
    _pendingOrderDetails = Map<String, Map<String, dynamic>>.from(orderDetails);
    _pendingPrices = Map<String, double>.from(prices);
    _pendingPaymentMethod = paymentMethod;
    _pendingOrderId = orderId;
  }

  static void clearPendingPayment() {
    _pendingOrderDetails = null;
    _pendingPrices = null;
    _pendingPaymentMethod = null;
    _pendingOrderId = null;
    shouldClearCart = true; // Signale à HomeScreen de vider le panier
  }

  /// Masque une commande localement (côté client uniquement)
  static Future<void> hideOrderLocally(int orderId) async {
    final strId = orderId.toString();
    if (!_hiddenOrders.contains(strId)) {
      _hiddenOrders.add(strId);
      await _preferences?.setStringList('hiddenOrders', _hiddenOrders);
    }
  }

  static Future<void> saveAuthDetails(Map<String, dynamic> authData) async {
    _lastRefreshOutcome = _RefreshOutcome.skipped;
    _authToken = authData['token'];
    _refreshToken = authData['refreshToken'] as String? ?? _refreshToken;
    _userId = authData['id'];
    _userName = authData['firstname'];
    _userLastName = authData['lastname'];
    _userEmail = authData['email'];
    _userPhone = authData['phone'];

    await _preferences?.setString('authToken', _authToken!);
    if (_refreshToken != null && _refreshToken!.isNotEmpty) {
      await _preferences?.setString('refreshToken', _refreshToken!);
    }
    await _preferences?.setInt('userId', _userId!);
    await _preferences?.setString('userName', _userName!);
    await _preferences?.setString('userLastName', _userLastName!);
    await _preferences?.setString('userEmail', _userEmail!);
    if (_userPhone != null) {
      await _preferences?.setString('userPhone', _userPhone!);
    }
  }

  static Future<void> clearAuthDetails() async {
    _authToken = null;
    _refreshToken = null;
    _userId = null;
    _userName = null;
    _userLastName = null;
    _userEmail = null;
    _userPhone = null;
    await _preferences?.remove('authToken');
    await _preferences?.remove('refreshToken');
    await _preferences?.remove('userId');
    await _preferences?.remove('userName');
    await _preferences?.remove('userLastName');
    await _preferences?.remove('userEmail');
    await _preferences?.remove('userPhone');
  }

  static Map<String, String> get _headers {
    final Map<String, String> headers = {
      'Content-Type': 'application/json; charset=UTF-8',
    };
    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    return headers;
  }

  static Future<http.Response> _safeGet(String url) async {
    return _withAuthRetry(() async {
      try {
        return await http.get(Uri.parse(url), headers: _headers).timeout(
              const Duration(seconds: 15),
              onTimeout: () => throw AppError.server(),
            );
      } catch (error) {
        throw AppError.from(error);
      }
    });
  }

  static Future<http.Response> _safePost(
      String url, Map<String, dynamic> body) async {
    return _withAuthRetry(() async {
      try {
        return await http
            .post(
              Uri.parse(url),
              headers: _headers,
              body: jsonEncode(body),
            )
            .timeout(
              const Duration(seconds: 15),
              onTimeout: () => throw AppError.server(),
            );
      } catch (error) {
        throw AppError.from(error);
      }
    });
  }

  static Future<http.Response> _withAuthRetry(
    Future<http.Response> Function() send,
  ) async {
    var response = await send();
    if (response.statusCode == 401 && await _tryRefreshToken()) {
      response = await send();
    }
    return response;
  }

  static Future<bool> _tryRefreshToken() async {
    if (_refreshing || _refreshToken == null || _refreshToken!.isEmpty) {
      _lastRefreshOutcome = _RefreshOutcome.skipped;
      return false;
    }
    _refreshing = true;
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/refresh'),
            headers: {'Content-Type': 'application/json; charset=UTF-8'},
            body: jsonEncode({'refreshToken': _refreshToken}),
          )
          .timeout(const Duration(seconds: 15));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = _decodeJson(response);
        if (data is Map<String, dynamic> && data['token'] is String) {
          await saveAuthDetails(data);
          _lastRefreshOutcome = _RefreshOutcome.refreshed;
          return true;
        }
      }
      // 404/405 : l'API prod n'a pas encore /auth/refresh. On garde la session.
      if (response.statusCode == 404 ||
          response.statusCode == 405 ||
          response.statusCode == 501) {
        _lastRefreshOutcome = _RefreshOutcome.unavailable;
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        _lastRefreshOutcome = _RefreshOutcome.rejected;
      } else {
        _lastRefreshOutcome = _RefreshOutcome.skipped;
      }
    } catch (_) {
      // Réseau ou réponse illisible : ce n'est pas la preuve que le jeton est mort.
      _lastRefreshOutcome = _RefreshOutcome.skipped;
    } finally {
      _refreshing = false;
    }
    return false;
  }

  /// Vrai seulement si /auth/refresh a répondu que le jeton est invalide.
  static bool get _sessionReallyExpired =>
      _lastRefreshOutcome == _RefreshOutcome.rejected;

  /// Vérifie le jeton au démarrage. Renvoie false si l’utilisateur doit se reconnecter.
  static Future<bool> ensureSession() async {
    if (_authToken == null || _userId == null) return false;
    try {
      final me = await getAuthDetails();
      if (me != null) return true;
      if (await _tryRefreshToken()) {
        return await getAuthDetails() != null;
      }
      if (_sessionReallyExpired) {
        await clearAuthDetails();
        return false;
      }
      return _authToken != null;
    } catch (e) {
      final err = AppError.from(e);
      if (err.kind == AppErrorKind.session) {
        await clearAuthDetails();
        return false;
      }
      // Serveur / réseau : on garde la session locale, l’UI affichera l’illustration.
      return true;
    }
  }

  static dynamic _decodeJson(http.Response response) {
    final raw = utf8.decode(response.bodyBytes).trim();
    if (raw.isEmpty) return null;
    if (raw.startsWith('<') ||
        raw.toLowerCase().contains('error code:') ||
        raw.toLowerCase().contains('cloudflare')) {
      throw AppError.server();
    }
    try {
      return jsonDecode(raw);
    } on FormatException {
      throw AppError.server();
    }
  }

  static String? _messageFromBody(http.Response response) {
    try {
      final decoded = _decodeJson(response);
      if (decoded is Map) {
        final message = decoded['message'] ?? decoded['detail'] ?? decoded['error'];
        if (message is String && message.trim().isNotEmpty) {
          return message.trim();
        }
      }
      if (decoded is String && decoded.trim().isNotEmpty) return decoded.trim();
    } catch (_) {}
    return null;
  }

  static dynamic _handleApiResponse(http.Response response) {
    if (response.statusCode == 401 && _authToken != null) {
      final message = _messageFromBody(response);
      if (_sessionReallyExpired) {
        throw AppError.session();
      }
      throw AppError.generic(
        message ?? 'Action refusée. Votre connexion est conservée.',
      );
    }
    if (response.statusCode == 403) {
      throw AppError.generic(
        _messageFromBody(response) ?? 'Accès refusé pour cette action.',
      );
    }
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return _decodeJson(response);
    }

    final decoded = () {
      try {
        return _decodeJson(response);
      } on AppError {
        throw AppError.from(
          AppError.server(),
          statusCode: response.statusCode,
        );
      }
    }();

    if (decoded is Map<String, dynamic>) {
      final errorMessage = decoded['message'];
      if (errorMessage is String && errorMessage.isNotEmpty) {
        throw AppError.from(errorMessage, statusCode: response.statusCode);
      }
      final detail = decoded['detail'];
      if (detail is String && detail.isNotEmpty) {
        throw AppError.from(detail, statusCode: response.statusCode);
      }
      final errors = decoded['errors'];
      if (errors is List && errors.isNotEmpty) {
        final firstError = errors.first;
        if (firstError is String && firstError.isNotEmpty) {
          throw AppError.from(firstError, statusCode: response.statusCode);
        }
        if (firstError is Map<String, dynamic>) {
          final msg = firstError['defaultMessage'] ??
              firstError['message'] ??
              firstError['error'];
          if (msg is String && msg.isNotEmpty) {
            throw AppError.from(msg, statusCode: response.statusCode);
          }
        }
      }
      final error = decoded['error'];
      if (error is String && error.isNotEmpty) {
        if (response.statusCode == 400 && error.toLowerCase() == 'bad request') {
          throw AppError.generic(
              'Requête refusée. Vérifiez email, téléphone et mot de passe.');
        }
        throw AppError.from(error, statusCode: response.statusCode);
      }
    }
    throw AppError.from('Erreur serveur', statusCode: response.statusCode);
  }

  /// Méthode spécifique pour gérer les réponses d'authentification.
  static Map<String, dynamic> _handleAuthResponse(http.Response response) {
    final responseData = _handleApiResponse(response);
    if (responseData != null && responseData.containsKey('token')) {
      return responseData;
    } else {
      throw Exception(responseData['message'] ??
          'La réponse du serveur est invalide ou ne contient pas de jeton.');
    }
  }

  static Future<Map<String, dynamic>?> getAuthDetails() async {
    // v5 : /auth/me n'existe pas sur l'API PICON. On valide le jeton avec un
    // GET authentifié réel et léger, et on renvoie le profil de la session.
    final url = '$baseUrl/notifications/unread-count';
    try {
      final response = await _safeGet(url);
      if (response.statusCode == 401) {
        if (_sessionReallyExpired) throw AppError.session();
        throw AppError.generic('Session conservée.');
      }
      if (response.statusCode == 200) {
        final Map<String, dynamic> details = {
          'firstname': _userName,
          'lastname': _userLastName,
          'email': _userEmail,
          'phone': _userPhone,
        };
        // ignore: dead_code, unnecessary_null_comparison
        if (false) {
          // Ancienne mise à jour du cache depuis /auth/me (conservée)
          _userName = details['firstname'];
          _userLastName = details['lastname'];
          _userEmail = details['email'];
          _userPhone = details['phone'];

          await _preferences?.setString('userName', _userName ?? '');
          await _preferences?.setString('userLastName', _userLastName ?? '');
          await _preferences?.setString('userEmail', _userEmail ?? '');
          await _preferences?.setString('userPhone', _userPhone ?? '');
        }
        return details;
      }
    } catch (e) {
      final err = AppError.from(e);
      if (err.kind == AppErrorKind.session || err.kind == AppErrorKind.server) {
        rethrow;
      }
    }
    return null;
  }

  static Future<Map<String, dynamic>> login(
      {String? email, String? phone, required String password}) async {
    final url = '$baseUrl/auth/authenticate';
    final Map<String, dynamic> body = {'password': password};

    if (email != null && email.isNotEmpty) {
      body['email'] = email;
    } else if (phone != null && phone.isNotEmpty) {
      body['phone'] = phone;
    } else {
      throw Exception('Email ou numéro de téléphone requis pour la connexion.');
    }

    final response = await _safePost(url, body);
    return _handleAuthResponse(response);
  }

  static Future<Map<String, dynamic>> signup(String name, String email,
      String phone, String password, String pin) async {
    final url = '$baseUrl/auth/register';

    final parts =
        name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    final firstname = parts.isNotEmpty ? parts.first : '';
    final lastname = parts.length > 1
        ? parts.sublist(1).join(' ')
        : firstname;

    final body = {
      'firstname': firstname,
      'lastname': lastname,
      'email': email.trim(),
      'phone': phone.trim(),
      'password': password,
      'pin': pin.trim(),
    };

    final response = await _safePost(url, body);
    return _handleAuthResponse(response);
  }

  /// /auth/forgot-password n'existe pas sur l'API : la récupération passe par
  /// le code secret (verify-pin + reset-password). Aucun appel réseau.
  @Deprecated('Utiliser verifyPinForPasswordReset')
  static Future<void> forgotPassword(String email) async {
    throw AppError.generic(
        'Utilisez « Mot de passe oublié » avec votre code secret.');
    // ignore: dead_code
    final url = '$baseUrl/auth/forgot-password';
    final body = {'email': email};
    final response = await _safePost(url, body);
    _handleApiResponse(response);
  }

  static Future<List<String>> getAlbumImages(int userId) async {
    // v5 : aucun endpoint /album/images côté API → pas d'appel (404 évité).
    return const [];
    // ignore: dead_code
    final url =
        '$baseUrl/album/images'; // Backend should infer user from token
    final response = await _safeGet(url);
    final data = _handleApiResponse(response);
    if (data == null || data['images'] == null) return [];
    return List<String>.from(data['images']);
  }

  /// GET /promotions/{id}
  static Future<Promotion> fetchPromotionById(int id) async {
    final response = await _safeGet('$baseUrl/promotions/$id');
    final data = _handleApiResponse(response);
    if (data is! Map) throw AppError.server();
    return Promotion.fromJson(Map<String, Object?>.from(data));
  }

  /// GET /featured-content/{id}
  static Future<FeaturedContent> fetchFeaturedContentById(int id) async {
    final response = await _safeGet('$baseUrl/featured-content/$id');
    final data = _handleApiResponse(response);
    if (data is! Map) throw AppError.server();
    return FeaturedContent.fromJson(Map<String, Object?>.from(data));
  }

  static Future<List<Promotion>> fetchPromotions() async {
    final url = '$baseUrl/promotions';
    final response = await _safeGet(url);
    final responseData = _handleApiResponse(response);
    if (responseData == null) return [];
    if (responseData is! List) {
      debugPrint('fetchPromotions: réponse inattendue ($responseData)');
      return [];
    }
    final promos = <Promotion>[];
    for (final item in responseData) {
      if (item is! Map<String, dynamic>) continue;
      try {
        promos.add(Promotion.fromJson(_normalizePromotionJson(item)));
      } catch (e) {
        debugPrint('Promotion ignorée (parse): $e — $item');
      }
    }
    return promos;
  }

  static Map<String, dynamic> _normalizePromotionJson(Map<String, dynamic> json) {
    final copy = Map<String, dynamic>.from(json);
    copy['title'] = (json['title'] as String?) ?? '';
    copy['imageUrl'] = (json['imageUrl'] as String?) ?? '';
    copy['active'] = json['active'] ?? true;
    copy['createdAt'] =
        _jsonToIsoDateTime(json['createdAt']) ?? DateTime.now().toUtc().toIso8601String();
    if (json['updatedAt'] != null) {
      copy['updatedAt'] = _jsonToIsoDateTime(json['updatedAt']);
    }
    final target = json['targetUrl'];
    if (target is String && target.trim().isEmpty) {
      copy['targetUrl'] = null;
    }
    return copy;
  }

  static String? _jsonToIsoDateTime(dynamic value) {
    if (value == null) return null;
    if (value is String && value.isNotEmpty) return value;
    if (value is List && value.length >= 3) {
      final y = (value[0] as num).toInt();
      final m = (value[1] as num).toInt();
      final d = (value[2] as num).toInt();
      final h = value.length > 3 ? (value[3] as num).toInt() : 0;
      final min = value.length > 4 ? (value[4] as num).toInt() : 0;
      final sec = value.length > 5 ? (value[5] as num).toInt() : 0;
      return DateTime(y, m, d, h, min, sec).toIso8601String();
    }
    return null;
  }

  static Future<List<PhotoFormat>> fetchDimensions() async {
    final url = '$baseUrl/public/dimensions';
    final response = await _safeGet(url);
    final responseData = _handleApiResponse(response);
    if (responseData == null) return [];
    final List<dynamic> list = responseData as List<dynamic>;
    return list.map((json) => PhotoFormat.fromJson(json)).toList();
  }

  static Future<List<PhotoFrame>> fetchFrames() async {
    final url = '$baseUrl/public/frames';
    final response = await _safeGet(url);
    final responseData = _handleApiResponse(response);
    if (responseData == null) return [];
    final List<dynamic> list = responseData as List<dynamic>;
    return list
        .whereType<Map<String, dynamic>>()
        .map(PhotoFrame.fromJson)
        .toList();
  }

  static Future<FeaturedContent?> fetchFeaturedContent() async {
    try {
      // Prod expose la liste sur GET /featured-content (pas /active).
      final list = await fetchActiveFeaturedContents();
      if (list.isEmpty) return null;
      return list.first;
    } catch (e) {
      debugPrint('fetchFeaturedContent: $e');
      return null;
    }
  }

  static Future<Booking> createBooking(Booking booking) async {
    final url = '$baseUrl/bookings';
    final body = {
      'title': booking.title,
      'description': booking.description,
      'userId': booking.userId,
      'startTime': booking.startTime.toIso8601String(),
      'endTime': booking.endTime.toIso8601String(),
      'status': booking.status.name.toUpperCase(),
      'type': _bookingTypeToJson(booking.type),
      'amount': booking.amount,
      'notes': booking.notes,
    };
    final response = await _safePost(url, body);
    final Map<String, dynamic> responseData = _handleApiResponse(response);
    return Booking.fromRawJson(responseData);
  }

  static String _bookingTypeToJson(BookingType type) {
    switch (type) {
      case BookingType.photoSession:
        return 'PHOTO_SESSION';
      case BookingType.event:
        return 'EVENT';
      case BookingType.portrait:
        return 'PORTRAIT';
      case BookingType.product:
        return 'PRODUCT';
      case BookingType.other:
        return 'OTHER';
    }
  }

// fetch user bookings
  /// Archive ZIP des photos d'une commande (GET /orders/{id}/download-photos).
  static Future<Uint8List> downloadOrderPhotosZip(int orderId) async {
    final url = '$baseUrl/orders/$orderId/download-photos';
    final response = await _withAuthRetry(() async {
      try {
        return await http.get(Uri.parse(url), headers: _headers).timeout(
              const Duration(seconds: 60),
              onTimeout: () => throw AppError.server(),
            );
      } catch (error) {
        throw AppError.from(error);
      }
    });
    if (response.statusCode == 200) return response.bodyBytes;
    if (response.statusCode == 404) {
      throw Exception('Commande introuvable ou sans photos.');
    }
    _handleApiResponse(response);
    throw AppError.server();
  }

  static Future<List<Booking>> fetchUserBookings() async {
    final url = '$baseUrl/bookings';
    final response = await _safeGet(url);
    final responseData = _handleApiResponse(response);
    if (responseData == null) return [];
    final List<dynamic> list = responseData as List<dynamic>;
    return list
        .map((json) => Booking.fromRawJson(json as Map<String, dynamic>))
        .toList();
  }

  // fetch active featured contents
  static Future<List<FeaturedContent>> fetchActiveFeaturedContents() async {
    try {
      final url = '$baseUrl/featured-content';
      final response = await _safeGet(url);
      final dynamic data = _handleApiResponse(response);
      if (data == null) return [];
      if (data is! List) return [];
      return data
          .whereType<Map<String, dynamic>>()
          .map((e) => FeaturedContent.fromJson(e.cast<String, Object?>()))
          .where((fc) => fc.active)
          .toList()
        ..sort((a, b) => a.priority.compareTo(b.priority));
    } catch (e) {
      debugPrint('fetchActiveFeaturedContents: $e');
      return [];
    }
  }

  /// Coordonnées studio de secours si l'API contact-info échoue (404/401/réseau).
  static const ContactInfo defaultContactInfo = ContactInfo(
    address: 'Kodjoviakopé',
    phoneNumber: '+228 98526226 / 72683032',
    whatsappNumber: '+228 98526226',
    email: 'infos@photopicon.com',
    openingHours: 'Lun-Dim: 8h00-20h00',
    facebookUrl: 'https://www.facebook.com/share/1NncFmswZN/',
  );

  // fetch contact info
  static Future<ContactInfo> fetchContactInfo() async {
    try {
      final url = '$baseUrl/public/contact-info';
      final response = await _safeGet(url);
      final responseData = _handleApiResponse(response);
      if (responseData is! Map<String, dynamic>) {
        // v5 : plus de coordonnées en dur affichées ; l'écran montre l'erreur.
        throw AppError.server();
      }
      return ContactInfo.fromJson(Map<String, Object?>.from(responseData));
    } catch (e) {
      debugPrint('fetchContactInfo: $e');
      rethrow;
    }
  }

// verify pin for password reset
  static Future<Map<String, dynamic>> verifyPinForPasswordReset(
      {String? email, String? phone, required String pin}) async {
    final url = '$baseUrl/auth/verify-pin';
    final Map<String, dynamic> body = {'pin': pin};

    if (email != null && email.isNotEmpty) {
      body['identifier'] = email;
    } else if (phone != null && phone.isNotEmpty) {
      body['identifier'] = phone;
    } else {
      throw Exception(
          'Email ou numéro de téléphone requis pour la vérification du code PIN.');
    }

    final response = await _safePost(url, body);
    return _handleApiResponse(response); // Expects { "resetToken": "..." }
  }

  // reset password with token
  static Future<void> resetPasswordWithToken(
      {required String token, required String newPassword}) async {
    final url = '$baseUrl/auth/reset-password';
    final body = {
      'token': token,
      'newPassword': newPassword,
    };
    final response = await _safePost(url, body);
    _handleApiResponse(response); // Expects no content on success
  }

  // create order
  static Future<Order> createOrder(Map<String, dynamic> orderDetails) async {
    final url = '$baseUrl/orders';
    final response = await _safePost(url, orderDetails);
    return Order.fromJson(_handleApiResponse(response));
  }

  /// Récupère le code USSD marchand calculé côté serveur pour une commande.
  ///
  /// Les codes marchands ne sont jamais stockés dans l'app : ils sont résolus
  /// par le backend (montant authoritatif serveur) et renvoyés via cet endpoint
  /// authentifié.
  static Future<String> fetchOrderUssdCode(int orderId) async {
    final url = '$baseUrl/orders/$orderId/ussd-code';
    final response = await _safeGet(url);
    final responseData = _handleApiResponse(response);
    final code = (responseData is Map<String, dynamic>)
        ? responseData['ussdCode']?.toString()
        : null;
    if (code == null || code.isEmpty) {
      throw Exception('Code de paiement indisponible.');
    }
    return code;
  }

  static Future<Order> confirmOrderPayment(int orderId,
      {String? paymentReference,
      String? paymentProofType,
      String? paymentProofText,
      String? paymentProofImageUrl}) async {
    final url = '$baseUrl/orders/$orderId/payment/confirm';
    final response = await _safePost(url, {
      if (paymentReference != null && paymentReference.trim().isNotEmpty)
        'paymentReference': paymentReference.trim(),
      if (paymentProofType != null && paymentProofType.trim().isNotEmpty)
        'paymentProofType': paymentProofType.trim(),
      if (paymentProofText != null && paymentProofText.trim().isNotEmpty)
        'paymentProofText': paymentProofText.trim(),
      if (paymentProofImageUrl != null && paymentProofImageUrl.trim().isNotEmpty)
        'paymentProofImageUrl': paymentProofImageUrl.trim(),
    });
    final data = _handleApiResponse(response);
    if (data is Map<String, dynamic>) {
      try {
        return Order.fromJson(Map<String, Object?>.from(data));
      } catch (e) {
        debugPrint('confirmOrderPayment: réponse 2xx illisible ($e)');
      }
    }
    // Le serveur a accepté la confirmation : on ne bloque pas le parcours
    // si le JSON de la commande ne correspond pas au modèle local.
    return Order(
      id: orderId,
      orderItems: const [],
      status: 'PENDING_PAYMENT',
      totalAmount: 0,
      paymentMethod: paymentReference ?? '',
      deliveryType: 'Standard',
      createdAt: DateTime.now(),
    );
  }

  static Future<String> uploadPaymentProof(int orderId, File imageFile) async {
    final url = '$baseUrl/orders/$orderId/payment-proof/upload';
    Future<http.Response> send() async {
      final request = http.MultipartRequest('POST', Uri.parse(url));
      if (_authToken != null && _authToken!.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $_authToken';
      }
      request.files.add(
        await http.MultipartFile.fromPath('file', imageFile.path),
      );
      final streamedResponse =
          await request.send().timeout(const Duration(seconds: 30));
      return http.Response.fromStream(streamedResponse);
    }

    final response = await _withAuthRetry(send);
    final responseData = _handleApiResponse(response) as Map<String, dynamic>;
    final fileUrl = responseData['url']?.toString();
    if (fileUrl == null || fileUrl.isEmpty) {
      throw Exception('URL de preuve invalide.');
    }
    return fileUrl;
  }

  // fetch my orders
  static Future<List<Order>> fetchMyOrders() async {
    final url = '$baseUrl/orders/my-orders';
    final response = await _safeGet(url);
    final responseData = _handleApiResponse(response);
    if (responseData == null) return [];
    final List<dynamic> list = responseData as List<dynamic>;
    return list.map((json) => Order.fromJson(json)).toList();
  }

  // fetch my orders raw payload (includes payment proof/status metadata)
  static Future<List<Map<String, dynamic>>> fetchMyOrdersRaw() async {
    final url = '$baseUrl/orders/my-orders';
    final response = await _safeGet(url);
    final responseData = _handleApiResponse(response);
    if (responseData == null) return [];
    final list = responseData as List<dynamic>;
    return list
        .whereType<Map<String, dynamic>>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  /// GET /orders/{id} brut (paymentStatus, preuve, dates…) pour les reçus.
  static Future<Map<String, dynamic>> fetchOrderRaw(int orderId) async {
    final response = await _safeGet('$baseUrl/orders/$orderId');
    final data = _handleApiResponse(response);
    if (data is! Map) throw AppError.server();
    return Map<String, dynamic>.from(data);
  }

  // fetch order by id
  static Future<Order?> fetchOrderById(String orderId) async {
    final url = '$baseUrl/orders/$orderId';
    try {
      final response = await _safeGet(url);
      if (response.statusCode == 200) {
        final responseData = _handleApiResponse(response);
        return Order.fromJson(responseData);
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  // cancel order
  static Future<void> cancelOrder(int orderId) async {
    final url = '$baseUrl/orders/$orderId/cancel';
    final response = await _safePost(url, {});
    _handleApiResponse(response);
  }

  // delete pending-payment order permanently (customer side)
  static Future<void> deletePendingPaymentOrder(int orderId) async {
    final url = '$baseUrl/orders/$orderId/pending-payment';
    final response = await http
        .delete(
          Uri.parse(url),
          headers: _headers,
        )
        .timeout(const Duration(seconds: 15));
    _handleApiResponse(response);
  }

  // update order
  static Future<Order> updateOrder(
      int orderId, Map<String, dynamic> updates) async {
    final url = '$baseUrl/orders/$orderId';
    final response = await http
        .put(
          Uri.parse(url),
          headers: _headers,
          body: jsonEncode(updates),
        )
        .timeout(const Duration(seconds: 15));
    return Order.fromJson(_handleApiResponse(response));
  }

  // ── Notifications client ─────────────────────────────────────────────────

  static Future<List<AppNotification>> fetchNotifications() async {
    final url = '$baseUrl/notifications';
    final response = await _safeGet(url);
    final responseData = _handleApiResponse(response);
    if (responseData == null) return [];
    final list = responseData as List<dynamic>;
    return list
        .whereType<Map<String, dynamic>>()
        .map((e) => AppNotification.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  static Future<int> fetchUnreadNotificationCount() async {
    final url = '$baseUrl/notifications/unread-count';
    final response = await _safeGet(url);
    final responseData = _handleApiResponse(response);
    if (responseData is Map && responseData['count'] != null) {
      return (responseData['count'] as num).toInt();
    }
    return 0;
  }

  static Future<AppNotification> markNotificationAsRead(int notificationId) async {
    final url = '$baseUrl/notifications/$notificationId/read';
    final response = await _safePost(url, {});
    return AppNotification.fromJson(
        Map<String, dynamic>.from(_handleApiResponse(response) as Map));
  }

  static Future<void> deleteNotification(int notificationId) async {
    final url = '$baseUrl/notifications/$notificationId';
    final response = await http
        .delete(Uri.parse(url), headers: _headers)
        .timeout(const Duration(seconds: 15));
    _handleApiResponse(response);
  }

  static Future<List<String>> uploadPhotos(List<dynamic> imageFiles) async {
    final url = '$baseUrl/orders/upload';
    final request = http.MultipartRequest('POST', Uri.parse(url));

    // Add headers, especially the authorization token
    request.headers.addAll({
      'Authorization': 'Bearer $_authToken',
    });

    // Add userId to the request fields
    if (_userId != null) {
      request.fields['userId'] = _userId.toString();
    } else {
      throw AppError.session();
    }

    // Add files to the request
    for (var imageFile in imageFiles) {
      request.files.add(await http.MultipartFile.fromPath(
        'files', // This key should match the backend's @RequestParam name
        imageFile.path,
      ));
    }

    try {
      var streamedResponse =
          await request.send().timeout(const Duration(minutes: 2));
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 401 && await _tryRefreshToken()) {
        final retry = http.MultipartRequest('POST', Uri.parse(url));
        retry.headers['Authorization'] = 'Bearer $_authToken';
        if (_userId != null) {
          retry.fields['userId'] = _userId.toString();
        }
        for (var imageFile in imageFiles) {
          retry.files.add(await http.MultipartFile.fromPath(
            'files',
            imageFile.path,
          ));
        }
        streamedResponse =
            await retry.send().timeout(const Duration(minutes: 2));
        response = await http.Response.fromStream(streamedResponse);
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final responseData = _decodeJson(response);
        if (responseData is Map && responseData.containsKey('urls')) {
          return List<String>.from(responseData['urls']);
        }
        throw AppError.generic(
            'L\'envoi des photos a échoué. Réessayez dans un instant.');
      }
      throw AppError.from(
        'upload',
        statusCode: response.statusCode,
        body: utf8.decode(response.bodyBytes),
      );
    } catch (e) {
      throw AppError.from(e);
    }
  }

}

enum _RefreshOutcome { refreshed, rejected, unavailable, skipped }
