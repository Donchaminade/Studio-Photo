package com.studiophoto.photoappbackend.frame;

import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/public/frames")
@RequiredArgsConstructor
public class PhotoFrameController {

    private final PhotoFrameService photoFrameService;

    @GetMapping
    public ResponseEntity<List<PhotoFrameDto>> getActiveFrames() {
        return ResponseEntity.ok(photoFrameService.getActiveFrames());
    }
}
