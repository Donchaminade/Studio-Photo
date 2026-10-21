package com.studiophoto.photoappbackend.repository;

import com.studiophoto.photoappbackend.model.User;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.LocalDateTime;
import java.util.Collection;
import java.util.List;
import java.util.Optional;

public interface UserRepository extends JpaRepository<User, Integer> {

    Optional<User> findByEmail(String email);

    Optional<User> findByPhone(String phone);

    boolean existsByEmail(String email);

    boolean existsByPhone(String phone);

    Optional<User> findFirstByPhoneIn(Collection<String> phones);

    long countByCreatedAtBetween(LocalDateTime start, LocalDateTime end);

    List<User> findTop5ByOrderByCreatedAtDesc();

    List<User> findByCreatedAtBetweenOrderByCreatedAtDesc(LocalDateTime start, LocalDateTime end);
}
