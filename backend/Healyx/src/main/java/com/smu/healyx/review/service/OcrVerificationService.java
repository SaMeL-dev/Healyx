package com.smu.healyx.review.service;

import com.smu.healyx.common.exception.AuthException;
import com.smu.healyx.common.service.S3UploadService;
import com.smu.healyx.hospital.domain.Hospital;
import com.smu.healyx.hospital.repository.HospitalRepository;
import com.smu.healyx.ocr.service.VisionService;
import com.smu.healyx.review.dto.OcrVerifyRequest;
import com.smu.healyx.review.dto.OcrVerifyResponse;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.Base64;
import java.util.Optional;
import java.util.concurrent.TimeUnit;

@Slf4j
@Service
@RequiredArgsConstructor
public class OcrVerificationService {

    private final HospitalRepository hospitalRepository;
    private final S3UploadService s3UploadService;
    private final VisionService visionService;
    private final StringRedisTemplate redisTemplate;

    private static final long OCR_TOKEN_TTL_SECONDS = 600L; // 10분
    private static final String OCR_KEY_PREFIX = "ocr:";

    // ════════════════════════════════════════════════════════════════
    // 외부 명세 메소드 (프로그램 목록 v1.0 기준)
    // ════════════════════════════════════════════════════════════════

    /**
     * HX_R_004: 영수증 OCR 추출 및 병원 DB 대조
     *
     * <p>프로그램 목록(v1.0) 명세 메소드명을 컨트롤러 진입점으로 노출하기 위한 위임 메소드.
     * 내부 구현은 verify() 그대로 유지하여 단위 테스트 영향 없음.
     */
    public OcrVerifyResponse verifyVisitByReceipt(Long userId, OcrVerifyRequest request) throws IOException {
        return verify(userId, request);
    }

    // ════════════════════════════════════════════════════════════════
    // 내부 구현
    // ════════════════════════════════════════════════════════════════

    /**
     * 영수증 OCR 인증을 수행한다.
     *
     * 1. 영수증 이미지 S3 업로드
     * 2. Google Vision OCR 호출 → 전체 텍스트 추출
     * 3. ykiho → hospitals.name 조회
     * 4. 정규화된 텍스트 contains 비교
     * 5. 일치 시 Redis에 인증 상태 저장 (TTL 10분)
     */
    public OcrVerifyResponse verify(Long userId, OcrVerifyRequest request) throws IOException {

        // 1. hospitals 테이블에서 ykiho로 병원명 확보
        Hospital hospital = hospitalRepository.findByYkiho(request.getYkiho())
                .orElseThrow(() -> new AuthException(
                        "HOSPITAL_NOT_FOUND",
                        "병원 정보를 찾을 수 없습니다.",
                        HttpStatus.NOT_FOUND));

        // 2. 영수증 이미지 S3 업로드
        MultipartFile file = request.getReceiptImage();
        String receiptImageUrl = s3UploadService.upload(
                file.getBytes(),
                "receipts",
                Optional.ofNullable(file.getContentType()).orElse("image/jpeg")
        );

        // 3. Vision OCR — Base64 변환 후 전체 텍스트 추출
        String imageBase64 = Base64.getEncoder().encodeToString(file.getBytes());
        String ocrText = visionService.extractText(imageBase64);
        // extractText() 내부에서 텍스트 미감지 시 ExternalApiException(VISION_NO_TEXT) 발생
        // → GlobalExceptionHandler가 503 응답 처리하지만,
        //   설계서 기준 422로 내려야 하므로 catch 후 재가공
        // (위 ExternalApiException은 visionService 내부에서 이미 throw됨 — 호출부에서 캐치)

        // 4. 병원명 정규화 비교
        String normalizedOcr      = normalize(ocrText);
        String normalizedHospital = normalize(hospital.getName());

        if (!normalizedOcr.contains(normalizedHospital)
                && !normalizedHospital.contains(normalizedOcr)) {
            log.warn("OCR 병원명 불일치: hospitalName={}, ocrText(앞100자)={}",
                    hospital.getName(), ocrText.substring(0, Math.min(100, ocrText.length())));
            throw new AuthException(
                    "RECEIPT_MISMATCH",
                    "선택한 병원과 영수증 정보가 다릅니다",
                    HttpStatus.BAD_REQUEST);
        }

        // 5. Redis에 인증 상태 저장 (value: receiptImageUrl)
        String redisKey = buildOcrKey(userId, request.getYkiho());
        redisTemplate.opsForValue().set(redisKey, receiptImageUrl, OCR_TOKEN_TTL_SECONDS, TimeUnit.SECONDS);
        log.debug("OCR 인증 완료: userId={}, ykiho={}", userId, request.getYkiho());

        return new OcrVerifyResponse(receiptImageUrl);
    }

    /**
     * OCR 인증 상태를 Redis에서 조회한다.
     *
     * @return receiptImageUrl — 없으면 null
     */
    public String getReceiptImageUrl(Long userId, String ykiho) {
        return redisTemplate.opsForValue().get(buildOcrKey(userId, ykiho));
    }

    /**
     * OCR 인증 상태를 Redis에서 삭제한다 (1회성 소비).
     */
    public void consumeOcrToken(Long userId, String ykiho) {
        redisTemplate.delete(buildOcrKey(userId, ykiho));
    }

    // ── 내부 유틸 ────────────────────────────────────────────────────

    /**
     * 병원명 정규화: 공백·특수문자 제거 후 소문자 변환.
     * 한글·영문·숫자만 유지하여 표기 방식 차이를 흡수.
     */
    private String normalize(String text) {
        return text.replaceAll("[^\\p{L}\\d]", "").toLowerCase();
    }

    private String buildOcrKey(Long userId, String ykiho) {
        return OCR_KEY_PREFIX + userId + ":" + ykiho;
    }
}
