package com.studiophoto.photoappbackend.admin.dto;

import lombok.Builder;
import lombok.Data;

import java.util.List;

@Data
@Builder
public class ChartDataDTO {
    private List<String> labels;
    private List<Long> newUsers;
    private List<Long> uploadedPhotos;
}
