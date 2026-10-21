# Corriger l'erreur 413 (upload images admin)

## Alternative sans accès Ubuntu (depuis le code)
Le backend compresse automatiquement les images admin > 1 Mo avant envoi
(dimensions, cadres, promotions, contenu vedette).
**Redéployez le JAR** après mise à jour du backend.

## Cause
Nginx Ubuntu (`api.photopicon.com`) limite par défaut les requêtes à **1 Mo**.
Votre image (~2,6 Mo) est bloquée **avant** d'atteindre le backend Windows.

## Correction rapide (sur le VPS Ubuntu)

```bash
sudo nano /etc/nginx/sites-available/api.photopicon.com
```

Dans le bloc `server { listen 443 ... }`, ajoutez **en haut** (avant `location /`) :

```nginx
client_max_body_size 200M;
client_body_timeout 300s;
```

Dans `location /`, ajoutez si absent :

```nginx
proxy_send_timeout 300s;
proxy_read_timeout 300s;
proxy_request_buffering off;
```

Puis :

```bash
sudo nginx -t
sudo systemctl reload nginx
```

## Fichier complet de référence

Voir `nginx-api.photopicon.com.conf` dans ce dossier.

## Vérification

Réessayez l'upload sur :
`https://api.photopicon.com/admin/dimensions`

Image test : 2,6 Mo → doit passer.

## Si 413 persiste

Vérifiez aussi un éventuel `client_max_body_size` dans `/etc/nginx/nginx.conf` (bloc `http`).

```bash
grep -r client_max_body_size /etc/nginx/
```

La valeur la plus restrictive gagne. Mettez `200M` au niveau `http` ou `server`.
