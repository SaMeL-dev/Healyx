package com.smu.healyx.hira.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.smu.healyx.common.exception.ExternalApiException;
import com.smu.healyx.hira.dto.HiraItem;
import com.smu.healyx.hira.dto.HospitalDto;
import com.smu.healyx.hira.dto.HospitalSearchRequest;
import com.smu.healyx.hira.dto.HospitalSearchResponse;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;
import org.springframework.web.client.RestTemplate;

import java.net.URI;
import java.util.ArrayList;
import java.util.List;

@Slf4j
@Service
@RequiredArgsConstructor
public class HiraApiService {

    private final RestTemplate restTemplate;
    private final ObjectMapper objectMapper;

    @Value("${api.hira.url}")
    private String hiraApiUrl;

    @Value("${api.hira.key}")
    private String hiraApiKey;

    private static final String ENDPOINT = "/getHospBasisList";

    /**
     * HIRA Open API를 호출하여 병원 목록을 검색합니다.
     * 일 10,000건 트래픽 제한이 있으므로 불필요한 중복 호출을 방지해야 합니다.
     */
    public HospitalSearchResponse searchHospitals(HospitalSearchRequest request) {
        URI uri = buildUri(request);
        log.debug("HIRA API 호출: {}", uri.toString().replaceAll("serviceKey=[^&]+", "serviceKey=***"));

        String rawResponse;
        try {
            rawResponse = restTemplate.getForObject(uri, String.class);  // URI 객체 전달
        } catch (Exception e) {
            log.error("HIRA API 호출 실패: {}", e.getMessage());
            throw new ExternalApiException("HIRA_API_ERROR", "병원 정보 서비스에 일시적으로 접근할 수 없습니다. 잠시 후 다시 시도해 주세요.");
        }

        log.debug("HIRA API 원시 응답: {}", rawResponse);
        return parseResponse(rawResponse, request.getPageNo(), request.getNumOfRows());
    }

    private URI buildUri(HospitalSearchRequest request) {
        StringBuilder sb = new StringBuilder();
        sb.append(hiraApiUrl).append(ENDPOINT);
        sb.append("?serviceKey=").append(hiraApiKey);
        sb.append("&pageNo=").append(request.getPageNo());
        sb.append("&numOfRows=").append(request.getNumOfRows());
        sb.append("&_type=json");

        if (StringUtils.hasText(request.getDgsbjtCd())) {
            sb.append("&dgsbjtCd=").append(request.getDgsbjtCd());
        }
        if (StringUtils.hasText(request.getClCd())) {
            sb.append("&clCd=").append(request.getClCd());
        }
        if (StringUtils.hasText(request.getXPos())) {
            sb.append("&xPos=").append(request.getXPos());
        }
        if (StringUtils.hasText(request.getYPos())) {
            sb.append("&yPos=").append(request.getYPos());
        }
        if (StringUtils.hasText(request.getRadius())) {
            sb.append("&radius=").append(request.getRadius());
        }

        return URI.create(sb.toString());
    }

    private HospitalSearchResponse parseResponse(String rawResponse, int pageNo, int numOfRows) {
        try {
            JsonNode root = objectMapper.readTree(rawResponse);
            JsonNode header = root.path("response").path("header");

            String resultCode = header.path("resultCode").asText();
            if (!"00".equals(resultCode)) {
                log.error("HIRA API 오류 응답: resultCode={}, resultMsg={}",
                        resultCode, header.path("resultMsg").asText());
                throw new ExternalApiException("HIRA_API_ERROR",
                        "[HIRA resultCode=" + resultCode + "] " + header.path("resultMsg").asText());
            }

            JsonNode body = root.path("response").path("body");
            int totalCount = body.path("totalCount").asInt(0);

            List<HospitalDto> hospitals = new ArrayList<>();
            JsonNode itemNode = body.path("items").path("item");

            if (itemNode.isArray()) {
                for (JsonNode node : itemNode) {
                    HiraItem item = objectMapper.treeToValue(node, HiraItem.class);
                    hospitals.add(toHospitalDto(item));
                }
            } else if (itemNode.isObject()) {
                // 결과가 1건일 때 HIRA API는 배열 대신 단일 객체를 반환
                HiraItem item = objectMapper.treeToValue(itemNode, HiraItem.class);
                hospitals.add(toHospitalDto(item));
            }
            // itemNode가 없거나 빈 문자열이면 빈 리스트 반환

            return HospitalSearchResponse.builder()
                    .hospitals(hospitals)
                    .pageNo(pageNo)
                    .numOfRows(numOfRows)
                    .totalCount(totalCount)
                    .build();

        } catch (ExternalApiException e) {
            throw e;
        } catch (Exception e) {
            log.error("HIRA API 응답 파싱 실패", e);
            throw new ExternalApiException("HIRA_PARSE_ERROR", "병원 정보 서비스에 일시적으로 접근할 수 없습니다. 잠시 후 다시 시도해 주세요.");
        }
    }

    private HospitalDto toHospitalDto(HiraItem item) {
        return HospitalDto.builder()
                .ykiho(item.getYkiho())
                .hospitalName(item.getYadmNm())
                .address(item.getAddr())
                .telephone(item.getTelno())
                .longitude(item.getLongitude())
                .latitude(item.getLatitude())
                .hospitalType(item.getClCdNm())
                .foreignCertified(false) // DB 연동 완료 후 foreign_certified_hospital 테이블에서 조회
                .build();
    }
}