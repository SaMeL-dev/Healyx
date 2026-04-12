# Healyx 외국인을 위한 AI 기반 병원 추천 및 의료비 예측 플랫폼

<img width="1804" height="1016" alt="image" src="https://github.com/user-attachments/assets/f6346b76-fcad-4007-bc87-55757d7b40ac" />

## 프로젝트 소개
 - Healyx는 한국에 거주하거나 방문하는 외국인이 언어 장벽과 의료비 불확실성으로 인해 적절한 의료 서비스에 어려움을 겪는 문제를 해결하기 위한 애플리케이션입니다.
 - 증상을 음성 또는 텍스트로 입력하면 AI가 분석하여 주변의 적합한 병원을 추천해줍니다.
 - 사용자의 나이, 성별, 지역, 보험 가입 여부를 기반으로 예상 의료비 범위를 제공합니다.
 - 약봉투를 카메라로 촬영하면 OCR과 번역을 통해 복약 정보를 사용자 언어로 제공합니다.
 - 외국인 커뮤니티 리뷰를 통해 실제 외국인 환자의 경험을 공유할 수 있습니다.

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
| **언어** | Java(Spring Boot), Dart(Flutter), Python(데이터 전처리) |
| **모바일 앱** | Flutter 3.x, geolocator, google_maps_flutter |
| **백엔드** | Spring Boot 3.x, JPA, Lombok, Gradle |
| **AI / LLM** | GPT-4o-mini (증상 분석, ICD-10 분류, 긴급도 판정) |
| **DB** | MySQL, Redis |
| **외부 API** | 건강보험심사평가원 병원정보서비스 API, 구글맵 API, Google Vision API, DeepL API |
| **보안** | BCryptPasswordEncoder, Spring Security 필터 체인 |
| **공공 데이터** | 건강보험 진료비 통계지표, 시도별 진료비 통계, 외국인 유치 의료기관목록 |
| **IDE / Tool** | IntelliJ IDEA, Android Studio, GitHub, Postman |

## 시스템 아키텍처
추가 예정

## 프로젝트 구조
추가 예정

## 역할 분담
### 임지성
 - **PM**
 - **백엔드**
 - **프론트엔드**

### 이승준
 - **QA**
 - **백엔드**
 - **DB**

### 유희수
 - **퍼블리셔**
 - **프론트엔드**

### 김채은

### 박혜소

## 개발 기간 및 작업 관리
### 개발 기간
 - 2026.03.02 ~ 2025.06.13

### 작업 관리
 - 카카오톡 등으로 TODO 리스트 정리하여 공유
 - Github로 코드 작성 후 Commit/Push하여 진행 상황 공유
 - 매일 1~2시간 가량 진도 체크 및 개발 진행

## 주요 기능
### 1. AI 기반 병원 추천
 - 증상을 음성 또는 로 입력하면 GPT-4o-mini가 ICD-10 코드, 진료과, 긴급도(1~5)를 분석
 - 긴급도에 따라 탐색 반경 자동 결정 (1 ~ 2: 3km / 3 ~ 4: 10km / 5: 15km)
 - 건보 병원정보서비스 API로 GPS 기반 반경 내 병원 실시간 조회
 - 4개 항목 하이브리드 스코어링으로 Top-5 병원 추천
   - α(0.40) · 진료과 유사도
   - β(0.30) · 외국어 지원 점수 (외국인 유치 인증 기반)
   - γ(0.20) · 리뷰 점수
   - δ(0.10) · 거리 패널티
  
### 2. 의료비 예측
 - 건강보험 진료비 통계 데이터(ICD-10 기준 200개 질환) 기반 기준금액 산출
 - 연령·성별 보정계수, 지역 보정계수, 물가 보정계수 순차 적용
 - 건강보험 가입 여부에 따라 본인부담금 / 전액 두 가지 범위 표시 (±25%)

### 3. 약봉투 번역
 - 카메라로 약봉투 촬영 → Google Vision API OCR → 한국어 텍스트 추출
 - DeepL API로 사용자 언어(영어·중국어·일본어 등)로 번역
 - 약명 / 복용법 / 주의사항 항목별 카드 표시

### 4. 커뮤니티 / 리뷰
 - 외국인 사용자가 병원 방문 후 평점·텍스트 작성
 - 누적 리뷰가 병원 추천 스코어링(γ 가중치)에 자동 반영
 - 커뮤니티에서는 후기글이나 포스팅 등을 병원 이용 여부 상관없이 자유롭게 작성

### 5. 회원 가입 / 로그인
 - 이메일 기반 회원 가입 및 JWT 인증
 - 가입 시 수집한 나이·성별·보험 가입 여부는 의료비 예측 보정에 활용

## 시작하기
환경 변수 설정 (application.properties)
```properties
# 데이터베이스
spring.datasource.url=jdbc:mysql://localhost:3306/healyx
spring.datasource.username=root
spring.datasource.password=비밀번호
spring.datasource.driver-class-name=com.mysql.cj.jdbc.Driver

# JPA
spring.jpa.hibernate.ddl-auto=validate
spring.jpa.show-sql=true

# 건보 병원정보서비스 API
api.hira.key=건보_API_인코딩_서비스키
api.hira.url=https://apis.data.go.kr/B551182/hospInfoService1

# OpenAI GPT
api.gpt.key=OpenAI_API_키

# 구글 API (Maps · Vision)
api.google.key=구글_API_키

# DeepL 번역
api.deepl.key=DeepL_API_키

# Redis
spring.data.redis.host=localhost
spring.data.redis.port=6379

# JWT
jwt.secret=JWT_시크릿_키
jwt.expiration=86400000
```
