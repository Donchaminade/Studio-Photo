import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Base URL de votre API
  static const String baseUrl = 'http://10.0.2.2/studio'; // Ajustez selon votre configuration

  /// Méthode privée pour effectuer une requête GET sécurisée
  static Future<http.Response> _safeGet(String url) async {
    try {
      return await http.get(Uri.parse(url)).timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw Exception(
                'Délai dépassé. Impossible de joindre le serveur.'),
          );
    } catch (error) {
      throw Exception('Erreur réseau : $error');
    }
  }

  /// Méthode privée pour effectuer une requête POST sécurisée
  static Future<http.Response> _safePost(
      String url, Map<String, String> body) async {
    try {
      return await http.post(Uri.parse(url), body: body).timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw Exception(
                'Délai dépassé. Impossible de joindre le serveur.'),
          );
    } catch (error) {
      throw Exception('Erreur réseau : $error');
    }
  }

  /// Méthode pour gérer les réponses de l'API
  static Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (responseData['success'] == true) {
        return responseData; // Retourne les données si succès
      } else {
        throw Exception(
            responseData['message'] ?? 'Erreur inconnue côté serveur.');
      }
    } else {
      throw Exception(
        'Erreur serveur. Code: ${response.statusCode}, Message: ${response.reasonPhrase}',
      );
    }
  }

  /// Méthode pour la connexion
  static Future<Map<String, dynamic>> login(
      String email, String password) async {
    final url = '$baseUrl/login.php';
    final body = {'email': email, 'password': password};

    final response = await _safePost(url, body);
    return _handleResponse(response);
  }

  /// Méthode pour l'inscription
  static Future<Map<String, dynamic>> signup(
      String name, String email, String password) async {
    final url = '$baseUrl/signup.php';
    final body = {'name': name, 'email': email, 'password': password};

    final response = await _safePost(url, body);
    return _handleResponse(response);
  }

  /// Méthode pour récupérer les images de l'album
  static Future<List<String>> getAlbumImages(int userId) async {
    final url = '$baseUrl/get_album_images.php?user_id=$userId';
    final response = await _safeGet(url);
    final data = _handleResponse(response);
    return List<String>.from(data['images']);
  }

  /// Méthode pour récupérer les tarifs des tirages
  static Future<List<Map<String, dynamic>>> getPrices() async {
    final url = '$baseUrl/get_prices.php';
    final response = await _safeGet(url);
    final data = _handleResponse(response);
    // Assumes the API returns a list of objects under the 'prices' key
    return List<Map<String, dynamic>>.from(data['prices']);
  }
}
