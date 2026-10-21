# 🚀 Guide de Déploiement - Studio Photo Backend (Docker Compose)
**Serveur :** CentOS Stream | **IP :** `109.176.197.158`

Ce guide détaille la procédure pour déployer l'application Spring Boot sur votre VPS en utilisant Docker Compose.

---

## 🛠 Phase 1 : Préparation du Serveur (À faire une seule fois)

Connectez-vous à votre VPS :
```bash
ssh root@109.176.197.158
```

### 1.1 Mise à jour et installation de Docker Compose
```bash
yum update -y
yum install -y git yum-utils
# Docker (si pas déjà fait)
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
yum install -y docker-ce docker-ce-cli containerd.io
systemctl enable --now docker
```

---

## 🏗 Phase 2 : Premier Déploiement

### 2.1 Récupération du code
```bash
git clone https://github.com/StanleyDev11/Studio-Photo.git
cd Studio-Photo
git checkout feature/docker-compose-setup
cd photo_app_backend/
```

### 2.2 Configuration des variables d'environnement
Créez votre propre fichier `.env` sur le serveur :
```bash
cp .env.example .env
vi .env  # Modifiez les mots de passe et les secrets si nécessaire
```

### 2.3 Lancement global
Docker Compose va construire l'image backend, lancer MySQL avec persistance, et configurer le réseau.
```bash
docker compose up -d --build
```

---

## 🔄 Phase 3 : Mise à jour de l'application (Routine)

Dès que vous poussez des modifications sur GitHub, suivez ces étapes pour mettre à jour le serveur :

1. **Récupérer le nouveau code :**
   ```bash
   cd ~/Studio-Photo
   git pull origin feature/docker-compose-setup
   ```

2. **Mettre à jour les conteneurs :**
   ```bash
   cd photo_app_backend/
   docker compose up -d --build
   ```
   *Docker recréera uniquement le conteneur backend sans toucher à vos données MySQL.*

---

## 🛡 Phase 4 : Sécurité (Firewall)

Ouvrez le port 8080 pour permettre l'accès à l'API :
```bash
dnf install firewalld -y
systemctl enable --now firewalld
firewall-cmd --zone=public --add-port=8080/tcp --permanent
firewall-cmd --reload
```

---

## 🔍 Diagnostic et Maintenance

| Action | Commande |
| :--- | :--- |
| **Voir les logs de l'App** | `docker compose logs -f backend` |
| **Voir les logs de la DB** | `docker compose logs -f db` |
| **Statut des conteneurs** | `docker compose ps` |
| **Arrêter tout** | `docker compose down` |
| **Espace disque Docker** | `docker system df` |

---

⚠️ **Note sur la Persistance :**
- Les photos envoyées sont stockées sur le VPS dans : `photo_app_backend/uploads/`
- La base de données est stockée dans un volume Docker nommé : `mysql_data`
