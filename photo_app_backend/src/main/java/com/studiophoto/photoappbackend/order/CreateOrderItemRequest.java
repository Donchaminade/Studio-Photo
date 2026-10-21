package com.studiophoto.photoappbackend.order;

import lombok.Data;

@Data
public class CreateOrderItemRequest {
    private String imageUrl;
    private String size; // "10x15 cm"
    private int quantity;
    private Boolean withFrame;
    private Long frameId;
    /** Conseil studio (texte libre, calculé côté app). */
    private String studioPrintAdvice;
    private String suggestedPhotoSize;
    private String chosenPrintQuality;
    private String suggestedPrintQuality;
}
