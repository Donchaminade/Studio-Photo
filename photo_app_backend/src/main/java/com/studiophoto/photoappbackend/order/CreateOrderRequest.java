package com.studiophoto.photoappbackend.order;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.Data;

import java.util.ArrayList;
import java.util.List;

@Data
public class CreateOrderRequest {
    @JsonProperty("isExpress")
    private boolean isExpress;
    private String paymentMethod;
    private String deliveryAddress; // Added delivery address field
    private List<CreateOrderItemRequest> items = new ArrayList<>();
}
