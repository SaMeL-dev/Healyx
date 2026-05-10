package com.smu.healyx.translation.service;

import com.smu.healyx.common.exception.AuthException;
import com.smu.healyx.common.service.S3UploadService;
import com.smu.healyx.deepl.service.TranslationService;
import org.springframework.http.HttpStatus;
import com.smu.healyx.ocr.service.VisionService;
import com.smu.healyx.translation.domain.MedicalTranslation;
import com.smu.healyx.translation.dto.MedicalTranslationRequest;
import com.smu.healyx.translation.dto.MedicalTranslationResponse;
import com.smu.healyx.translation.dto.TextBlock;
import com.smu.healyx.translation.dto.TranslationArchiveItem;
import com.smu.healyx.translation.repository.MedicalTranslationRepository;
import com.smu.healyx.user.domain.User;
import com.smu.healyx.user.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Base64;
import java.util.List;
import java.util.stream.IntStream;

@Slf4j
@Service
@RequiredArgsConstructor
public class MedicalTranslationService {

    private final VisionService visionService;
    private final TranslationService translationService;
    private final ImageOverlayService imageOverlayService;
    private final S3UploadService s3UploadService;
    private final MedicalTranslationRepository medicalTranslationRepository;
    private final UserRepository userRepository;

    @Transactional
    public MedicalTranslationResponse translate(MedicalTranslationRequest request, Long userId) {
        // 1. DOCUMENT_TEXT_DETECTION — 텍스트 블록 + 좌표 추출
        List<TextBlock> blocks = visionService.extractTextBlocks(request.getImageBase64());

        // 2. DeepL 일괄 번역 (1회 API 호출)
        List<String> originalTexts = blocks.stream().map(TextBlock::getOriginalText).toList();
        List<String> translatedTexts = translationService.translateBatch(originalTexts, request.getTargetLanguage());

        List<TextBlock> translatedBlocks = IntStream.range(0, blocks.size())
                .mapToObj(i -> TextBlock.builder()
                        .originalText(blocks.get(i).getOriginalText())
                        .translatedText(translatedTexts.get(i))
                        .x(blocks.get(i).getX()).y(blocks.get(i).getY())
                        .width(blocks.get(i).getWidth()).height(blocks.get(i).getHeight())
                        .build())
                .toList();

        // 3. 오버레이 이미지 생성
        byte[] imageBytes = Base64.getDecoder().decode(request.getImageBase64());
        byte[] overlayBytes = generateOverlay(imageBytes, translatedBlocks);

        String fullOriginal = String.join("\n", originalTexts);
        String fullTranslated = String.join("\n", translatedTexts);

        // 게스트: S3/DB 저장 없이 Base64로 반환
        if (userId == null) {
            return MedicalTranslationResponse.forGuest(fullOriginal, fullTranslated, overlayBytes);
        }

        // 로그인 사용자: S3 업로드 + DB 저장
        String imageUrl = null;
        String translatedImageUrl = null;
        try {
            imageUrl = s3UploadService.upload(imageBytes, "translations", "image/jpeg");
            translatedImageUrl = s3UploadService.upload(overlayBytes, "translations/overlay", "image/png");
        } catch (Exception e) {
            // S3 업로드 실패 시 텍스트만 저장 (graceful degradation)
            log.warn("S3 업로드 실패, 텍스트만 저장합니다: {}", e.getMessage());
        }

        User user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("사용자를 찾을 수 없습니다."));

        MedicalTranslation saved = medicalTranslationRepository.save(
                MedicalTranslation.builder()
                        .user(user)
                        .originalText(fullOriginal)
                        .translatedText(fullTranslated)
                        .targetLanguage(request.getTargetLanguage())
                        .imageUrl(imageUrl)
                        .translatedImageUrl(translatedImageUrl)
                        .build()
        );

        return MedicalTranslationResponse.fromEntity(saved);
    }

    /** 번역 보관함 항목 개별 조회 — 본인 소유 확인 */
    @Transactional(readOnly = true)
    public TranslationArchiveItem getArchiveItem(Long userId, Long translationId) {
        MedicalTranslation translation = medicalTranslationRepository.findById(translationId)
                .orElseThrow(() -> new AuthException("TRANSLATION_NOT_FOUND",
                        "번역 항목을 찾을 수 없습니다.", HttpStatus.NOT_FOUND));

        if (translation.getUser() == null || !translation.getUser().getUserId().equals(userId)) {
            throw new AuthException("ACCESS_DENIED",
                    "해당 번역 항목에 접근할 권한이 없습니다.", HttpStatus.FORBIDDEN);
        }

        return TranslationArchiveItem.from(translation);
    }

    /** 번역 보관함 항목 삭제 — 본인 소유 확인 후 S3 이미지 및 DB 레코드 삭제 */
    @Transactional
    public void deleteArchiveItem(Long userId, Long translationId) {
        MedicalTranslation translation = medicalTranslationRepository.findById(translationId)
                .orElseThrow(() -> new AuthException("TRANSLATION_NOT_FOUND",
                        "번역 항목을 찾을 수 없습니다.", HttpStatus.NOT_FOUND));

        if (translation.getUser() == null || !translation.getUser().getUserId().equals(userId)) {
            throw new AuthException("ACCESS_DENIED",
                    "해당 번역 항목을 삭제할 권한이 없습니다.", HttpStatus.FORBIDDEN);
        }

        // S3 이미지 삭제 (실패해도 DB 삭제는 진행)
        deleteS3ImageQuietly(translation.getImageUrl());
        deleteS3ImageQuietly(translation.getTranslatedImageUrl());

        medicalTranslationRepository.delete(translation);
    }

    private void deleteS3ImageQuietly(String imageUrl) {
        if (imageUrl == null) return;
        try {
            s3UploadService.delete(imageUrl);
        } catch (Exception e) {
            log.warn("S3 이미지 삭제 실패 (무시하고 계속 진행): url={}, error={}", imageUrl, e.getMessage());
        }
    }

    /** 번역 보관함 조회 — 최신순 */
    @Transactional(readOnly = true)
    public List<TranslationArchiveItem> getArchive(Long userId) {
        return medicalTranslationRepository
                .findByUser_UserIdOrderByCreatedAtDesc(userId)
                .stream()
                .map(TranslationArchiveItem::from)
                .toList();
    }

    private byte[] generateOverlay(byte[] imageBytes, List<TextBlock> blocks) {
        try {
            return imageOverlayService.overlay(imageBytes, blocks);
        } catch (Exception e) {
            // 오버레이 실패 시 원본 이미지 그대로 반환
            log.warn("오버레이 이미지 생성 실패, 원본 이미지를 사용합니다: {}", e.getMessage());
            return imageBytes;
        }
    }
}
