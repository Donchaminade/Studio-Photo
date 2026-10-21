# Correction du Fichier `api_service.dart` pour la Communication avec le Backend Spring Boot

Ce document décrit les modifications nécessaires à apporter au fichier `photo_app/lib/api_service.dart` de l'application Flutter afin d'assurer une communication correcte avec le backend Spring Boot pour les fonctionnalités de connexion et d'inscription.

## Contexte du Problème

L'analyse initiale a révélé plusieurs incohérences entre la manière dont l'application Flutter tentait de communiquer avec le backend et la manière dont le backend Spring Boot était configuré :

1.  **Endpoints Incorrects** : L'application Flutter appelait des endpoints de type `.php` (`login.php`, `signup.php`), alors que le backend Spring Boot expose des endpoints REST (`/api/auth/authenticate`, `/api/auth/register`).
2.  **URL de Base Inexacte** : La `baseUrl` dans Flutter (`http://10.0.2.2/studio/`) ne correspondait pas à la configuration par défaut du backend Spring Boot (qui est sur le port `8080` et sans chemin de contexte `/studio/`). L'adresse `10.0.2.2` est correcte pour l'émulateur Android pour atteindre le `localhost` de la machine hôte.
3.  **Format du Corps de Requête Inadéquat** : L'application Flutter envoyait les données sous forme `application/x-www-form-urlencoded`, tandis que le backend Spring Boot attend un corps de requête JSON (`application/json`).
4.  **Champs d'Inscription Disparates** : L'application Flutter envoyait un champ `name` pour l'inscription, alors que le backend Spring Boot attendait des champs `firstname` et `lastname`.

## Modifications Apportées à `api_service.dart`

Le code suivant inclut les corrections nécessaires pour résoudre les problèmes mentionnés ci-dessus.

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Base URL de votre API Spring Boot
  // Assurez-vous que cette URL pointe vers votre instance de backend Spring Boot.
  // 10.0.2.2 est l'alias pour localhost sur un émulateur Android.
  // Le port 8080 est le port par défaut de Spring Boot.
  static const String baseUrl = 'http://10.0.2.2:8080/api';

  /// Méthode privée pour effectuer une requête POST sécurisée avec un corps JSON.
  /// Elle gère également les timeouts et les erreurs réseau.
  static Future<http.Response> _safePost(String url, Map<String, dynamic> body) async {
    try {
      return await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json; charset=UTF-8'}, // Spécifie le type de contenu JSON
        body: jsonEncode(body), // Convertit le Map en chaîne JSON
      ).timeout(
        const Duration(seconds: 15), // Délai d'attente de 15 secondes
        onTimeout: () => throw Exception('Délai dépassé. Impossible de joindre le serveur.'),
      );
    } catch (error) {
      // Gestion améliorée des erreurs réseau pour fournir un feedback plus clair.
      throw Exception('Erreur réseau : Impossible de se connecter au serveur. Vérifiez votre connexion et l\'adresse du serveur.');
    }
  }

  /// Méthode pour gérer et interpréter les réponses de l'API.
  /// Elle vérifie le code de statut HTTP et tente de décoder les messages d'erreur JSON.
  static Map<String, dynamic> _handleResponse(http.Response response) {
    // Si le statut HTTP n'est pas 200 (OK), cela indique une erreur.
    if (response.statusCode != 200) {
      try {
        final errorBody = jsonDecode(response.body);
        // Tente d'extraire un message d'erreur du corps de la réponse JSON.
        final errorMessage = errorBody['message'] ?? 'Erreur inconnue du serveur.';
        throw Exception('Erreur ${response.statusCode}: $errorMessage');
      } catch (e) {
        // Si le corps n'est pas un JSON valide ou est vide, utilise le message de raison HTTP.
        throw Exception('Erreur serveur. Code: ${response.statusCode}, Message: ${response.reasonPhrase}');
      }
    }

    // Si le statut HTTP est 200, nous supposons un succès et décodons la réponse.
    final Map<String, dynamic> responseData = jsonDecode(response.body);

    // Votre backend Spring Boot renvoie un token en cas de succès d'authentification/inscription.
    // Cette logique vérifie la présence de ce token. Ajustez si la structure de succès de votre API est différente.
    if (responseData.containsKey('token')) {
      return responseData;
    } else {
       // Cas où le statut est 200 mais le corps ne contient pas le token attendu ou a une structure inattendue.
       final errorMessage = responseData['message'] ?? 'La réponse du serveur est invalide.';
       throw Exception(errorMessage);
    }
  }

  /// Méthode pour la connexion d'un utilisateur.
  /// Elle envoie les informations d'identification au endpoint d'authentification du backend.
  static Future<Map<String, dynamic>> login(String email, String password) async {
    const url = '$baseUrl/auth/authenticate'; // Endpoint de connexion du backend
    final body = {'email': email, 'password': password};

    final response = await _safePost(url, body);
    return _handleResponse(response);
  }

  /// Méthode pour l'inscription d'un nouvel utilisateur.
  /// Elle adapte les champs d'entrée de Flutter (`name`) aux attentes du backend (`firstname`, `lastname`).
  static Future<Map<String, dynamic>> signup(String name, String email, String password) async {
    const url = '$baseUrl/auth/register'; // Endpoint d'inscription du backend
    
    // Logique pour diviser le champ 'name' en 'firstname' et 'lastname'.
    // Si le nom contient un espace, il est divisé. Sinon, le 'name' entier est utilisé comme 'firstname'.
    String firstname = name;
    String lastname = '';
    if (name.contains(' ')) {
      final parts = name.split(' ');
      firstname = parts.first;
      lastname = parts.sublist(1).join(' ');
    }

    final body = {
      'firstname': firstname,
      'lastname': lastname,
      'email': email,
      'password': password
    };

    final response = await _safePost(url, body);
    return _handleResponse(response);
  }
}
```

## Étapes de Vérification

Pour vérifier que ces modifications permettent une communication correcte :

1.  **Remplacez le contenu de votre fichier `photo_app/lib/api_service.dart`** par le code fourni ci-dessus.
2.  **Démarrez votre backend Spring Boot.** Assurez-vous qu'il est accessible sur `http://localhost:8080`.
3.  **Exécutez votre application Flutter mobile** sur un émulateur ou un appareil physique.
4.  **Tentez de vous inscrire et de vous connecter** via l'interface de l'application mobile.

Si le backend et le frontend sont correctement configurés et que ces modifications sont appliquées, les fonctionnalités de connexion et d'inscription devraient maintenant fonctionner.

```