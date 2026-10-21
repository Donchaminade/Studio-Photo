package com.studiophoto.photoappbackend.storage;

import org.springframework.core.io.Resource;
import org.springframework.web.multipart.MultipartFile;

import java.nio.file.Path;
import java.util.stream.Stream;

public interface StorageService {

    void init(); // Initialise le système de stockage (crée le répertoire racine)

    String store(MultipartFile file); // Stocke un fichier et retourne son nom/chemin relatif

    Stream<Path> loadAll(); // Charge tous les chemins de fichiers stockés

    Path load(String filename); // Charge le chemin d'un fichier spécifique

    Resource loadAsResource(String filename); // Charge un fichier comme une ressource Spring

    void delete(String filename); // Supprime un fichier

    void deleteAll(); // Supprime tous les fichiers (dangereux en production)

    String getFileUrl(String filename); // Retourne l'URL publique du fichier
}
