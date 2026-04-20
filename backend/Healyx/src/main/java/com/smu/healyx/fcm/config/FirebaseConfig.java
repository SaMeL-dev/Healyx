package com.smu.healyx.fcm.config;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import com.google.firebase.messaging.FirebaseMessaging;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.io.Resource;

import java.io.IOException;

@Slf4j
@Configuration
public class FirebaseConfig {

    @Value("${api.firebase.key}")
    private Resource firebaseCredential;

    /** Firebase App을 초기화하고 FirebaseMessaging 빈을 반환합니다. */
    @Bean
    public FirebaseMessaging firebaseMessaging() throws IOException {
        if (!FirebaseApp.getApps().isEmpty()) {
            log.info("Firebase Admin SDK 이미 초기화됨");
            return FirebaseMessaging.getInstance();
        }

        FirebaseOptions options = FirebaseOptions.builder()
                .setCredentials(GoogleCredentials.fromStream(firebaseCredential.getInputStream()))
                .build();

        FirebaseApp app = FirebaseApp.initializeApp(options);
        log.info("Firebase Admin SDK 초기화 완료");
        return FirebaseMessaging.getInstance(app);
    }
}
