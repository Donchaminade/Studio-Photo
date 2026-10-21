# Politique de confidentialité — Picon

**Photo Picon** · Application mobile **Picon**  
Package Android : `com.photopicon.app`  
Services associés : [https://api.photopicon.com](https://api.photopicon.com)

*Dernière mise à jour : 30 juillet 2026*

La présente politique décrit comment **Photo Picon** (« nous », « le studio ») collecte, utilise, conserve et protège vos données personnelles lorsque vous utilisez l'application **Picon** sur Google Play et les services associés.

---

## 1. Responsable du traitement

**Studio Photo Picon**  
E-mail : [contact@photopicon.com](mailto:contact@photopicon.com)  
WhatsApp : [+228 98 52 62 26](https://wa.me/22898526226)

---

## 2. Données personnelles collectées

Lorsque vous créez un compte ou utilisez l'application, nous pouvons collecter et traiter :

| Catégorie | Données |
|-----------|---------|
| **Identité / compte** | Adresse e-mail, numéro de téléphone, nom (si fourni), mot de passe (stocké de façon sécurisée / hachée), code PIN de récupération (si utilisé) |
| **Photos** | Images que vous choisissez et téléversez pour une commande d'impression |
| **Commandes** | Produits (formats, cadres, dimensions), quantités, statut, historique de commandes |
| **Paiement** | Références de transaction Mobile Money / USSD, preuve de paiement éventuelle. **Nous ne stockons pas** vos codes secrets / PIN Mobile Money |
| **Technique** | Jetons d'authentification, journaux techniques limités nécessaires au fonctionnement et à la sécurité du service |

Nous ne collectons pas sciemment d'autres catégories de données sensibles non listées ici.

---

## 3. Autorisations Android et leur usage

L'application demande uniquement les autorisations nécessaires au service. Voici ce que nous utilisons et **pourquoi**, pour la revue Google Play :

### 3.1 Internet (`INTERNET`)

- Connexion au serveur `api.photopicon.com` pour l'authentification, les commandes, le téléversement des photos et le suivi des paiements.

### 3.2 Sélection de photos — **sans** accès galerie large

- Pour choisir une photo à imprimer, l'application utilise le **sélecteur de photos système Android** (photo picker / intent de sélection).
- L'utilisateur choisit **explicitement** la ou les images à envoyer.
- L'application **ne déclare pas** et **n'utilise pas** `READ_MEDIA_IMAGES`, `READ_MEDIA_VIDEO`, `READ_MEDIA_AUDIO`, `READ_EXTERNAL_STORAGE` ni `WRITE_EXTERNAL_STORAGE` pour accéder à toute la galerie.
- Aucune photo n'est lue en arrière-plan hors du flux de commande initié par l'utilisateur.

### 3.3 Téléphone / USSD (`CALL_PHONE`, `READ_PHONE_STATE`, `READ_PHONE_NUMBERS`)

Ces autorisations sont utilisées **uniquement** pour le paiement **Mobile Money via USSD** (composition du code USSD / appel vers le service de paiement) :

- **`CALL_PHONE`** : lancer l'appel / le code USSD de paiement demandé par l'utilisateur.
- **`READ_PHONE_STATE`** / **`READ_PHONE_NUMBERS`** : permettre le bon fonctionnement du flux d'appel USSD sur l'appareil (état de la ligne / numéro selon les besoins techniques Android), **pas** pour collecter ou revendre l'historique d'appels, ni pour un usage marketing.

Nous n'utilisons pas ces permissions pour appeler des numéros hors du flux de paiement Mobile Money / USSD initié dans l'app.

---

## 4. Usage des images (droits)

- Les photos téléversées servent **uniquement** à l'exécution de votre commande d'impression / prestation photo auprès du studio.
- Nous **ne vendons pas** vos images à des tiers.
- Nous **ne les utilisons pas** pour de la publicité, de l'entraînement d'IA, ni pour un catalogue public sans votre demande.
- Accès limité au personnel du studio et aux systèmes techniques nécessaires (hébergement) pour traiter la commande.
- Vous pouvez demander la suppression de vos photos (voir section 8).

---

## 5. Finalités du traitement

Vos données sont utilisées pour :

1. Créer et gérer votre compte (e-mail, téléphone, mot de passe / PIN).
2. Traiter, imprimer et livrer vos commandes photo.
3. Suivre et confirmer les paiements Mobile Money / USSD.
4. Vous contacter au sujet d'une commande ou d'une réservation (e-mail, téléphone, WhatsApp).
5. Assurer la sécurité, la prévention des abus et le bon fonctionnement de l'application.

Base : exécution du contrat / prestation demandée, et intérêt légitime de sécurité du service, dans le respect de la législation applicable.

---

## 6. Partage et vente de données

- Nous **ne vendons pas** vos données personnelles.
- Partage limité aux prestataires **strictement nécessaires** : hébergement serveur, opérateur Mobile Money / réseau télécom pour le paiement USSD.
- Vos photos sont destinées au **studio** pour l'exécution de la commande, pas à des partenaires marketing.
- Nous pouvons divulguer des données si la loi l'exige (autorité compétente).

---

## 7. Conservation

- **Compte et commandes** : tant que le compte est actif, puis durée nécessaire au suivi des commandes et aux obligations légales / comptables.
- **Photos** : durée nécessaire au traitement, à l'impression et à l'archivage raisonnable de la commande ; suppression sur demande lorsque techniquement et légalement possible.
- **Journaux techniques** : conservation limitée, à des fins de sécurité et de diagnostic.

---

## 8. Suppression de compte et de données

Pour supprimer votre compte et les données associées (y compris photos et commandes, dans la mesure techniquement et légalement possible) :

1. Écrivez à [contact@photopicon.com](mailto:contact@photopicon.com), **ou**
2. Contactez-nous sur WhatsApp : [+228 98 52 62 26](https://wa.me/22898526226)

Indiquez l'**adresse e-mail** utilisée dans l'application. Nous traitons la demande dans un délai raisonnable (**en général sous 30 jours**).

---

## 9. Vos droits

Selon la législation applicable, vous pouvez demander :

- l'accès à vos données ;
- la rectification ;
- l'effacement ;
- l'opposition à certains traitements ;

en nous contactant aux coordonnées de la section 1 / 8.

---

## 10. Sécurité

Mesures raisonnables : authentification, contrôle d'accès, communications **HTTPS**. Aucun système n'est totalement inviolable ; en cas d'incident, nous prendrons les mesures appropriées.

---

## 11. Enfants (13 ans et plus)

L'application **n'est pas destinée aux enfants de moins de 13 ans**. Nous ne collectons pas sciemment de données auprès de mineurs de moins de 13 ans sans autorisation parentale. Si vous pensez qu'un enfant nous a fourni des données, contactez-nous pour suppression.

---

## 12. Modifications

Cette politique peut être mise à jour. La version en vigueur est publiée sur ce document (Gist public) et, le cas échéant, sur [https://api.photopicon.com/privacy](https://api.photopicon.com/privacy).

---

## 13. Contact

Pour toute question relative à la confidentialité, aux autorisations Android ou à la suppression de compte :

- E-mail : [contact@photopicon.com](mailto:contact@photopicon.com)
- WhatsApp : [+228 98 52 62 26](https://wa.me/22898526226)

---

© Photo Picon — Application **Picon** (`com.photopicon.app`)