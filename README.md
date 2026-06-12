# Healyx 외국인을 위한 AI 기반 병원 추천 및 의료비 예측 플랫폼

<img width="1804" height="1016" alt="image" src="https://github.com/user-attachments/assets/f6346b76-fcad-4007-bc87-55757d7b40ac" />

## 프로젝트 소개
- Healyx는 한국에 거주하거나 방문하는 외국인이 언어 장벽과 의료비 불확실성으로 인해 적절한 의료 서비스에 어려움을 겪는 문제를 해결하기 위한 애플리케이션입니다.
- 증상을 음성 또는 텍스트로 입력하면 AI가 분석하여 주변의 적합한 병원을 추천해줍니다.
- 사용자의 나이, 성별, 지역, 보험 가입 여부를 기반으로 예상 의료비 범위를 제공합니다.
- 약봉투를 카메라로 촬영하면 OCR과 번역을 통해 복약 정보를 사용자 언어로 제공합니다.
- 외국인 커뮤니티 리뷰를 통해 실제 외국인 환자의 경험을 공유할 수 있습니다.
- 한국어를 포함해 총 6개 언어(한국어·영어·중국어·베트남어·태국어·일본어)의 UI를 지원합니다.

### 주요 성과 (정량 지표)
| 항목 | 결과 |
|------|------|
| 병원 추천 API 응답 시간 | 90~120s → **15~20s** (약 83% 개선, 504 타임아웃 해소) |
| 의료비 예측 정확도 | MAPE **6.10%** (ICD-10 9개 코드 기준) |
| 약봉투 OCR 인식 정확도 | **70.9%** (이상치 3건 제외 시 75.0%) |
| AI 클린봇 정탐률 / 오탐률 | **96.7% / 0%** (n=60) |

## 배포 정보
| 항목 | 내용 |
|------|------|
| 도메인 | HTTPS, Route 53 + ACM + ALB |
| 서버 | AWS EC2 (t3.small, Docker) |
| 데이터베이스 | AWS RDS (MySQL 8.0) |
| 캐시 | AWS ElastiCache (Redis, TLS) |
| 스토리지 | AWS S3 (리뷰/번역 이미지) |
| 모니터링 | Prometheus + Grafana |

## 팀원 구성
<table>
  <tr>
    <th>임지성</th>
    <th>이승준</th>
    <th>유희수</th>
    <th>김채은</th>
    <th>박혜소</th>
  </tr>
  <tr>
    <td align="center">
      <a href="https://github.com/ljsoung">@ljsoung</a>
    </td>
    <td align="center">
      <a href="https://github.com/SaMeL-dev">@SaMeL-dev</a>
    </td>
    <td align="center">
      <a href="https://github.com/Uhsoo02">@Uhsoo02</a>
    </td>
    <td align="center">
      <a href="https://github.com/kimchaeeun0">@kimchaeeun0</a>
    </td>
    <td align="center">
      <a href="https://github.com/Parkhs88">@Parkhs88</a>
    </td>
  </tr>
</table>

## 기술 스택
| 구분 | 기술 스택 |
|------|-----------|
| **언어** | Java 21 (Spring Boot), Dart (Flutter), Python (데이터 전처리) |
| **모바일 앱** | Flutter 3.x, geolocator, google_maps_flutter, flutter_localizations |
| **백엔드** | Spring Boot 3.3.5, Spring Security, JPA, Lombok, Gradle |
| **AI / LLM** | GPT-5.4-mini Function Calling (증상 분석, ICD-10 분류, 진료과 매칭, AI 클린봇) |
| **DB / 캐시** | MySQL 8.0 (AWS RDS), Redis (AWS ElastiCache, TLS) |
| **외부 API** | 건강보험심사평가원 병원정보서비스 API(HIRA), Google Maps API, Google Vision API(OCR), DeepL API, Firebase FCM, Gmail SMTP |
| **인프라** | AWS EC2, ALB, Route 53, ACM, S3, Secrets Manager |
| **CI/CD** | GitHub Actions → Docker Build → Docker Hub → EC2 Pull & 재배포 |
| **모니터링** | Prometheus, Grafana |
| **보안** | BCryptPasswordEncoder, Spring Security 필터 체인, JWT (Access 15분 / Refresh 7일 · Redis) |
| **공공 데이터** | 건강보험 진료비 통계지표, 시도별 진료비 통계, 외국인 유치 의료기관목록 |
| **IDE / Tool** | IntelliJ IDEA, Android Studio, GitHub, Postman, Swagger |

## 지원 언어
| 구분 | 지원 언어 |
|------|-----------|
| UI (앱 전체) | 한국어, 영어, 중국어, 베트남어, 태국어, 일본어 (6개) |
| 의료 문서 번역 (DeepL) | 한국어 → 영어·중국어·베트남어·태국어·일본어 |

## 시스템 아키텍처
<img width="2260" height="1252" alt="시스템 아키텍처" src="https://github.com/user-attachments/assets/58a0b45d-bef1-4e27-832f-2adb9b546321" />

## 프로젝트 구조

```
healyx/
├── backend/                        # Spring Boot REST API
│   └── src/main/java/com/smu/healyx/
│       ├── agent/                  # AI Agent (GPT Function Calling)
│       ├── auth/                   # 인증 (JWT, 회원가입/로그인/비밀번호)
│       ├── common/                 # 공통 (ApiResponse, Security, S3, 예외처리)
│       │   ├── config/             # RedisConfig, RestTemplateConfig
│       │   ├── exception/          # GlobalExceptionHandler
│       │   ├── security/           # JwtProvider, JwtAuthenticationFilter
│       │   └── service/            # S3UploadService
│       ├── community/              # 커뮤니티 (게시글/댓글/북마크/신고)
│       ├── cost/                   # 의료비 예측
│       ├── deepl/                  # DeepL 번역 연동
│       ├── email/                  # 이메일 인증 (SMTP + Redis)
│       ├── fcm/                    # Firebase Cloud Messaging
│       ├── gpt/                    # GPT 증상 분석
│       ├── hira/                   # HIRA Open API 직접 검색
│       ├── hospital/               # 병원 추천 (Agent 래퍼)
│       ├── ocr/                    # Google Vision OCR
│       ├── review/                 # 리뷰 (영수증 OCR 인증)
│       ├── translation/            # 의료 번역 (OCR + DeepL + S3)
│       └── user/                   # 사용자 프로필
│           └── scheduler/          # 만 나이 자동 갱신 배치
│
└── frontend/                        # Flutter 앱
    └── lib/
        ├── screens/                 # 화면 단위 위젯 ({기능}Screen)
        ├── widgets/                 # 공용 컴포넌트
        ├── services/                # API 통신 (Dio 등)
        └── l10n/                    # 다국어 ARB 리소스 (8개 언어)
```

## 역할 분담
### 임지성 — PM, 백엔드, 프론트엔드
- 회원가입 / 로그인 / 이메일 인증(아이디 찾기·비밀번호 재설정) API
- 의료 번역(OCR + DeepL + S3) API, 메뉴/리뷰 API
- AI Agent(GPT Function Calling 기반 병원 추천 + ICD-10 추출) 구현
- HIRA Open API 등 외부 API 연동, AWS 인프라 구축, CI/CD 파이프라인 구축, 시크릿 키 관리
- 병원 추천 API 성능 개선(504 타임아웃 해소), 프로그램 설계서·클래스 다이어그램 작성
- 애자일 개발 방법론 및 GitFlow 브랜치 전략 수립, 팀원 일정 관리

### 이승준 — 백엔드, DB, QA
- 백엔드 도메인 모델 설계, 병원 추천 / 의료비 예측 / 커뮤니티 / 리뷰 모듈 API 구현
- DB 설계 및 문서화 후 구축, Swagger / JWT / 성능 캐싱 등 공통 인프라 보강
- 통합 테스트 실행

### 유희수 — 퍼블리셔, 프론트엔드
- 언어선택 / 메인 / 병원찾기 / 로그인 / 회원가입 / 비밀번호 찾기 / 아이디 찾기 화면 퍼블리싱
- 로그인·비로그인 권한 분기, 비밀번호 재설정, 병원찾기, 커뮤니티, 프로필 설정 API 연동
- 앱 자체 알림 디자인

### 김채은 — 기획, 디자인, QA
- 요구사항 정의서·분석서 작성(기능 84건 · 비기능 13건), 유스케이스 정의, WBS 작성
- UI/UX 설계, UI 정의서 작성, UI 디자인
- 테스트 케이스 작성 및 테스트, 이슈리스트 작성

### 박혜소 — 디자인, 퍼블리셔, QA
- 초기언어 / 로그인 / 의료번역 / 리뷰 / 커뮤니티 디자인
- 병원찾기 결과 / 의료번역 / 리뷰 / 커뮤니티 / 메뉴 / 프로필 퍼블리싱, 다국어 매핑
- 서비스 모니터링(Prometheus/Grafana)

## 개발 기간 및 작업 관리
### 개발 기간
- 2026.03.03 ~ 2026.06.19 (선문대학교 종합프로젝트, SW중심대학 기업연계 프로젝트)

### 작업 관리
- **애자일 2주 단위 스프린트** — Notion 칸반 보드에 작업 항목 등록 후 우선순위(P1·P2·P3) 부여, 매 스프린트 종료 시 회고 및 차기 계획 수립
- **GitFlow 기반 브랜치 전략** — `main | feature/{도메인}/{기능명}` 체계로 기능 단위 격리 개발, 모든 PR은 동료 코드 리뷰 후 머지
- Discord 음성 채널 + 카카오톡 채팅방 + 대면 회의를 병행하여 의사결정 지연 최소화
- 기능 단위별 메인/서브 역할자를 이원화 운영하여 단일 장애점(SPOF) 방지

## 주요 기능
### 1. AI 기반 병원 추천
- 증상을 음성 또는 텍스트로 입력하면 GPT-5.4-mini Function Calling 기반 AI Agent(`HospitalAgentService`)가 단일 호출로 `진료과목코드(dgsbjtCd)`와 `ICD-10 코드`를 동시 추출
- 위험도(1~5단계)에 따라 탐색 반경 자동 결정
  - 1~2단계 → 3km (의원급)
  - 3~4단계 → 10km (병원급)
  - 5단계 → 15km (응급)
- HIRA 병원정보서비스 API로 병원 종별 코드(clCd)별 GPS 기반 반경 내 병원을 **병렬 호출**하여 실시간 조회
- 4개 항목 하이브리드 스코어링으로 Top-5 병원 추천
  - 병원 타입 일치도 0.35
  - 외국어 친화도 0.30 (외국인 환자 유치 인증 여부 기반)
  - 리뷰 점수 0.15
  - 거리 패널티 0.20
  - **Cold Start 보정**: 리뷰 10건 미만 병원은 리뷰 항목을 제거하고 병원 타입 0.50 / 외국어 친화도 0.30 / 거리 0.20으로 재정규화하여, 신규·소규모 병원이 리뷰 부족으로 부당하게 하위 정렬되는 것을 방지

### 2. 의료비 예측
- 건강보험심사평가원 진료비 통계 데이터(ICD-10 기준 약 200개 질환 + 진료과 fallback) 기반 기준금액 산출
- 6단계 순차 연산: ICD-10 매칭 → 진료형태(외래/입원) 결정 → 보험 가입 여부별 기준수가 선택 → 연령·성별·지역·병원종별 보정계수 적용 → 물가계수(`INFLATION_RATE = 1.061`) 적용 → 신뢰구간 산출
- 건강보험 가입 여부에 따라 본인부담금 / 전액 두 가지 기준으로 산출하며, 최종 금액의 **±25%** 범위(최저~최고 예상가)로 표시
- 게스트는 ICD-10 코드만으로 순수 계산(보정 미적용), 로그인 사용자는 나이·성별·보험 보정 계수까지 적용된 정밀 예측 제공
- 예측 결과는 DB에 저장하지 않고 DTO(`CostPredictionResult`)로 실시간 연산하여 반환

### 3. 약봉투 / 의료 문서 번역
- 카메라로 처방전·약봉투·진단서 촬영 → Google Vision API OCR → 한국어 텍스트 추출
- DeepL API로 사용자 언어(영어·중국어·베트남어·태국어·일본어)로 번역 후 원본 이미지 위에 번역 텍스트 오버레이
- 번역 결과 이미지·원문·번역문을 AWS S3 및 DB에 저장, 사용자별 보관함에 **1년간** 보관 후 배치 삭제
- 보관함에서 원본/번역 이미지를 함께 확인하고 개별 삭제 가능

### 4. 커뮤니티 / 리뷰
- 영수증 OCR로 `ykiho`(요양기호) 대조 후 실제 방문자만 리뷰를 작성할 수 있는 신뢰 리뷰 시스템 (인증 상태는 Redis에 10분 TTL로 관리, 별도 DB 테이블 불필요)
- 리뷰 등록/삭제 시 병원 평균 별점을 동일 트랜잭션 내에서 즉시 재계산
- 누적 리뷰는 병원 추천 스코어링(리뷰 점수 0.15)에 자동 반영
- 커뮤니티는 병원 이용 여부와 관계없이 자유롭게 게시글·댓글 작성 가능
- 검색 키워드를 LLM으로 자동 번역하여 원문·번역문 양방향에서 일치 게시글을 탐색하는 다국어 통합 검색
- GPT 기반 AI 클린봇이 게시글/댓글 저장 직전 욕설·혐오 표현을 1차 차단하고, 신고 누적 콘텐츠는 재검토 후 자동 블라인드 처리하는 이중 필터 구조

### 5. 회원 가입 / 로그인
- 이메일 인증(Redis TTL 기반, `email:verify:{purpose}:{email}` 3분 / `email:verified:{purpose}:{email}` 10분) 후 회원가입 가능
- JWT 인증: Access Token 15분, Refresh Token 7일(Redis에만 저장, DB 미저장)
- 비밀번호는 `BCryptPasswordEncoder`로 해싱, 로그인 5회 실패 시 30분 계정 잠금
- 가입 시 수집한 나이·성별·보험 가입 여부는 의료비 예측 보정에 활용되며, 프로필 설정에서 언제든 수정 가능

## 성능 최적화 — 병원 추천 API 응답 시간 83% 개선

병원 추천 API(`POST /api/hospitals/recommend`)는 출시 초기 **90~120초**까지 응답이 지연되며 ALB 60초 idle timeout으로 인한 **504 Gateway Timeout**이 발생했습니다. 원인 분석 후 아래와 같이 개선했습니다.

| 병목 원인 | Before | 개선 방법 | After |
|-----------|--------|-----------|-------|
| GPT Function Calling Agent Loop 순차 실행 (`search_hospitals` → `extract_icd10_code`) | 약 15초 | 단일 GPT 호출로 `dgsbjtCd`·`departmentName`·`icd10Code` 동시 추출 | 약 2초 |
| HIRA `clCd` 4종 순차 블로킹 호출 | 40~60초 | `CompletableFuture` 기반 병렬 호출 (`clCd` 우선순위는 `putIfAbsent` 병합으로 보존) | 10~15초 |
| `RestTemplate` 타임아웃 미설정 → 외부 API 지연 시 무한 대기 | 무제한 | 연결 5초 / 읽기 20초 타임아웃 설정 | 즉시 차단 |
| **전체 응답 시간** | **90~120초 (504 발생)** | | **15~20초 (약 83% 개선, 타임아웃 해소)** |

> 평균 추천 응답 시간 15,550ms / p95 19,152ms (12개 신체 아이콘 × 외래·입원 위험도 × 5회 반복, 총 120회 측정 기준)

## 주요 API 엔드포인트

| 도메인 | 메서드 | 경로 | 설명 |
|--------|--------|------|------|
| 인증 | POST | `/api/auth/register` | 회원가입 (이메일 인증 선행 필수) |
| 인증 | POST | `/api/auth/login` | 로그인 (JWT 발급) |
| 인증 | POST | `/api/auth/find-id` | 아이디 찾기 |
| 인증 | PUT | `/api/auth/reset-password` | 비밀번호 재설정 |
| 이메일 | POST | `/api/email/send` / `/api/email/verify` | 이메일 인증 코드 발송 / 확인 |
| AI Agent | POST | `/api/agent/hospital-assistant` | 병원 추천 + 의료비 예측 통합 (게스트 가능) |
| 병원 | POST | `/api/hospitals/search` | HIRA API 직접 검색 |
| GPT | POST | `/api/gpt/analyze-symptom` | 증상 → 진료과 코드 추출 |
| OCR | POST | `/api/vision/ocr` | 이미지 → 텍스트 추출 (Google Vision) |
| 번역 | POST | `/api/translations/medical` | 의료 번역 (OCR + DeepL + S3, 게스트 가능) |
| 번역 | GET/DELETE | `/api/translations/archive/{id}` | 번역 보관함 조회 / 삭제 |
| 리뷰 | POST | `/api/reviews/ocr` | 영수증 OCR 방문 인증 |
| 리뷰 | POST | `/api/reviews` | 리뷰 등록 (방문 인증 후) |
| 리뷰 | GET | `/api/reviews/hospitals/{ykiho}` | 병원 상세 + 리뷰 목록 |
| 커뮤니티 | GET | `/api/community/bookmarks` | 북마크 목록 |
| 커뮤니티 | GET | `/api/community/my/posts` | 내가 쓴 게시글 |
| FCM | POST | `/api/fcm/test` | 푸시 알림 테스트 발송 |

## 시작하기

### 환경 변수 설정 (application-local.properties)
```properties
# 데이터베이스
spring.datasource.url=jdbc:mysql://localhost:3306/healyx
spring.datasource.username=root
spring.datasource.password=비밀번호
spring.datasource.driver-class-name=com.mysql.cj.jdbc.Driver

# JPA
spring.jpa.hibernate.ddl-auto=validate
spring.jpa.show-sql=true

# 건보 병원정보서비스 API (HIRA)
# 인증키는 URL-인코딩된 형태(%2F, %2B, %3D 포함)로 저장
api.hira.key=건보_API_인코딩_서비스키
api.hira.url=https://apis.data.go.kr/B551182/hospInfoService1

# OpenAI GPT (증상 분석 / AI Agent / 클린봇)
api.gpt.key=OpenAI_API_키
api.gpt.model=gpt-5.4-mini

# 구글 API (Maps · Vision OCR)
api.google.key=구글_API_키

# DeepL 번역
api.deepl.key=DeepL_API_키

# Redis (이메일 인증, Refresh Token, 진료과 캐시)
spring.data.redis.host=localhost
spring.data.redis.port=6379
# ElastiCache(TLS) 사용 시
# spring.data.redis.ssl.enabled=true

# JWT
jwt.secret=JWT_시크릿_키
jwt.access-expiration=900000      # 15분
jwt.refresh-expiration=604800000  # 7일

# Gmail SMTP (이메일 인증 코드 발송)
spring.mail.host=smtp.gmail.com
spring.mail.port=587
spring.mail.username=발송용_Gmail_계정
spring.mail.password=Gmail_앱_비밀번호

# Firebase FCM (푸시 알림)
fcm.credentials-path=firebase-service-account.json

# AWS S3 (리뷰 / 번역 이미지)
aws.s3.bucket=healyx-bucket
aws.s3.region=ap-northeast-2
aws.credentials.access-key=AWS_ACCESS_KEY
aws.credentials.secret-key=AWS_SECRET_KEY
```

> **운영(prod) 환경**에서는 위 민감 정보를 코드/프로퍼티에 직접 기입하지 않고, `application-prod.properties`에서 `${ENV_VAR}` 형태로 참조하며 실제 값은 **AWS Secrets Manager** 또는 EC2 환경변수로 주입합니다.

### 배포 (CI/CD)
```
git push (main)
  → GitHub Actions 트리거
  → Docker 이미지 빌드
  → Docker Hub Push
  → EC2에서 최신 이미지 Pull & 컨테이너 재시작
```
- `frontend/`, `backend/` 변경 경로에 따라 각각의 파이프라인이 분리 실행됩니다.
- 배포 자동화 실패 시 수동 배포 절차로 대체하여 기한 지연을 최소화합니다.
