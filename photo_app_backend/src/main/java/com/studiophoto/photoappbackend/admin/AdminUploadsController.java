package com.studiophoto.photoappbackend.admin;

import com.studiophoto.photoappbackend.model.User;
import com.studiophoto.photoappbackend.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;

import java.io.File;
import java.util.*;
import java.util.stream.Collectors;

@Controller
@RequestMapping("/admin/uploads")
@RequiredArgsConstructor
public class AdminUploadsController {

    private final UserRepository userRepository;
    private static final String UPLOADS_DIR = "uploads";

    @GetMapping
    public String listUserUploads(Model model) {
        Map<User, List<String>> userUploadsMap = new HashMap<>();
        File uploadsDir = new File(UPLOADS_DIR);
        if (!uploadsDir.exists() || !uploadsDir.isDirectory()) {
            model.addAttribute("error", "Le répertoire des téléversements n'existe pas.");
            return "admin/uploads/list";
        }

        File[] userDirs = uploadsDir.listFiles(File::isDirectory);
        if (userDirs != null) {
            for (File userDir : userDirs) {
                if (userDir.getName().startsWith("user_")) {
                    try {
                        Integer userId = Integer.parseInt(userDir.getName().substring(5));
                        Optional<User> userOpt = userRepository.findById(userId);

                        if (userOpt.isPresent()) {
                            File[] uploadSessionDirs = userDir.listFiles(File::isDirectory);
                            if (uploadSessionDirs != null) {
                                List<String> sessionIds = Arrays.stream(uploadSessionDirs)
                                        .map(File::getName)
                                        .collect(Collectors.toList());
                                userUploadsMap.put(userOpt.get(), sessionIds);
                            }
                        }
                    } catch (NumberFormatException e) {
                        // Ignore directories that don't have a valid user ID
                    }
                }
            }
        }

        model.addAttribute("userUploads", userUploadsMap);
        return "admin/uploads/list";
    }

    @GetMapping("/{userId}/{uploadId}")
    public String viewUploadSession(
            @PathVariable Integer userId,
            @PathVariable String uploadId,
            Model model) {

        List<String> imageUrls = new ArrayList<>();
        String dirPath = UPLOADS_DIR + "/user_" + userId + "/" + uploadId;
        File sessionDir = new File(dirPath);

        if (sessionDir.exists() && sessionDir.isDirectory()) {
            File[] imageFiles = sessionDir.listFiles();
            if (imageFiles != null) {
                for (File imageFile : imageFiles) {
                    if (imageFile.isFile()) {
                        // Assuming the base URL is the server root.
                        // In production, this should come from a config.
                        String fileUrl = "/uploads/user_" + userId + "/" + uploadId + "/" + imageFile.getName();
                        imageUrls.add(fileUrl);
                    }
                }
            }
        } else {
            model.addAttribute("error", "Le dossier de la session de téléversement est introuvable.");
        }

        model.addAttribute("imageUrls", imageUrls);
        model.addAttribute("userId", userId);
        model.addAttribute("uploadId", uploadId);
        return "admin/uploads/detail";
    }
}
