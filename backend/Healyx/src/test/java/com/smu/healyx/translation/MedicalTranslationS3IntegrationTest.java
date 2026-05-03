package com.smu.healyx.translation;

import com.smu.healyx.common.service.S3UploadService;
import com.smu.healyx.deepl.service.TranslationService;
import com.smu.healyx.ocr.service.VisionService;
import com.smu.healyx.translation.domain.MedicalTranslation;
import com.smu.healyx.translation.dto.MedicalTranslationRequest;
import com.smu.healyx.translation.dto.MedicalTranslationResponse;
import com.smu.healyx.translation.dto.TextBlock;
import com.smu.healyx.translation.repository.MedicalTranslationRepository;
import com.smu.healyx.translation.service.ImageOverlayService;
import com.smu.healyx.translation.service.MedicalTranslationService;
import com.smu.healyx.user.domain.User;
import com.smu.healyx.user.repository.UserRepository;
import org.junit.jupiter.api.*;
import org.junit.jupiter.api.parallel.Execution;
import org.junit.jupiter.api.parallel.ExecutionMode;
import org.mockito.ArgumentCaptor;
import org.springframework.test.util.ReflectionTestUtils;
import software.amazon.awssdk.auth.credentials.AwsBasicCredentials;
import software.amazon.awssdk.auth.credentials.StaticCredentialsProvider;
import software.amazon.awssdk.regions.Region;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.model.HeadObjectRequest;
import software.amazon.awssdk.services.s3.model.NoSuchKeyException;

import java.io.InputStream;
import java.util.ArrayList;
import java.util.Base64;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.junit.jupiter.api.Assumptions.assumeTrue;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

/**
 * 의료 번역 S3 저장 통합 테스트
 *
 * 실제 AWS S3에 원본 이미지와 번역 오버레이 이미지가 정상 저장되는지 검증합니다.
 * Vision API / DeepL API / DB(JPA)는 Mockito로 대체하여 S3 저장 로직만 집중 검증합니다.
 *
 * 실행 전 환경변수 설정 (IntelliJ Run Configuration 또는 터미널):
 *   AWS_ACCESS_KEY_ID     = IAM 액세스 키
 *   AWS_SECRET_ACCESS_KEY = IAM 시크릿 키
 *   AWS_S3_BUCKET         = S3 버킷명 (예: healyx-bucket)
 *   AWS_REGION            = 리전 (기본값: ap-northeast-2)
 *
 * 테스트 종료 후 업로드된 임시 파일은 @AfterEach에서 자동 삭제됩니다.
 */
@Execution(ExecutionMode.SAME_THREAD)
@TestMethodOrder(MethodOrderer.OrderAnnotation.class)
class MedicalTranslationS3IntegrationTest {

    private static final String ACCESS_KEY = System.getenv("AWS_ACCESS_KEY_ID");
    private static final String SECRET_KEY = System.getenv("AWS_SECRET_ACCESS_KEY");
    private static final String BUCKET     = System.getenv("AWS_S3_BUCKET");
    private static final String REGION     = Optional.ofNullable(System.getenv("AWS_REGION"))
                                                     .orElse("ap-northeast-2");

    private static final String TEST_IMAGE = "/medical-image.png";

    private S3Client        s3Client;
    private S3UploadService s3UploadService;

    /** 테스트 중 업로드된 URL — @AfterEach에서 S3 삭제 처리 */
    private final List<String> uploadedUrls = new ArrayList<>();

    /** true면 @AfterEach 삭제를 건너뜁니다 — S3 콘솔에서 직접 확인할 때 사용 */
    private static final boolean SKIP_CLEANUP =
            "true".equalsIgnoreCase(System.getenv("S3_SKIP_CLEANUP"));

    @BeforeEach
    void setUp() {
        assumeTrue(ACCESS_KEY != null && !ACCESS_KEY.isBlank(),
                "AWS_ACCESS_KEY_ID 미설정 — S3 통합 테스트를 건너뜁니다.");
        assumeTrue(SECRET_KEY != null && !SECRET_KEY.isBlank(),
                "AWS_SECRET_ACCESS_KEY 미설정 — S3 통합 테스트를 건너뜁니다.");
        assumeTrue(BUCKET != null && !BUCKET.isBlank(),
                "AWS_S3_BUCKET 미설정 — S3 통합 테스트를 건너뜁니다.");

        s3Client = S3Client.builder()
                .region(Region.of(REGION))
                .credentialsProvider(StaticCredentialsProvider.create(
                        AwsBasicCredentials.create(ACCESS_KEY, SECRET_KEY)))
                .build();

        s3UploadService = new S3UploadService(s3Client);
        ReflectionTestUtils.setField(s3UploadService, "bucket", BUCKET);
        ReflectionTestUtils.setField(s3UploadService, "region", REGION);
    }

    @AfterEach
    void tearDown() {
        if (SKIP_CLEANUP) {
            System.out.println("[정리 건너뜀] S3_SKIP_CLEANUP=true — S3 콘솔에서 아래 파일을 직접 확인하세요:");
            uploadedUrls.forEach(url -> System.out.println("  " + url));
            return;
        }
        uploadedUrls.forEach(url -> {
            try {
                s3UploadService.delete(url);
                System.out.println("[정리] 삭제 완료: " + url);
            } catch (Exception e) {
                System.err.println("[정리] 삭제 실패: " + url + " — " + e.getMessage());
            }
        });
        uploadedUrls.clear();
    }

    // ── Test 1: 원본 이미지 직접 업로드 ───────────────────────────────────────

    @Test
    @Order(1)
    @DisplayName("[S3] 원본 이미지 업로드 — URL 형식 및 S3 객체 존재 확인")
    void 원본_이미지_업로드() {
        byte[] imageBytes = loadTestImage(TEST_IMAGE);

        String url = s3UploadService.upload(imageBytes, "translations", "image/jpeg");
        uploadedUrls.add(url);

        System.out.println("[원본 이미지] S3 URL: " + url);

        assertThat(url)
                .startsWith("https://" + BUCKET + ".s3." + REGION + ".amazonaws.com/translations/")
                .endsWith(".jpg");

        assertObjectExists(url);
    }

    // ── Test 2: 오버레이 이미지 직접 업로드 ───────────────────────────────────

    @Test
    @Order(2)
    @DisplayName("[S3] 오버레이(번역) 이미지 업로드 — URL 형식 및 S3 객체 존재 확인")
    void 오버레이_이미지_업로드() throws Exception {
        byte[] imageBytes = loadTestImage(TEST_IMAGE);
        // ImageOverlayService로 실제 PNG 오버레이 이미지 생성 (블록 없이 원본 그대로 PNG 변환)
        byte[] overlayBytes = new ImageOverlayService().overlay(imageBytes, List.of());

        String url = s3UploadService.upload(overlayBytes, "translations/overlay", "image/png");
        uploadedUrls.add(url);

        System.out.println("[오버레이 이미지] S3 URL: " + url);

        assertThat(url)
                .startsWith("https://" + BUCKET + ".s3." + REGION + ".amazonaws.com/translations/overlay/")
                .endsWith(".png");

        assertObjectExists(url);
    }

    // ── Test 3: MedicalTranslationService 전체 파이프라인 S3 저장 검증 ────────

    @Test
    @Order(3)
    @DisplayName("[S3] MedicalTranslationService — 원본·오버레이 이미지 URL 모두 S3에 저장됨")
    void 서비스_전체파이프라인_S3저장() throws Exception {
        byte[] imageBytes = loadTestImage(TEST_IMAGE);
        String imageBase64 = Base64.getEncoder().encodeToString(imageBytes);

        // Vision / DeepL / DB 의존성 Mocking
        VisionService visionService             = mock(VisionService.class);
        TranslationService translationService   = mock(TranslationService.class);
        UserRepository userRepository           = mock(UserRepository.class);
        MedicalTranslationRepository repository = mock(MedicalTranslationRepository.class);

        // Vision API: 바운딩박스 1개 반환
        when(visionService.extractTextBlocks(anyString())).thenReturn(List.of(
                TextBlock.builder()
                        .originalText("복용법: 하루 3회 식후 복용")
                        .x(10).y(10).width(200).height(30)
                        .build()
        ));

        // DeepL API: 번역 결과 반환
        when(translationService.translateBatch(anyList(), eq("en")))
                .thenReturn(List.of("Dosage: Take 3 times a day after meals"));

        // DB: 테스트용 사용자 + save() 호출 시 전달받은 엔티티 그대로 반환
        User mockUser = mock(User.class);
        when(userRepository.findById(1L)).thenReturn(Optional.of(mockUser));

        ArgumentCaptor<MedicalTranslation> captor = ArgumentCaptor.forClass(MedicalTranslation.class);
        when(repository.save(captor.capture())).thenAnswer(inv -> inv.getArgument(0));

        // 실제 S3UploadService를 사용하는 MedicalTranslationService 구성
        MedicalTranslationService service = new MedicalTranslationService(
                visionService, translationService,
                new ImageOverlayService(),
                s3UploadService, repository, userRepository
        );

        MedicalTranslationRequest request = new MedicalTranslationRequest();
        ReflectionTestUtils.setField(request, "imageBase64", imageBase64);
        ReflectionTestUtils.setField(request, "targetLanguage", "en");

        MedicalTranslationResponse response = service.translate(request, 1L);

        // 저장된 엔티티의 URL 추출 + 테스트 후 삭제 등록
        MedicalTranslation savedEntity = captor.getValue();
        if (savedEntity.getImageUrl() != null)           uploadedUrls.add(savedEntity.getImageUrl());
        if (savedEntity.getTranslatedImageUrl() != null) uploadedUrls.add(savedEntity.getTranslatedImageUrl());

        System.out.println("[원본 이미지 URL]    " + savedEntity.getImageUrl());
        System.out.println("[오버레이 이미지 URL] " + savedEntity.getTranslatedImageUrl());

        // URL 형식 검증
        assertThat(savedEntity.getImageUrl())
                .as("원본 이미지 URL이 S3에 저장되어야 합니다.")
                .isNotNull()
                .startsWith("https://" + BUCKET + ".s3." + REGION + ".amazonaws.com/translations/");

        assertThat(savedEntity.getTranslatedImageUrl())
                .as("오버레이 이미지 URL이 S3에 저장되어야 합니다.")
                .isNotNull()
                .startsWith("https://" + BUCKET + ".s3." + REGION + ".amazonaws.com/translations/overlay/");

        // S3 객체 실제 존재 검증
        assertObjectExists(savedEntity.getImageUrl());
        assertObjectExists(savedEntity.getTranslatedImageUrl());

        // 텍스트도 엔티티에 저장됐는지 확인
        assertThat(savedEntity.getOriginalText()).contains("복용법");
        assertThat(savedEntity.getTranslatedText()).contains("Dosage");
    }

    // ── Test 4: S3 업로드 실패 시 텍스트만 저장 (graceful degradation) ─────────

    @Test
    @Order(4)
    @DisplayName("[S3] 업로드 실패 시 — 예외 없이 완료되고 텍스트는 저장, 이미지 URL은 null")
    void S3_업로드_실패시_graceful_degradation() {
        // 존재하지 않는 버킷으로 S3 업로드 실패를 유도합니다.
        S3UploadService brokenS3 = new S3UploadService(s3Client);
        ReflectionTestUtils.setField(brokenS3, "bucket", "healyx-nonexistent-bucket-xyz-000");
        ReflectionTestUtils.setField(brokenS3, "region", REGION);

        byte[] imageBytes = loadTestImage(TEST_IMAGE);
        String imageBase64 = Base64.getEncoder().encodeToString(imageBytes);

        VisionService visionService             = mock(VisionService.class);
        TranslationService translationService   = mock(TranslationService.class);
        UserRepository userRepository           = mock(UserRepository.class);
        MedicalTranslationRepository repository = mock(MedicalTranslationRepository.class);

        when(visionService.extractTextBlocks(anyString())).thenReturn(List.of(
                TextBlock.builder().originalText("복용법").x(0).y(0).width(100).height(20).build()
        ));
        when(translationService.translateBatch(anyList(), eq("en"))).thenReturn(List.of("Dosage"));

        User mockUser = mock(User.class);
        when(userRepository.findById(1L)).thenReturn(Optional.of(mockUser));

        ArgumentCaptor<MedicalTranslation> captor = ArgumentCaptor.forClass(MedicalTranslation.class);
        when(repository.save(captor.capture())).thenAnswer(inv -> inv.getArgument(0));

        MedicalTranslationService service = new MedicalTranslationService(
                visionService, translationService,
                new ImageOverlayService(),
                brokenS3, repository, userRepository
        );

        MedicalTranslationRequest request = new MedicalTranslationRequest();
        ReflectionTestUtils.setField(request, "imageBase64", imageBase64);
        ReflectionTestUtils.setField(request, "targetLanguage", "en");

        // S3 업로드 실패해도 예외 없이 완료되어야 합니다.
        MedicalTranslationResponse response = service.translate(request, 1L);

        MedicalTranslation savedEntity = captor.getValue();
        System.out.println("[원본 텍스트] " + savedEntity.getOriginalText());
        System.out.println("[번역 텍스트] " + savedEntity.getTranslatedText());
        System.out.println("[이미지 URL]  " + savedEntity.getImageUrl() + " (null이어야 함)");

        // 텍스트는 저장되고 이미지 URL은 null이어야 합니다.
        assertThat(savedEntity.getOriginalText()).isNotBlank();
        assertThat(savedEntity.getTranslatedText()).isNotBlank();
        assertThat(savedEntity.getImageUrl()).isNull();
        assertThat(savedEntity.getTranslatedImageUrl()).isNull();
    }

    // ── 헬퍼 ──────────────────────────────────────────────────────────────────

    /** S3 HeadObject로 객체의 실제 존재 여부를 확인합니다. */
    private void assertObjectExists(String url) {
        String key = url.substring(url.indexOf(".amazonaws.com/") + ".amazonaws.com/".length());
        try {
            s3Client.headObject(HeadObjectRequest.builder().bucket(BUCKET).key(key).build());
            System.out.println("[S3 확인] 객체 존재 확인: " + url);
        } catch (NoSuchKeyException e) {
            throw new AssertionError("S3에 객체가 존재하지 않습니다: " + url, e);
        }
    }

    private byte[] loadTestImage(String resourcePath) {
        try (InputStream is = getClass().getResourceAsStream(resourcePath)) {
            assumeTrue(is != null, resourcePath + " 파일이 없습니다. src/test/resources/ 에 추가하세요.");
            return is.readAllBytes();
        } catch (Exception e) {
            assumeTrue(false, "테스트 이미지 로드 실패: " + e.getMessage());
            return null;
        }
    }
}
