package com.studiophoto.photoappbackend.booking;

import com.studiophoto.photoappbackend.model.User;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Repository
public interface BookingRepository extends JpaRepository<Booking, Long>, JpaSpecificationExecutor<Booking> {

    @EntityGraph(attributePaths = { "user" })
    List<Booking> findByUser(User user);

    @EntityGraph(attributePaths = { "user" })
    List<Booking> findByStatus(BookingStatus status);

    List<Booking> findByStartTimeBetween(LocalDateTime start, LocalDateTime end);

    List<Booking> findByUserAndStatus(User user, BookingStatus status);

    long countByStatus(BookingStatus status);

    long countByStartTimeBetween(LocalDateTime start, LocalDateTime end);
}
