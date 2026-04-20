package com.smu.healyx.common.exception;

public class ExternalApiException extends RuntimeException {

    private final String errorCode;

    public ExternalApiException(String errorCode, String message) {
        super(message);
        this.errorCode = errorCode;
    }

    public String getErrorCode() {
        return errorCode;
    }
}