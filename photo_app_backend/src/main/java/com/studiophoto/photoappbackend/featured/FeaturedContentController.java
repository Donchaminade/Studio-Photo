package com.studiophoto.photoappbackend.featured;

import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/featured-content")
@RequiredArgsConstructor
public class FeaturedContentController {

    private final FeaturedContentService featuredContentService;

    @GetMapping("/active")
    public ResponseEntity<FeaturedContent> getActiveFeaturedContent() {
        return featuredContentService.getActiveFeaturedContent()
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    // Endpoints CRUD pour l'administration
    @GetMapping
    public ResponseEntity<List<FeaturedContent>> getAllFeaturedContent() {
        return ResponseEntity.ok(featuredContentService.getAllFeaturedContent());
    }

    @GetMapping("/{id}")
    public ResponseEntity<FeaturedContent> getFeaturedContentById(@PathVariable Long id) {
        return featuredContentService.getFeaturedContentById(id)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @PostMapping
    public ResponseEntity<FeaturedContent> createFeaturedContent(@RequestBody FeaturedContent featuredContent) {
        return ResponseEntity.ok(featuredContentService.saveFeaturedContent(featuredContent));
    }

    @PutMapping("/{id}")
    public ResponseEntity<FeaturedContent> updateFeaturedContent(@PathVariable Long id, @RequestBody FeaturedContent featuredContent) {
        return featuredContentService.getFeaturedContentById(id)
                .map(existingContent -> {
                    featuredContent.setId(id); // Ensure ID is set for update
                    return ResponseEntity.ok(featuredContentService.saveFeaturedContent(featuredContent));
                })
                .orElse(ResponseEntity.notFound().build());
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteFeaturedContent(@PathVariable Long id) {
        featuredContentService.deleteFeaturedContent(id);
        return ResponseEntity.noContent().build();
    }
}
