package com.studiophoto.photoappbackend.notification;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

@Component
@RequiredArgsConstructor
@Slf4j
public class NotificationCleanupScheduler {

    private final UserNotificationService notificationService;

    /** Supprime les notifications lues depuis plus de 3 jours. */
    @Scheduled(cron = "0 0 3 * * *")
    public void purgeExpiredReadNotifications() {
        notificationService.purgeAllExpiredRead();
        log.debug("Purge des notifications lues expirées effectuée.");
    }
}
