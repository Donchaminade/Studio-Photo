package com.studiophoto.photoappbackend.repository;

import com.studiophoto.photoappbackend.model.UserActivity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface UserActivityRepository extends JpaRepository<UserActivity, Long> {
    List<UserActivity> findAllByOrderByTimestampDesc();
}
