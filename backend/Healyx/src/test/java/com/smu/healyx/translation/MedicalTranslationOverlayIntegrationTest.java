package com.smu.healyx.translation;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.smu.healyx.common.exception.ExternalApiException;
import com.smu.healyx.deepl.service.TranslationService;
import com.smu.healyx.ocr.service.VisionService;
import com.smu.healyx.translation.dto.TextBlock;
import com.smu.healyx.translation.service.ImageOverlayService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.parallel.Execution;
import org.junit.jupiter.api.parallel.ExecutionMode;
import org.springframework.test.util.ReflectionTestUtils;
import org.springframework.web.client.RestTemplate;

import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.Base64;
import java.util.List;
import java.util.stream.IntStream;

import static org.assertj.core.api.Assertions.assertThat;
import static org.junit.jupiter.api.Assumptions.assumeTrue;

/**
 * 약봉투 번역 오버레이 통합 테스트
 *
 * 목적: 한국어로 적힌 약봉투 이미지를 사용자 선호 언어로 번역하여
 *       원본 위치에 오버레이하는 전체 파이프라인을 검증합니다.
 *       (Vision OCR → DeepL 번역 → ImageOverlayService 렌더링)
 *
 * 테스트 이미지:
 *   medical-image.png  — 한국어 의료 문서(약봉투) 샘플 (메인 테스트)
 *   medical-image2.png — 일본어 메뉴 샘플 (오버레이 렌더링 추가 확인용)
 *
 * 실행 전 환경변수 설정 필요 (IntelliJ Run Configuration 또는 터미널):
 *   VISION_API_KEY = application-local.properties의 api.vision.key 값
 *   DEEPL_API_KEY  = application-local.properties의 api.deepl.key 값
 *
 * 결과 이미지: build/test-overlay-{lang}.jpg (테스트 실행 후 육안 확인)
 *
 * @Execution(SAME_THREAD): 외부 API(Vision, DeepL)에 동시 요청이 몰리지 않도록
 *   테스트를 순차 실행합니다. 병렬 실행 시 Connection reset / Network unreachable 발생.
 */
@Execution(ExecutionMode.SAME_THREAD)
class MedicalTranslationOverlayIntegrationTest {

    private VisionService visionService;
    private TranslationService translationService;
    private ImageOverlayService imageOverlayService;

    private static final String VISION_KEY = System.getenv("VISION_API_KEY");
    private static final String DEEPL_KEY  = System.getenv("DEEPL_API_KEY");

    // 한국어 약봉투 샘플 이미지
    private static final String MEDICINE_BAG_IMAGE = "/medical-image.png";

    @BeforeEach
    void setUp() {
        assumeTrue(VISION_KEY != null && !VISION_KEY.isBlank(),
                "VISION_API_KEY 환경변수가 설정되지 않아 테스트를 건너뜁니다.");
        assumeTrue(DEEPL_KEY != null && !DEEPL_KEY.isBlank(),
                "DEEPL_API_KEY 환경변수가 설정되지 않아 테스트를 건너뜁니다.");

        RestTemplate restTemplate = new RestTemplate();
        ObjectMapper objectMapper = new ObjectMapper();

        visionService = new VisionService(restTemplate, objectMapper);
        ReflectionTestUtils.setField(visionService, "visionApiKey", VISION_KEY);

        translationService = new TranslationService(restTemplate, objectMapper);
        ReflectionTestUtils.setField(translationService, "deeplApiKey", DEEPL_KEY);

        imageOverlayService = new ImageOverlayService();
    }

    // ── 한국어 약봉투 → 지원 언어 5종 ─────────────────────────────────────────

    @Test
    @DisplayName("[실제 API] 약봉투(한국어) → 영어 번역 오버레이")
    void 약봉투_영어_번역_오버레이() throws Exception {
        runOverlayTest(MEDICINE_BAG_IMAGE, "en", "build/test-overlay-en.png");
    }

    @Test
    @DisplayName("[실제 API] 약봉투(한국어) → 중국어 번역 오버레이")
    void 약봉투_중국어_번역_오버레이() throws Exception {
        runOverlayTest(MEDICINE_BAG_IMAGE, "zh", "build/test-overlay-zh.png");
    }

    @Test
    @DisplayName("[실제 API] 약봉투(한국어) → 베트남어 번역 오버레이")
    void 약봉투_베트남어_번역_오버레이() throws Exception {
        runOverlayTest(MEDICINE_BAG_IMAGE, "vi", "build/test-overlay-vi.png");
    }

    @Test
    @DisplayName("[실제 API] 약봉투(한국어) → 태국어 번역 오버레이")
    void 약봉투_태국어_번역_오버레이() throws Exception {
        runOverlayTest(MEDICINE_BAG_IMAGE, "th", "build/test-overlay-th.png");
    }

    @Test
    @DisplayName("[실제 API] 약봉투(한국어) → 일본어 번역 오버레이")
    void 약봉투_일본어_번역_오버레이() throws Exception {
        runOverlayTest(MEDICINE_BAG_IMAGE, "ja", "build/test-overlay-ja.png");
    }

    // ── 공통 실행 로직 ─────────────────────────────────────────────────────────

    private void runOverlayTest(String resourcePath, String targetLang, String outputRelPath) throws Exception {
        byte[] imageBytes = loadTestImage(resourcePath);
        String imageBase64 = Base64.getEncoder().encodeToString(imageBytes);

        // Step 1: Vision DOCUMENT_TEXT_DETECTION — 텍스트 블록 + 바운딩박스 추출
        List<TextBlock> blocks;
        try {
            blocks = visionService.extractTextBlocks(imageBase64);
        } catch (ExternalApiException e) {
            assumeTrue(false, "Vision API 일시 불가 — 테스트를 건너뜁니다: " + e.getMessage());
            return;
        }
        System.out.println("\n[Step 1] Vision OCR 결과 ─ 추출 블록: " + blocks.size() + "개");
        blocks.forEach(b -> System.out.printf("  원문: %-20s | (x=%3d, y=%3d, w=%3d, h=%3d)%n",
                b.getOriginalText(), b.getX(), b.getY(), b.getWidth(), b.getHeight()));
        assertThat(blocks).isNotEmpty();

        // Step 2: DeepL 일괄 번역 (source 자동 감지)
        List<String> originals = blocks.stream().map(TextBlock::getOriginalText).toList();
        List<String> translated;
        try {
            translated = translationService.translateBatch(originals, targetLang);
        } catch (ExternalApiException e) {
            assumeTrue(false, "DeepL API 일시 불가 — 테스트를 건너뜁니다: " + e.getMessage());
            return;
        }
        System.out.println("\n[Step 2] DeepL 번역 결과 (→ " + targetLang + ")");
        IntStream.range(0, originals.size())
                .forEach(i -> System.out.printf("  [%s] → [%s]%n", originals.get(i), translated.get(i)));
        assertThat(translated).hasSameSizeAs(originals);
        translated.forEach(t -> assertThat(t).isNotBlank());

        // Step 3: 번역 텍스트를 원래 바운딩박스 위치에 주입
        List<TextBlock> translatedBlocks = IntStream.range(0, blocks.size())
                .mapToObj(i -> TextBlock.builder()
                        .originalText(blocks.get(i).getOriginalText())
                        .translatedText(translated.get(i))
                        .x(blocks.get(i).getX()).y(blocks.get(i).getY())
                        .width(blocks.get(i).getWidth()).height(blocks.get(i).getHeight())
                        .build())
                .toList();

        // Step 4: 오버레이 이미지 생성
        byte[] overlayBytes = imageOverlayService.overlay(imageBytes, translatedBlocks);
        assertThat(overlayBytes).isNotEmpty();
        assertThat(overlayBytes.length).isGreaterThan(1000);

        // Step 5: 결과 이미지 저장 (육안 확인용)
        Path outputPath = Paths.get(outputRelPath);
        Files.createDirectories(outputPath.getParent());
        Files.write(outputPath, overlayBytes);

        System.out.println("\n[Step 4] 오버레이 이미지 생성 완료");
        System.out.printf("  원본 크기: %,d bytes%n", imageBytes.length);
        System.out.printf("  결과 크기: %,d bytes%n", overlayBytes.length);
        System.out.println("\n★ 결과 이미지 경로: " + outputPath.toAbsolutePath());
        System.out.println("  IntelliJ에서 해당 파일을 열어 오버레이 결과를 확인하세요.");
    }

    private byte[] loadTestImage(String resourcePath) {
        try (InputStream is = getClass().getResourceAsStream(resourcePath)) {
            assumeTrue(is != null, resourcePath + " 파일을 찾을 수 없습니다. src/test/resources/ 에 추가하세요.");
            return is.readAllBytes();
        } catch (Exception e) {
            assumeTrue(false, "테스트 이미지 로드 실패: " + e.getMessage());
            return null;
        }
    }
}
