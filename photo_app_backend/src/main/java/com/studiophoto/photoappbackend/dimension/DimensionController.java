package com.studiophoto.photoappbackend.dimension;

import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/public/dimensions")
@RequiredArgsConstructor
public class DimensionController {

    private final DimensionService dimensionService;

    @GetMapping
    public ResponseEntity<List<DimensionDto>> getAllDimensions() {
        return ResponseEntity.ok(dimensionService.getAllDimensions());
    }
}
