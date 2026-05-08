# HEALYX — Claude Code 컨텍스트 파일

> 외국인 환자를 위한 병원 찾기·리뷰·의료비 예측·의료 번역 플랫폼
> 백엔드: Spring Boot (Java) | 프론트엔드: Flutter

---

## 1. 기술 스택

| 레이어 | 기술 |
|---|---|
| 백엔드 | Java 21+, Spring Boot 3.3.5, Spring Security (JWT) |
| 프론트엔드 | Flutter |
| DB | MySQL, DBML 기반 스키마 정의 |
| 캐시 | Redis (이메일 인증 TTL, OCR 토큰 TTL 관리) |
| 스토리지 | AWS S3 (영수증·리뷰 이미지) |
| 외부 API | Google Vision API (OCR), DeepL (번역), GPT Function Calling (증상 분석·ICD-10 추출), HIRA 건강보험 API |
| 알림 | FCM (Firebase Cloud Messaging) |

---

## 2. 패키지 구조 컨벤션

백엔드 패키지는 반드시 아래 규칙을 따름:

```
com.smu.healyx.{도메인}.{레이어}
```

예시:
- `com.smu.healyx.auth.service` — AuthService
- `com.smu.healyx.review.controller` — ReviewController
- `com.smu.healyx.hospital.service` — HospitalRecommendService
- `com.smu.healyx.cost.service` — CostPredictionService
- `com.smu.healyx.community.service` — CommunityService
- `com.smu.healyx.translation.service` — TranslationService

레이어 종류: `controller` / `service` / `domain` / `dto` / `repository`

---

## 3. API 응답 형식 (필수 준수)

모든 API는 아래 형식으로 응답해야 함:

```json
// 성공
{ "success": true, "data": { ... } }

// 실패
{ "success": false, "errorCode": "ERROR_CODE", "message": "..." }
```

- `data`가 없는 성공 응답도 `"data": null` 명시
- errorCode는 UPPER_SNAKE_CASE

---

## 4. 인증 정책 (NFR-AUTH-001 기반)

- 인증 수단: JWT Bearer Token
- 비로그인 허용 API: 병원별 리뷰 조회(`GET /api/reviews/hospitals/**`), 의료비 예측(`POST /api/cost/predict`)
- 본인 리소스 검증: 삭제·수정 시 반드시 `userId` 일치 검증 → 불일치 시 403

SecurityConfig 패턴:
```java
.requestMatchers(HttpMethod.GET, "/api/reviews/hospitals/**").permitAll()
.requestMatchers("/api/reviews/**").authenticated()
```

---

## 5. 주요 도메인별 비즈니스 규칙

### 5-1. 회원 (Auth / User)

- 아이디: 영문+숫자 7~12자 (`ACC-003`)
- 비밀번호: BCrypt 암호화
- 닉네임: 최대 10자 (`ACC-006`)
- 로그인 실패 5회 초과 → 30분 계정 잠금 (`HX_A_005`)
- 이메일 인증: Redis TTL 3분, key: `verify:FIND_ID:{email}` / `verify:RESET_PW:{email}`
- 나이: 한국식 나이, 배치로 연간 갱신

### 5-2. 리뷰 (`HX_R_*` / 요구사항 `RV-001~008`)

- 병원 식별자: **hospitalId(Long) 아님 → ykiho(String)** 사용 (v2 변경사항)
- OCR 인증 토큰: UUID 별도 발급 없음, Redis key 존재 여부로 검증
  - key: `ocr:{userId}:{ykiho}`, TTL 600초(10분), value: receipt_image_url
- 병원명 정규화 비교 (공백·특수문자 제거, lowercase, contains 방식)
- 리뷰 삭제: hard delete, 순서: S3 삭제 → review_images 행 삭제 → reviews 행 삭제
- 이미지: 최대 5장, 서버 단 강제
- 리뷰 본문: 최대 2000자
- 별점: 1~5 정수
- 닉네임 마스킹: 앞 2자 + `***`
- hospitals 테이블 upsert 시점: **병원 추천 API(HospitalRecommendService) 호출 시점**

### 5-3. 의료비 예측 (`HX_C_*` / 요구사항 `COST-001~004`)

- riskLevel 1~2 → outpatient, 3~5 → inpatient
- 보정 순서: 기준수가 × 연령·성별계수 × 지역계수(현재 1.0 고정) × 병원종별계수 × 물가계수 1.061
- 신뢰구간: min = 최종금액 × 0.75 (절사), max = 최종금액 × 1.25 (올림)
- icd10Code와 departmentName 둘 다 미전달 → 400
- hasHealthInsurance 미전달 시 false 처리

### 5-4. 병원 (`HX_H_*`)

- 병원 종별(clCd): 01=상급종합병원, 11=종합병원, 21=병원, 28=요양병원, 61=정신병원, 31=의원, 41=치과병원, 51=치과의원 (또는 42), 92=한방병원, 93=한의원 (또는 52)
- 외국인 유치 인증 여부: 배치로 `hospitals.is_foreign_certified` 갱신
- GPT Function Calling으로 icd10Code 추출 → Flutter가 의료비 예측 API에 전달

### 5-5. 커뮤니티 (`HX_COM_*`)

- 알림 유형: LIKE, COMMENT, REPLY
- 신고 대상: POST, COMMENT

### 5-6. 의료 번역 (`HX_T_*`)

- OCR: Google Vision API
- 번역: DeepL
- 지원 언어: zh, vi, th, en, uz, fil, ja (`LG-002`)

---

## 6. Redis Key 설계 (충돌 방지 필수)

| 용도 | Key 패턴 | TTL |
|---|---|---|
| 이메일 인증 (아이디 찾기) | `verify:FIND_ID:{email}` | 3분 |
| 이메일 인증 (비밀번호 재설정) | `verify:RESET_PW:{email}` | 3분 |
| OCR 인증 토큰 | `ocr:{userId}:{ykiho}` | 10분 |

FIND_ID / RESET_PW 동시 요청 시 key 충돌 방지 → prefix로 분리

---

## 7. DB 핵심 규칙

- `users` 테이블: `created_at`, `updated_at` 없음 (2차 리코멘트 결정)
- `hospitals` 테이블: `created_at` 보존 (디버깅용)
- `email_verifications` 테이블 삭제 → Redis TTL로 대체
- 리뷰 삭제: hard delete (soft delete 아님)
- `hospital_departments` 테이블: 현재 보류 상태
- 외래키 명명: `{참조테이블}_id` 패턴

---

## 8. S3 디렉토리 구조

| 용도 | directory |
|---|---|
| 영수증 이미지 | `receipts/` |
| 리뷰 첨부 이미지 | `reviews/` |

업로드: `S3UploadService.upload()` | 삭제: `S3UploadService.delete()`

---

## 9. 에러 코드 목록 (주요)

| errorCode | 상황 |
|---|---|
| `HOSPITAL_NOT_FOUND` | ykiho로 병원 미발견 |
| `OCR_UNREADABLE` | Vision API 텍스트 미감지 |
| `RECEIPT_MISMATCH` | 영수증 병원명 불일치 |
| `OCR_TOKEN_EXPIRED` | Redis OCR 토큰 없음/만료 |
| `INVALID_RATING` | 별점 범위 오류 (1~5) |
| `CONTENT_TOO_LONG` | 리뷰 2000자 초과 |
| `TOO_MANY_IMAGES` | 이미지 5장 초과 |
| `REVIEW_NOT_FOUND` | 리뷰 미발견 |
| `FORBIDDEN` | 본인 리소스 아님 |

---

## 10. PR 검토 시 반드시 확인할 항목

Claude가 PR을 검토할 때 아래 항목을 우선 확인:

1. **API 응답 형식** — `{"success": true/false, "data": ...}` 구조 준수 여부
2. **인증/권한 처리** — 비로그인 허용 API 외 인증 누락, 본인 리소스 403 처리
3. **hospitalId vs ykiho** — 외부 인터페이스에서 hospitalId(Long) 사용 여부 (v2 이후 ykiho(String)만 허용)
4. **Redis key 패턴** — 정해진 prefix 사용 여부, TTL 설정 여부
5. **리뷰 삭제 순서** — S3 → review_images → reviews 순서 준수
6. **유효성 검사** — 별점(1~5), 본문(2000자), 이미지(5장) 서버 단 검증
7. **병원명 정규화** — OCR 비교 시 normalize() 함수 적용 여부
8. **패키지 구조** — `com.smu.healyx.{도메인}.{레이어}` 컨벤션
9. **S3 디렉토리** — receipts/ vs reviews/ 올바른 경로 사용
10. **보안** — SQL Injection, 민감정보 로깅(비밀번호, 개인정보) 여부
11. **민감정보 커밋 차단** — 아래 파일이 diff에 포함되면 즉시 ❌ 처리:
    - `application-local.properties` (API 키, DB 비밀번호 포함)
    - `firebase/` 디렉토리 내 JSON 파일 (서비스 계정 키)
    - `*.pem`, `*.ppk` (SSH 키)
    - 코드 내 하드코딩된 API 키 문자열 (`sk-`, `AIzaSy`, `AKIA` 등 패턴)
12. **운영 설정 하드코딩** — `application-prod.properties`에서 값이 `${ENV_VAR}` 형식이 아닌 평문으로 들어간 경우 ❌
13. **좌표 필드 매핑** — HIRA API 응답에서 `XPos` → `longitude`(경도), `YPos` → `latitude`(위도) 매핑 확인 (반대로 저장 시 지도 핀 오작동)
14. **브랜치 네이밍** — 섹션 12 규칙 준수 여부
15. **커밋 메시지 prefix** — `feat:` / `fix:` / `chore:` / `refactor:` 중 하나 사용 여부

---

## 11. 담당자

| 역할 | 담당 |
|---|---|
| PM / 백엔드 총괄 | 임지성 |
| 병원·리뷰·비용 서비스 | 이승준 |
| Flutter UI | 유희수, 박혜소 |

---

## 12. 브랜치 전략 및 커밋 컨벤션

### 브랜치 네이밍 규칙

```
feature/backend/{기능명}     예: feature/backend/auth-login
feature/frontend/{기능명}    예: feature/frontend/login-screen
fix/backend/{기능명}         예: fix/backend/token-refresh
hotfix/{기능명}              예: hotfix/jwt-expiry-crash
```

### 커밋 메시지 prefix

| prefix | 용도 |
|---|---|
| `feat:` | 새 기능 |
| `fix:` | 버그 수정 |
| `chore:` | 설정, 패키지, 빌드 등 |
| `refactor:` | 리팩토링 |

### 핵심 규칙

- main 직접 푸시 금지 (초기 세팅 커밋 이후)
- 모든 작업은 브랜치 생성 → 개발 → PR → 머지 사이클
- PR은 팀원 1명 리뷰 필수
- PR은 24시간 내 리뷰 (브랜치 장기 생존 시 충돌 위험)
- `application.properties`, `build.gradle` 등 공유 파일 변경 시 팀 공지

### CI/CD 트리거 범위

```yaml
on:
  push:
    branches: [main]
    paths:
      - 'backend/**'   # backend 폴더 변경 시에만 배포 트리거
```

프론트엔드(Flutter)는 CI/CD 없음 — APK 빌드 후 직접 설치

---

## 13. 병원 추천 비즈니스 로직 (검토 기준)

### 탐색 반경 (긴급도별)

| riskLevel | 반경 | 대상 |
|---|---|---|
| 1~2 | 3km | 의원급 |
| 3~4 | 10km | 병원급 |
| 5 | 15km | 응급 |

### 하이브리드 스코어링 가중치

리뷰 10건 이상일 때:

| 항목 | 가중치 |
|---|---|
| 진료과 유사도 | 0.40 |
| 외국어 지원 | 0.30 |
| 리뷰 점수 | 0.20 |
| 거리 패널티 | 0.10 |

리뷰 10건 미만일 때:

| 항목 | 가중치 |
|---|---|
| 진료과 유사도 | 0.55 |
| 외국어 지원 | 0.35 |
| 거리 패널티 | 0.10 |

### HIRA API 주의사항

- 일일 트래픽: 10,000건 제한
- 좌표 매핑: `XPos` → `longitude`(경도), `YPos` → `latitude`(위도) ← 반드시 준수
- clCd 변환 누락 시 `"기타"` fallback 처리
- 추천 병원 Top 5 → Flutter 전달 + Redis 캐싱 대상

### 의료비 보정계수 물가 수치

```
물가계수 = 1.061  (2023→2026, 연 2% 복리 3년)
```

매 의료비 예측 연산마다 고정 적용. 임의 변경 금지.
