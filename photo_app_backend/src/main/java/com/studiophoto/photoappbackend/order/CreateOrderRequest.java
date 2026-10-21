package com.studiophoto.photoappbackend.order;

import com.fasterxml.jackson.annotation.JsonAlias;
import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.Getter;
import lombok.Setter;

import java.util.ArrayList;
import java.util.List;

public class CreateOrderRequest {
    /**
     * Champ {@code express} (pas {@code isExpress}) pour que Jackson lise
     * le JSON Flutter {@code isExpress}. Sinon le forfait Xpress 1500 FCFA
     * n'était pas persisté et l'admin affichait un total trop bas.
     */
    private boolean express;

    @Getter
    @Setter
    private String paymentMethod;

    @Getter
    @Setter
    private String deliveryAddress;

    @Getter
    @Setter
    private List<CreateOrderItemRequest> items = new ArrayList<>();

    @JsonProperty("isExpress")
    @JsonAlias({"express"})
    public boolean isExpress() {
        return express;
    }

    @JsonProperty("isExpress")
    public void setExpress(boolean express) {
        this.express = express;
    }
}
