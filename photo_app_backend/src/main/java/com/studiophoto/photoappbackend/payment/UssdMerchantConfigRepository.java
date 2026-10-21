package com.studiophoto.photoappbackend.payment;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface UssdMerchantConfigRepository extends JpaRepository<UssdMerchantConfig, Long> {
    Optional<UssdMerchantConfig> findTopByOrderByIdAsc();
}
