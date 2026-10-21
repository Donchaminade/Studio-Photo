package com.studiophoto.photoappbackend.featured;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface FeaturedContentRepository extends JpaRepository<FeaturedContent, Long> {
    List<FeaturedContent> findByActiveTrueOrderByPriorityAsc();
    Optional<FeaturedContent> findFirstByActiveTrueOrderByPriorityAsc(); // Pour récupérer le premier
}
