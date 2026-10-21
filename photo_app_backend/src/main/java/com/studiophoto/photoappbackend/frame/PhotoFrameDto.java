package com.studiophoto.photoappbackend.frame;

import lombok.Builder;
import lombok.Data;

import java.util.List;

@Data
@Builder
public class PhotoFrameDto {
    private Long id;
    private String name;
    private List<String> images;
    private String description;
    private int sortOrder;
}
