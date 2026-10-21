package com.studiophoto.photoappbackend.order;

import org.springframework.transaction.annotation.Transactional;
import org.hibernate.Hibernate;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;
import java.math.BigDecimal;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ResponseBody;
import java.io.IOException;
import java.nio.charset.StandardCharsets;

import java.util.Optional;
import java.util.stream.Collectors;
import com.studiophoto.photoappbackend.order.OrderItem;
import java.util.Map;
import java.util.List;

@Controller
@RequestMapping("/admin/orders")
@RequiredArgsConstructor
@Slf4j
public class AdminOrderController {

    private final OrderService orderService;

    @GetMapping
    public String listOrders(Model model) {
        model.addAttribute("orders", orderService.findAll());
        return "admin/orders/list";
    }

    @GetMapping("/{id}")
    @Transactional(readOnly = true)
    public String viewOrderDetails(@PathVariable("id") Long id, Model model, RedirectAttributes redirectAttributes) {
        Optional<Order> orderOptional = orderService.findById(id);
        if (orderOptional.isPresent()) {
            Order order = orderOptional.get();
            Hibernate.initialize(order.getOrderItems()); // Initialize the collection
            model.addAttribute("order", order);

            // Pre-process the order items
            if (order.getOrderItems() != null && !order.getOrderItems().isEmpty()) {
                Map<String, List<OrderItem>> groupedItems = order.getOrderItems().stream()
                        .collect(Collectors.groupingBy(OrderItem::getPhotoSize));
                model.addAttribute("groupedItems", groupedItems);
            }

            return "admin/orders/detail";
        } else {
            redirectAttributes.addFlashAttribute("errorMessage", "Commande non trouvée.");
            return "redirect:/admin/orders";
        }
    }

    @GetMapping("/{id}/confirm")
    public String confirmOrder(@PathVariable("id") Long id, RedirectAttributes redirectAttributes) {
        try {
            orderService.updateOrderStatusAndPaymentMethod(id, OrderStatus.PROCESSING, null);
            redirectAttributes.addFlashAttribute("successMessage",
                    "Commande #" + id + " a été confirmée et est en cours de traitement.");
        } catch (IllegalArgumentException e) {
            redirectAttributes.addFlashAttribute("errorMessage", e.getMessage());
        }
        return "redirect:/admin/orders";
    }

    @GetMapping("/{id}/confirm-payment")
    public String confirmPayment(@PathVariable("id") Long id, RedirectAttributes redirectAttributes) {
        try {
            orderService.updateOrderStatusAndPaymentMethod(id, OrderStatus.PROCESSING, null);
            redirectAttributes.addFlashAttribute("successMessage",
                    "Paiement validé pour la commande #" + id + ".");
        } catch (IllegalArgumentException e) {
            redirectAttributes.addFlashAttribute("errorMessage", e.getMessage());
        }
        return "redirect:/admin/orders";
    }

    @GetMapping("/{id}/cancel")
    public String cancelOrder(@PathVariable("id") Long id, RedirectAttributes redirectAttributes) {
        try {
            orderService.updateOrderStatusAndPaymentMethod(id, OrderStatus.CANCELLED, null);
            redirectAttributes.addFlashAttribute("successMessage", "Commande #" + id + " a été annulée.");
        } catch (IllegalArgumentException e) {
            redirectAttributes.addFlashAttribute("errorMessage", e.getMessage());
        }
        return "redirect:/admin/orders";
    }

    @GetMapping("/{id}/complete")
    public String completeOrder(@PathVariable("id") Long id, RedirectAttributes redirectAttributes) {
        try {
            orderService.updateOrderStatusAndPaymentMethod(id, OrderStatus.COMPLETED, null);
            redirectAttributes.addFlashAttribute("successMessage",
                    "Commande #" + id + " a été marquée comme terminée.");
        } catch (IllegalArgumentException e) {
            redirectAttributes.addFlashAttribute("errorMessage", e.getMessage());
        }
        return "redirect:/admin/orders";
    }

    @PostMapping("/{id}/initiate-refund")
    public String initiateRefund(
            @PathVariable("id") Long id,
            @RequestParam(value = "refundAmount", required = false) BigDecimal refundAmount,
            @RequestParam(value = "refundReason", required = false) String refundReason,
            RedirectAttributes redirectAttributes) {
        try {
            orderService.initiateRefund(id, refundAmount, refundReason);
            redirectAttributes.addFlashAttribute("successMessage",
                    "Remboursement initié pour la commande #" + id
                            + ". Effectuez le transfert USSD puis confirmez avec la référence.");
        } catch (IllegalArgumentException | IllegalStateException e) {
            redirectAttributes.addFlashAttribute("errorMessage", e.getMessage());
        }
        return "redirect:/admin/orders/" + id;
    }

    @PostMapping("/{id}/confirm-refund")
    public String confirmRefund(
            @PathVariable("id") Long id,
            @RequestParam("refundReference") String refundReference,
            RedirectAttributes redirectAttributes) {
        try {
            orderService.confirmRefund(id, refundReference);
            redirectAttributes.addFlashAttribute("successMessage",
                    "Remboursement confirmé pour la commande #" + id + ".");
        } catch (IllegalArgumentException | IllegalStateException e) {
            redirectAttributes.addFlashAttribute("errorMessage", e.getMessage());
        }
        return "redirect:/admin/orders/" + id;
    }

    @GetMapping("/{id}/delete")
    public String deleteOrder(@PathVariable("id") Long id, RedirectAttributes redirectAttributes) {
        try {
            orderService.deleteById(id);
            redirectAttributes.addFlashAttribute("successMessage", "Commande #" + id + " supprimée avec succès.");
        } catch (Exception e) {
            redirectAttributes.addFlashAttribute("errorMessage", "Erreur lors de la suppression : " + e.getMessage());
        }
        return "redirect:/admin/orders";
    }

    @PostMapping("/bulk-delete")
    @ResponseBody
    public ResponseEntity<Void> bulkDelete(@RequestBody List<Long> ids) {
        orderService.deleteAllByIdIn(ids);
        return ResponseEntity.noContent().build();
    }

    @GetMapping("/{id}/download-photos")
    @ResponseBody
    public ResponseEntity<byte[]> downloadOrderPhotos(@PathVariable("id") Long id) {
        try {
            byte[] zipBytes = orderService.createOrderPhotosZipForAdmin(id);

            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_OCTET_STREAM);
            headers.setContentDispositionFormData("attachment", "order_" + id + "_photos.zip");
            headers.setContentLength(zipBytes.length);

            return new ResponseEntity<>(zipBytes, headers, HttpStatus.OK);

        } catch (IllegalArgumentException e) {
            log.warn("Download ZIP commande {}: {}", id, e.getMessage());
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .contentType(MediaType.TEXT_PLAIN)
                    .body(e.getMessage().getBytes(StandardCharsets.UTF_8));
        } catch (IOException e) {
            // Fichiers manquants / aucune photo accessible — pas un 500 brut
            log.warn("Download ZIP commande {} impossible: {}", id, e.getMessage());
            return ResponseEntity.status(HttpStatus.UNPROCESSABLE_ENTITY)
                    .contentType(MediaType.TEXT_PLAIN)
                    .body(e.getMessage().getBytes(StandardCharsets.UTF_8));
        } catch (Exception e) {
            log.error("Download ZIP commande {} echec inattendu", id, e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .contentType(MediaType.TEXT_PLAIN)
                    .body(("Erreur interne lors de la generation du ZIP: " + e.getMessage())
                            .getBytes(StandardCharsets.UTF_8));
        }
    }
}
