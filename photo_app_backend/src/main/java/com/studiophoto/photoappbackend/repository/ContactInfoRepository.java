package com.studiophoto.photoappbackend.repository;

import com.studiophoto.photoappbackend.model.ContactInfo;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.Optional;

public interface ContactInfoRepository extends JpaRepository<ContactInfo, Long> {
    Optional<ContactInfo> findTopByOrderByIdAsc();
}
