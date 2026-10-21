package com.studiophoto.photoappbackend.admin.dto;

import lombok.Builder;
import lombok.Data;
import java.util.List;

@Data
@Builder
public class PhotoFormatChartDTO {
    private List<String> labels;
    private List<Long> data;
    private List<String> backgroundColors;
}
