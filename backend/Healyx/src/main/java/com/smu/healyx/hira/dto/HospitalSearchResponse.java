package com.smu.healyx.hira.dto;

import lombok.Builder;
import lombok.Getter;

import java.util.List;

@Getter
@Builder
public class HospitalSearchResponse {

    private List<HospitalDto> hospitals;
    private int pageNo;
    private int numOfRows;
    private int totalCount;
}