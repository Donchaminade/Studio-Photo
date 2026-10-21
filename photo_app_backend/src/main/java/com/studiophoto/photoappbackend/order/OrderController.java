package com.studiophoto.photoappbackend.order;

import com.studiophoto.photoappbackend.model.User;
import com.studiophoto.photoappbackend.notification.UserNotificationService;
import com.studiophoto.photoappbackend.payment.UssdCodeService;
import com.studiophoto.photoappbackend.storage.StorageService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/orders")
@RequiredArgsConstructor
public class OrderController {

    private final OrderService orderService;
    private final StorageService storageService;
    private final UserNotificationService userNotificationService;
    private final UssdCodeService ussdCodeService;

    @PostMapping
    public ResponseEntity<?> createOrder(
            @RequestBody CreateOrderRequest request,
            @AuthenticationPrincipal User currentUser) {
        if (currentUser == null) {
            return ResponseEntity.status(401).build(); // Non autorisé
        }
        try {
            Order newOrder = orderService.createOrder(request, currentUser);
            return ResponseEntity.ok(newOrder);
        } catch (IllegalStateException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }

    @GetMapping("/my-orders")
    public ResponseEntity<List<OrderResponseDTO>> getMyOrders(@AuthenticationPrincipal User currentUser) {
        if (currentUser == null) {
            return ResponseEntity.status(401).build();
        }
        List<OrderResponseDTO> orders = orderService.findOrdersByUser(currentUser.getId())
                .stream()
                .map(OrderResponseDTO::from)
                .collect(java.util.stream.Collectors.toList());
        return ResponseEntity.ok(orders);
    }

    @GetMapping("/{id}")
    public ResponseEntity<OrderResponseDTO> getOrderById(
            @PathVariable Long id,
            @AuthenticationPrincipal User currentUser) {
        if (currentUser == null) {
            return ResponseEntity.status(401).build();
        }
        return orderService.findById(id)
                .filter(order -> order.getUser().getId().equals(currentUser.getId()))
                .map(order -> ResponseEntity.ok(OrderResponseDTO.from(order)))
                .orElse(ResponseEntity.notFound().build());
    }

    /**
     * Renvoie le code USSD marchand calculé pour une commande.
     *
     * Sécurité : endpoint authentifié + commande nécessairement détenue par
     * l'utilisateur. Les codes marchands restent côté serveur ; seul le code
     * final lié à cette commande (montant authoritatif serveur) est renvoyé.
     */
    @GetMapping("/{id}/ussd-code")
    public ResponseEntity<?> getOrderUssdCode(
            @PathVariable Long id,
            @AuthenticationPrincipal User currentUser) {
        if (currentUser == null) {
            return ResponseEntity.status(401).build();
        }
        return orderService.findById(id)
                .filter(order -> order.getUser().getId().equals(currentUser.getId()))
                .<ResponseEntity<?>>map(order -> ResponseEntity.ok(
                        Collections.singletonMap("ussdCode", ussdCodeService.resolveForOrder(order))))
                .orElse(ResponseEntity.notFound().build());
    }

    @PostMapping("/upload")
    public ResponseEntity<?> uploadPhotos(
            @RequestParam("files") List<MultipartFile> files,
            @RequestParam("userId") Long userId) {

        if (files.isEmpty()) {
            return ResponseEntity.badRequest().body("Please select files to upload.");
        }

        List<String> fileUrls = new ArrayList<>();
        String uploadId = UUID.randomUUID().toString();

        try {
            for (MultipartFile file : files) {
                if (file.isEmpty()) {
                    continue;
                }

                String originalFilename = file.getOriginalFilename();
                if (originalFilename == null) {
                    originalFilename = "unnamed-file";
                }

                // Clean the filename to prevent directory traversal issues
                String sanitizedFilename = Paths.get(originalFilename).getFileName().toString();

                // Stocker dans le dossier configuré (storage.location) / user_X / uploadId
                Path userDirectory = storageService.load("user_" + userId + "/" + uploadId);
                Files.createDirectories(userDirectory);

                Path destinationFile = userDirectory.resolve(sanitizedFilename).normalize().toAbsolutePath();

                // Double check to prevent saving files outside the intended directory
                if (!destinationFile.getParent().equals(userDirectory.toAbsolutePath())) {
                    return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                            .body("Cannot store file outside the designated directory.");
                }

                file.transferTo(destinationFile);

                // L'URL relative sera préfixée par le frontend avec le bon domaine
                String fileUrl = "/uploads/user_" + userId + "/" + uploadId + "/" + sanitizedFilename;
                fileUrls.add(fileUrl);
            }

            return ResponseEntity.ok(Collections.singletonMap("urls", fileUrls));

        } catch (IOException e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body("Failed to upload files.");
        }
    }

    @GetMapping("/{orderId}/download-photos")
    public ResponseEntity<byte[]> downloadOrderPhotos(
            @PathVariable Long orderId,
            @AuthenticationPrincipal User currentUser) {
        if (currentUser == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
        }
        try {
            byte[] zipBytes = orderService.createOrderPhotosZip(orderId, currentUser);

            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_OCTET_STREAM);
            headers.setContentDispositionFormData("attachment", "order_" + orderId + "_photos.zip");
            headers.setContentLength(zipBytes.length);

            return new ResponseEntity<>(zipBytes, headers, HttpStatus.OK);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).build(); // Order not found or not owned by user
        } catch (IOException e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(null); // Error during zip creation
        }
    }

    @PostMapping("/{id}/cancel")
    public ResponseEntity<?> cancelOrder(
            @PathVariable Long id,
            @AuthenticationPrincipal User currentUser) {
        if (currentUser == null) {
            return ResponseEntity.status(401).build();
        }
        try {
            orderService.cancelOrder(id, currentUser);
            return ResponseEntity.ok().build();
        } catch (IllegalStateException e) {
            userNotificationService.notifyCancellationRefused(currentUser, id, e.getMessage());
            return ResponseEntity.badRequest().body(e.getMessage());
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body("Une erreur est survenue lors de l'annulation.");
        }
    }

    @DeleteMapping("/{id}/pending-payment")
    public ResponseEntity<?> deletePendingPaymentOrder(
            @PathVariable Long id,
            @AuthenticationPrincipal User currentUser) {
        if (currentUser == null) {
            return ResponseEntity.status(401).build();
        }
        try {
            orderService.deletePendingPaymentOrderByCustomer(id, currentUser);
            return ResponseEntity.noContent().build();
        } catch (IllegalArgumentException e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(e.getMessage());
        } catch (IllegalStateException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body("Une erreur est survenue lors de la suppression.");
        }
    }

    @PostMapping("/{id}/payment/confirm")
    public ResponseEntity<?> confirmPaymentFromCustomer(
            @PathVariable Long id,
            @RequestBody(required = false) Map<String, String> payload,
            @AuthenticationPrincipal User currentUser) {
        if (currentUser == null) {
            return ResponseEntity.status(401).build();
        }
        try {
            String paymentReference = payload != null ? payload.get("paymentReference") : null;
            String paymentProofType = payload != null ? payload.get("paymentProofType") : null;
            String paymentProofText = payload != null ? payload.get("paymentProofText") : null;
            String paymentProofImageUrl = payload != null ? payload.get("paymentProofImageUrl") : null;
            Order order = orderService.markPaymentReportedByCustomer(
                    id,
                    currentUser,
                    paymentReference,
                    paymentProofType,
                    paymentProofText,
                    paymentProofImageUrl);
            return ResponseEntity.ok(OrderResponseDTO.from(order));
        } catch (IllegalStateException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        } catch (IllegalArgumentException e) {
            return ResponseEntity.notFound().build();
        }
    }

    @PostMapping("/{id}/payment-proof/upload")
    public ResponseEntity<?> uploadPaymentProof(
            @PathVariable Long id,
            @RequestParam("file") MultipartFile file,
            @AuthenticationPrincipal User currentUser) {
        if (currentUser == null) {
            return ResponseEntity.status(401).build();
        }
        if (file == null || file.isEmpty()) {
            return ResponseEntity.badRequest().body("Fichier de preuve requis.");
        }
        try {
            Order order = orderService.findById(id)
                    .orElseThrow(() -> new IllegalArgumentException("Commande non trouvée."));
            if (!order.getUser().getId().equals(currentUser.getId())) {
                return ResponseEntity.status(403).body("Accès interdit.");
            }

            String originalFilename = file.getOriginalFilename();
            if (originalFilename == null || originalFilename.isBlank()) {
                originalFilename = "proof-image.jpg";
            }
            String sanitizedFilename = Paths.get(originalFilename).getFileName().toString();
            String uploadId = UUID.randomUUID().toString();

            Path proofDirectory = storageService.load("payment-proofs/user_" + currentUser.getId() + "/" + uploadId);
            Files.createDirectories(proofDirectory);
            Path destinationFile = proofDirectory.resolve(sanitizedFilename).normalize().toAbsolutePath();

            if (!destinationFile.getParent().equals(proofDirectory.toAbsolutePath())) {
                return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                        .body("Chemin de fichier invalide.");
            }

            file.transferTo(destinationFile);
            String fileUrl = "/uploads/payment-proofs/user_" + currentUser.getId() + "/" + uploadId + "/" + sanitizedFilename;
            return ResponseEntity.ok(Collections.singletonMap("url", fileUrl));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        } catch (IOException e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body("Impossible d'uploader la preuve de paiement.");
        }
    }
}
