package com.studiophoto.photoappbackend;

import com.studiophoto.photoappbackend.storage.StorageProperties;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.scheduling.annotation.EnableScheduling;

@SpringBootApplication
@EnableConfigurationProperties(StorageProperties.class)
@EnableScheduling
public class PhotoAppBackendApplication {

	public static void main(String[] args) {
		SpringApplication.run(PhotoAppBackendApplication.class, args);
	}

}
