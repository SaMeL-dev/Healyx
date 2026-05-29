import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../app_language.dart';
import '../model/hospital_recommend_response.dart';

class HospitalRecommendService {
  static const String _baseUrl = 'https://jwejweiya.com';

  static Future<HospitalRecommendResponse> recommendHospitals({
    required String symptom,
    required double latitude,
    required double longitude,
    required int riskLevel,
    String sortBy = 'recommend',
    String? accessToken,
  }) async {
    final uri = Uri.parse('$_baseUrl/api/hospitals/recommend');

    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (accessToken != null && accessToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $accessToken';
    }

    final body = {
      'symptom': symptom,
      'latitude': latitude,
      'longitude': longitude,
      'languageCode': AppLanguage.currentLang.value,
      'riskLevel': riskLevel,
      'sortBy': sortBy,
    };

    debugPrint('===== 병원 추천 API 요청 시작 =====');
    debugPrint('URL: $uri');
    debugPrint(
      'Authorization Header: ${accessToken != null && accessToken.isNotEmpty ? 'included' : 'not included'}',
    );
    debugPrint('Body: ${jsonEncode(body)}');

    try {
      final response = await http
          .post(
        uri,
        headers: headers,
        body: jsonEncode(body),
      )
          .timeout(const Duration(seconds: 100));

      final decodedBody = utf8.decode(response.bodyBytes);

      debugPrint('===== 병원 추천 API 응답 =====');
      debugPrint('StatusCode: ${response.statusCode}');
      debugPrint('ResponseBody: $decodedBody');

      // 504 Gateway Time-out은 서버에서 HTML로 내려오는 경우가 많으므로
      // JSON 파싱 전에 먼저 처리해야 함
      if (response.statusCode == 504) {
        throw HospitalRecommendException(
          message: 'gateway_timeout',
          statusCode: response.statusCode,
        );
      }

      Map<String, dynamic> jsonBody;

      try {
        jsonBody = jsonDecode(decodedBody) as Map<String, dynamic>;
      } catch (e) {
        debugPrint('병원 추천 API JSON 파싱 실패: $e');

        throw HospitalRecommendException(
          message: 'server_response_parse_error',
          statusCode: response.statusCode,
        );
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return HospitalRecommendResponse.fromJson(jsonBody);
      }

      throw HospitalRecommendException(
        message: jsonBody['message']?.toString() ?? 'hospital_recommend_failed',
        statusCode: response.statusCode,
      );
    } on TimeoutException {
      throw HospitalRecommendException(
        message: 'timeout',
      );
    } catch (e) {
      debugPrint('===== 병원 추천 API 실제 오류 =====');
      debugPrint(e.toString());

      if (e is HospitalRecommendException) {
        rethrow;
      }

      throw HospitalRecommendException(
        message: 'hospital_recommend_failed',
      );
    }
  }
}

class HospitalRecommendException implements Exception {
  final String message;
  final int? statusCode;

  HospitalRecommendException({
    required this.message,
    this.statusCode,
  });

  @override
  String toString() {
    if (statusCode == null) {
      return message;
    }

    return '[$statusCode] $message';
  }
}