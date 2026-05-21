package com.smu.healyx.common.service;

import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import software.amazon.awssdk.core.sync.RequestBody;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.model.DeleteObjectRequest;
import software.amazon.awssdk.services.s3.model.GetObjectRequest;
import software.amazon.awssdk.services.s3.model.PutObjectRequest;
import software.amazon.awssdk.services.s3.presigner.S3Presigner;
import software.amazon.awssdk.services.s3.presigner.model.GetObjectPresignRequest;

import java.time.Duration;
import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class S3UploadService {

    public static final Duration DEFAULT_PRESIGN_TTL = Duration.ofHours(1);

    private final S3Client s3Client;
    private final S3Presigner s3Presigner;

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

    /**
     * DB에 저장된 전체 URL을 Presigned GET URL로 변환한다.
     * prefix 미매칭/null/blank면 원본 URL을 그대로 반환한다.
     */
    public String presignGetUrl(String storedUrl) {
        if (storedUrl == null || storedUrl.isBlank()) return storedUrl;
        String prefix = "https://" + bucket + ".s3." + region + ".amazonaws.com/";
        if (!storedUrl.startsWith(prefix)) return storedUrl;
        String key = storedUrl.substring(prefix.length());

        var getReq = GetObjectRequest.builder().bucket(bucket).key(key).build();
        var presignReq = GetObjectPresignRequest.builder()
                .signatureDuration(DEFAULT_PRESIGN_TTL)
                .getObjectRequest(getReq)
                .build();
        return s3Presigner.presignGetObject(presignReq).url().toString();
    }

    /**
     * URL 목록을 일괄 Presigned GET URL로 변환한다.
     */
    public List<String> presignAll(List<String> storedUrls) {
        return storedUrls.stream().map(this::presignGetUrl).toList();
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
