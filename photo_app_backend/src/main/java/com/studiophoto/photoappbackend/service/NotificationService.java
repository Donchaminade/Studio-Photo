package com.studiophoto.photoappbackend.service;

import lombok.RequiredArgsConstructor;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Service;

import java.util.Map;

@Service
@RequiredArgsConstructor
public class NotificationService {

    private final SimpMessagingTemplate messagingTemplate;

    public void sendSyncNotification(String type) {
        messagingTemplate.convertAndSend("/topic/sync", Map.of("type", type));
    }
}
