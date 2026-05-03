package com.smu.healyx.common.service;

import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import software.amazon.awssdk.core.sync.RequestBody;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.model.DeleteObjectRequest;
import software.amazon.awssdk.services.s3.model.PutObjectRequest;

import java.util.UUID;

@Service
@RequiredArgsConstructor
public class S3UploadService {

    private final S3Client s3Client;

    @Value("${cloud.aws.s3.bucket}")
    private String bucket;

    @Value("${spring.cloud.aws.region.static}")
    private String region;

    /**
     * 파일을 S3에 업로드하고 URL을 반환한다.
     * @param fileBytes   업로드할 파일의 바이트 배열
     * @param directory   S3 내 저장 경로 (예: "translations", "reviews")
     * @param contentType MIME 타입 (예: "image/jpeg")
     */
    public String upload(byte[] fileBytes, String directory, String contentType) {
        String key = directory + "/" + UUID.randomUUID() + toExtension(contentType);

        s3Client.putObject(
                PutObjectRequest.builder()
                        .bucket(bucket)
                        .key(key)
                        .contentType(contentType)
                        .build(),
                RequestBody.fromBytes(fileBytes)
        );

        return buildUrl(key);
    }

    /**
     * S3 URL로부터 파일을 삭제한다.
     */
    public void delete(String fileUrl) {
        String key = fileUrl.substring(fileUrl.indexOf(".amazonaws.com/") + ".amazonaws.com/".length());

        s3Client.deleteObject(
                DeleteObjectRequest.builder()
                        .bucket(bucket)
                        .key(key)
                        .build()
        );
    }

    private String buildUrl(String key) {
        return "https://" + bucket + ".s3." + region + ".amazonaws.com/" + key;
    }

    private String toExtension(String contentType) {
        return switch (contentType) {
            case "image/png"  -> ".png";
            case "image/gif"  -> ".gif";
            case "image/webp" -> ".webp";
            default           -> ".jpg";
        };
    }
}
