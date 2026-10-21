# Progression du Projet Backend Studio Photo

Ce document résume les travaux effectués sur le backend Spring Boot de l'application "Studio Photo" et les prochaines étapes.

## Contexte du Projet

Le projet consiste à développer une application pour un studio photo avec une partie mobile (Flutter) et une partie web (admin). La décision a été prise de reconstruire le backend en Java Spring Boot, en fournissant une API REST propre pour l'application mobile et une interface d'administration web. L'application mobile sera adaptée pour consommer cette nouvelle API.

## Travaux Réalisés

Les actions suivantes ont été menées sur la branche `feature/rebuild-backend` :

1.  **Création de la branche Git** : `feature/rebuild-backend`.
2.  **Nettoyage du répertoire** : L'ancien contenu du dossier `photo_app_backend` a été supprimé.
3.  **Génération du nouveau Projet Spring Boot** : Un projet Spring Boot a été généré via `start.spring.io` avec les dépendances suivantes : `Spring Web`, `Spring Data JPA`, `PostgreSQL Driver`, `Spring Security`, `Lombok`, `Thymeleaf`, `Validation`, `Spring Mail`.
4.  **Correction de la Structure des Dossiers** : Les fichiers du projet Spring Boot, initialement extraits à la racine du projet parent, ont été déplacés dans le dossier `photo_app_backend`.
5.  **Configuration du `pom.xml`** :
    *   Mise à jour de la version de `spring-boot-starter-parent` à `3.2.1`.
    *   Mise à jour de la `java.version` à `21`.
    *   Ajout des dépendances pour JWT (`jjwt-api`, `jjwt-impl`, `jjwt-jackson`).
6.  **Configuration Initiale de `application.properties`** : Ajout des propriétés pour le serveur, la base de données PostgreSQL, JPA, les clés JWT, l'emplacement de stockage des fichiers et la configuration de l'envoi d'e-mails.
7.  **Mise en place de l'Authentification JWT et du Modèle Utilisateur** :
    *   **Modèles** :
        *   `src/main/java/com/studiophoto/photoappbackend/model/Role.java` (Enum: USER, ADMIN)
        *   `src/main/java/com/studiophoto/photoappbackend/model/User.java` (Entité JPA implémentant `UserDetails`)
    *   **Répertoire** :
        *   `src/main/java/com/studiophoto/photoappbackend/repository/UserRepository.java`
    *   **Sécurité JWT** :
        *   `src/main/java/com/studiophoto/photoappbackend/security/JwtService.java` (Génération et validation des tokens JWT)
        *   `src/main/java/com/studiophoto/photoappbackend/security/JwtAuthenticationFilter.java` (Filtre d'authentification HTTP)
    *   **Configuration Spring Security** :
        *   `src/main/java/com/studiophoto/photoappbackend/config/ApplicationConfig.java` (Beans de configuration : UserDetailsService, AuthenticationProvider, AuthenticationManager, PasswordEncoder)
        *   `src/main/java/com/studiophoto/photoappbackend/config/SecurityConfig.java` (Chaîne de filtres de sécurité, CSRF désactivé, session stateless, protection des endpoints)
    *   **Authentification (DTOs, Service, Contrôleur)** :
        *   `src/main/java/com/studiophoto/photoappbackend/auth/RegisterRequest.java` (DTO pour l'inscription)
        *   `src/main/java/com/studiophoto/photoappbackend/auth/AuthenticationRequest.java` (DTO pour la connexion)
        *   `src/main/java/com/studiophoto/photoappbackend/auth/AuthenticationResponse.java` (DTO pour la réponse d'authentification)
        *   `src/main/java/com/studiophoto/photoappbackend/auth/AuthenticationService.java` (Logique métier d'inscription et d'authentification)
        *   `src/main/java/com/studiophoto/photoappbackend/auth/AuthenticationController.java` (Endpoints REST pour `/api/auth/register` et `/api/auth/authenticate`)

## Prochaines Étapes / Reste à Faire

### **Priorité 1 : Résolution de l'erreur Maven**
*   Le problème actuel de compilation Maven (`'dependencies.dependency.version' is missing`) doit être résolu avant de continuer. La suggestion est de supprimer le dossier `C:\Users\stani\.m2\repository` et de relancer `./mvnw clean install`.

### **Priorités de Développement (après résolution de Maven)**

2.  **Implémentation de la gestion des photos** :
    *   Création de l'entité `Photo` et de son `Repository`.
    *   Mise en place d'un service de stockage de fichiers (`StorageService` pour le téléversement et la récupération).
    *   Développement des endpoints REST (`/api/photos`) pour gérer les photos (upload, récupération par utilisateur, etc.).

3.  **Développement de l'interface d'administration** :
    *   Création d'un `AdminController`.
    *   Conception des templates Thymeleaf pour gérer les utilisateurs, les photos et potentiellement d'autres aspects (tableau de bord, etc.).

4.  **Mise en place de la gestion des commandes et des paiements** :
    *   Création des entités `Order`, `OrderItem`, `Payment` et de leurs `Repositories`.
    *   Développement des services et contrôleurs associés.
    *   Intégration du paiement via Stripe (si l'utilisateur décide d'inclure cette fonctionnalité).

---
**Statut actuel :** En attente de la résolution de l'erreur Maven pour poursuivre le développement.
