package com.studiophoto.photoappbackend.frame;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface PhotoFrameRepository extends JpaRepository<PhotoFrame, Long> {

    List<PhotoFrame> findAllByActiveTrueOrderBySortOrderAscNameAsc();
}
