package com.studiophoto.photoappbackend.dimension;

import lombok.Builder;
import lombok.Data;

import java.math.BigDecimal;
import java.util.List;

@Data
@Builder
public class DimensionDto {
    private String dimension; // "name" from entity
    private BigDecimal price;
    private List<String> images;
    private String title;
    private String description;
    private boolean isPopular;
    private BigDecimal framePrice;
}
