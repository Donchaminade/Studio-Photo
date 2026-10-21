# Guide Complet de Déploiement de l'Application sur VPS (CentOS Stream)

Ce document récapitule toutes les étapes et commandes nécessaires pour déployer votre application Spring Boot backend en tant que conteneur Docker sur votre serveur VPS sous CentOS Stream, ainsi que la configuration de la base de données MySQL et du pare-feu.

---

## Prérequis

*   Accès SSH root à votre VPS (avec l'IP `109.176.197.158`).
*   Votre projet Spring Boot backend avec le `Dockerfile` mis à jour (sur GitHub).
*   Votre machine locale avec Git configuré pour pousser les modifications vers GitHub.

---

## Étapes de Déploiement sur le VPS

**Connectez-vous à votre VPS via SSH depuis votre machine locale :**

```bash
ssh root@109.176.197.158
```
*(Remplacez l'adresse IP si elle change. Vous serez invité à saisir votre mot de passe root.)*

---

### Étape 1 : Mettre à Jour le Système et Installer Git

*   Ceci met à jour tous les paquets du système et installe `git` pour récupérer votre code.

```bash
yum update -y
yum install -y git
```

---

### Étape 2 : Cloner le Projet et Basculer sur la Bonne Branche

*   Téléchargez votre dépôt GitHub et placez-vous sur la branche contenant le `Dockerfile` et les dernières modifications.

```bash
git clone https://github.com/StanleyDev11/Studio-Photo.git
cd Studio-Photo
git checkout feature/rebuild-backend10
```

---

### Étape 3 : Installer Docker sur le Serveur

*   Ces commandes ajoutent le dépôt officiel de Docker, puis installent Docker CE (Community Edition).

```bash
yum install -y yum-utils
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
yum install -y docker-ce docker-ce-cli containerd.io
```

---

### Étape 4 : Démarrer et Activer le Service Docker

*   Lance Docker et configure-le pour qu'il démarre automatiquement au redémarrage du serveur.

```bash
systemctl start docker
systemctl enable docker
```

---

### Étape 5 : Construire l'Image Docker de l'Application Backend

*   **Assurez-vous d'être dans le répertoire `photo_app_backend` avant d'exécuter la commande.**
*   Cette commande utilise le `Dockerfile` pour créer une image Docker de votre application.

```bash
cd photo_app_backend/
docker build -t photo-app-backend .
```

---

### Étape 6 : Lancer le Conteneur de la Base de Données MySQL

*   Ceci crée un conteneur séparé pour votre base de données MySQL.
*   **Très important :** Remplacez `VOTRE_MOT_DE_PASSE_POUR_LA_BD` par un mot de passe fort et **unique** de votre choix. Notez-le, vous en aurez besoin.

```bash
docker run -d -p 3306:3306 --name mysql-db -e MYSQL_ROOT_PASSWORD=VOTRE_MOT_DE_PASSE_POUR_LA_BD -e MYSQL_DATABASE=photo_db mysql:8.0
```

---

### Étape 7 : Lancer le Conteneur de l'Application Backend

*   Ceci démarre votre application et la connecte à la base de données MySQL.
*   **Important :** Utilisez le **même mot de passe** que vous avez défini à l'étape 6.
*   Notez que `SPRING_DATASOURCE_URL` utilise `db` comme nom d'hôte, car c'est le nom du conteneur MySQL tel qu'il est lié.

```bash
docker run -d -p 8080:8080 --name photo-app --link mysql-db:db -e SPRING_DATASOURCE_URL=jdbc:mysql://db:3306/photo_db -e SPRING_DATASOURCE_USERNAME=root -e SPRING_DATASOURCE_PASSWORD=VOTRE_MOT_DE_PASSE_POUR_LA_BD photo-app-backend
```

---

### Étape 8 : Configurer le Pare-feu pour Ouvrir le Port de l'Application

*   Installe `firewalld` (si ce n'est pas déjà fait), l'active, puis ouvre le port 8080 pour le trafic entrant.

```bash
dnf install firewalld -y           # Installe firewalld si manquant (utilise dnf car CentOS 10 Stream)
systemctl enable firewalld --now   # Active et démarre firewalld
firewall-cmd --zone=public --add-port=8080/tcp --permanent
firewall-cmd --reload
```

---

## Vérification du Déploiement

Après avoir exécuté toutes les étapes, vous pouvez vérifier le statut de votre application :

1.  **Vérifier que les conteneurs Docker sont en cours d'exécution :**
    ```bash
    docker ps
    ```
    Vous devriez voir `mysql-db` et `photo-app` listés avec le statut `Up`.

2.  **Consulter les logs de votre application backend (pour s'assurer qu'elle démarre sans erreur) :**
    ```bash
    docker logs photo-app
    ```

3.  **Accéder à l'application depuis votre navigateur web :**
    Ouvrez votre navigateur et naviguez vers :
    `http://109.176.197.158:8080`

    Vous devriez voir votre application Spring Boot fonctionner.

---
Ce guide complet devrait vous être utile pour vos futurs déploiements !
