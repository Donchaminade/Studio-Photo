package com.studiophoto.photoappbackend.notification;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

public interface UserNotificationRepository extends JpaRepository<UserNotification, Long> {

    List<UserNotification> findByUserIdOrderByCreatedAtDesc(Integer userId);

    long countByUserIdAndReadFalse(Integer userId);

    Optional<UserNotification> findByIdAndUserId(Long id, Integer userId);

    @Modifying(clearAutomatically = true)
    @Query("DELETE FROM UserNotification n WHERE n.user.id = :userId")
    int deleteByUserId(@Param("userId") Integer userId);

    @Modifying
    @Query("DELETE FROM UserNotification n WHERE n.user.id = :userId AND n.read = true AND n.readAt IS NOT NULL AND n.readAt < :cutoff")
    int deleteReadOlderThan(@Param("userId") Integer userId, @Param("cutoff") LocalDateTime cutoff);

    @Modifying
    @Query("DELETE FROM UserNotification n WHERE n.read = true AND n.readAt IS NOT NULL AND n.readAt < :cutoff")
    int deleteAllReadOlderThan(@Param("cutoff") LocalDateTime cutoff);
}
