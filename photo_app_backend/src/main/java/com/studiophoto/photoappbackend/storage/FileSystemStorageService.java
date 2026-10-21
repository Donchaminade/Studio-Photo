package com.studiophoto.photoappbackend.storage;

import org.springframework.core.io.Resource;
import org.springframework.core.io.UrlResource;
import org.springframework.stereotype.Service;
import org.springframework.util.FileSystemUtils;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.io.InputStream;
import java.net.MalformedURLException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.util.Objects;
import java.util.UUID;
import java.util.stream.Stream;

@Service
public class FileSystemStorageService implements StorageService {

    private final Path rootLocation;

    public FileSystemStorageService(StorageProperties properties) {
        this.rootLocation = Paths.get(properties.getLocation());
    }

    @Override
    public void init() {
        try {
            Files.createDirectories(rootLocation);
        } catch (IOException e) {
            throw new StorageException("Impossible d'initialiser le stockage des fichiers", e);
        }
    }

    @Override
    public String store(MultipartFile file) {
        String filename = UUID.randomUUID() + "-"
                + Objects.requireNonNull(file.getOriginalFilename()).replaceAll("\\s+", "_");
        try {
            if (file.isEmpty()) {
                throw new StorageException("Impossible de stocker un fichier vide : " + filename);
            }
            // Sécurité: Vérifier que le chemin du fichier est dans le répertoire de
            // stockage
            Path destinationFile = this.rootLocation.resolve(Paths.get(filename)).normalize().toAbsolutePath();
            if (!destinationFile.getParent().equals(this.rootLocation.toAbsolutePath())) {
                // This is a security check
                throw new StorageException("Sécurité : tentative de stockage en dehors du répertoire autorisé.");
            }
            try (InputStream inputStream = file.getInputStream()) {
                Files.copy(inputStream, destinationFile, StandardCopyOption.REPLACE_EXISTING);
            }
        } catch (IOException e) {
            throw new StorageException("Échec du stockage du fichier " + filename, e);
        }
        return filename; // Retourne juste le nom du fichier
    }

    @Override
    public Stream<Path> loadAll() {
        try {
            return Files.walk(this.rootLocation, 1)
                    .filter(path -> !path.equals(this.rootLocation))
                    .map(this.rootLocation::relativize);
        } catch (IOException e) {
            throw new StorageException("Échec de la lecture des fichiers stockés", e);
        }
    }

    @Override
    public Path load(String filename) {
        return rootLocation.resolve(filename);
    }

    @Override
    public Resource loadAsResource(String filename) {
        try {
            Path file = load(filename);
            Resource resource = new UrlResource(file.toUri());
            if (resource.exists() || resource.isReadable()) {
                return resource;
            } else {
                throw new StorageFileNotFoundException("Fichier introuvable ou illisible : " + filename);
            }
        } catch (MalformedURLException e) {
            throw new StorageFileNotFoundException("Fichier introuvable ou illisible : " + filename, e);
        }
    }

    @Override
    public void delete(String filename) {
        Path file = load(filename);
        try {
            Files.deleteIfExists(file);
        } catch (IOException e) {
            throw new StorageException("Échec de la suppression du fichier " + filename, e);
        }
    }

    @Override
    public void deleteAll() {
        FileSystemUtils.deleteRecursively(rootLocation.toFile());
    }

    @Override
    public String getFileUrl(String filename) {
        // Pour un environnement de production, l'URL pourrait être différente (ex: CDN)
        // Ici, on suppose que les fichiers sont servis via un endpoint Spring MVC
        // "/uploads/**"
        // Le contrôleur devra mapper "/uploads/" à ce répertoire rootLocation
        return "/uploads/" + filename;
    }
}
