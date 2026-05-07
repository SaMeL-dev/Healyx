# ---------- Build Stage ----------
FROM gradle:8.5-jdk21 AS builder
WORKDIR /app
COPY . .
RUN gradle bootJar --no-daemon

# ---------- Run Stage ----------
FROM eclipse-temurin:21-jre
WORKDIR /app

# 다국어 텍스트 오버레이 렌더링에 필요한 폰트
# fonts-thai-tlwg-ttf : 태국어 (TH Sarabun New, Loma 등)
# fonts-noto-cjk      : 한국어·중국어·일본어 (Noto Sans CJK)
RUN apt-get update --fix-missing && \
    apt-get install -y --no-install-recommends \
        fonts-thai-tlwg-ttf \
        fonts-noto-cjk && \
    fc-cache -f && \
    rm -rf /var/lib/apt/lists/*

COPY --from=builder /app/build/libs/*.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", \
  "-Xms128m", \
  "-Xmx350m", \
  "-XX:MetaspaceSize=128m", \
  "-XX:MaxMetaspaceSize=200m", \
  "-XX:ReservedCodeCacheSize=64m", \
  "-XX:+UseSerialGC", \
  "-jar", "app.jar"]