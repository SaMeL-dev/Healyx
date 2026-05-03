package com.smu.healyx.hospital.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;

import java.util.List;

@Getter
@Builder
@AllArgsConstructor
public class HospitalSummaryDto {
    private Long hospitalId;
    private String name;
    private String type;
    private String address;
    private double latitude;
    private double longitude;
    private String phone;
    private boolean isForeignCertified;
    private List<String> departments;
    private Double avgRating;    // 리뷰 없으면 null
    private int reviewCount;
    private double distanceKm;
    private double score;
}