// 리뷰 관련 API 서비스// GET    /api/reviews/hospitals/search — 리뷰용 병원 검색
// GET    /api/reviews/my              — 내 리뷰 목록 조회
// DELETE /api/reviews/my/{reviewId}  — 내 리뷰 삭제

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

// 리뷰 병원 검색 결과 모델
class HospitalSearchResult {
  final String ykiho;
  final String hospitalName;
  final String address;
  final double avgRating;
  final int reviewCount;
  final bool foreignCertified;

  HospitalSearchResult({
    required this.ykiho,
    required this.hospitalName,
    required this.address,
    required this.avgRating,
    required this.reviewCount,
    required this.foreignCertified,
  });

  factory HospitalSearchResult.fromJson(Map<String, dynamic> json) {
    return HospitalSearchResult(
      ykiho: json['ykiho'] ?? '',
      hospitalName: json['name'] ?? json['hospitalName'] ?? '',
      address: json['address'] ?? '',
      avgRating: (json['averageRating'] ?? json['avgRating'] ?? 0).toDouble(),
      reviewCount: json['reviewCount'] ?? 0,
      foreignCertified: json['foreignCertified'] ?? false,
    );
  }
}

// 내 리뷰 항목 모델
class MyReviewData {
  final int reviewId;
  final String hospitalName;
  final String ykiho;
  final String contentPreview;
  final double rating;
  final String address;
  final bool hasBadge;

  MyReviewData({
    required this.reviewId,
    required this.hospitalName,
    required this.ykiho,
    required this.contentPreview,
    required this.rating,
    required this.address,
    required this.hasBadge,
  });

  factory MyReviewData.fromJson(Map<String, dynamic> json) {
    return MyReviewData(
      reviewId: json['reviewId'] ?? 0,
      hospitalName: json['hospitalName'] ?? '',
      ykiho: json['ykiho'] ?? '',
      contentPreview: json['contentPreview'] ?? json['content'] ?? '',
      rating: (json['rating'] ?? 0).toDouble(),
      address: json['address'] ?? '',
      hasBadge: json['hasBadge'] ?? json['foreignCertified'] ?? false,
    );
  }
}

class ReviewService {
  static const String _baseUrl = 'https://jwejweiya.com';

  // 리뷰용 병원 검색 — GET /api/reviews/hospitals/search?name=&region=&page=&size=
  static Future<List<HospitalSearchResult>> searchHospitals({
    String name = '',
    String region = '',
    int page = 0,
    int size = 20,
  }) async {
    final params = {
      if (name.isNotEmpty) 'name': name,
      if (region.isNotEmpty) 'region': region,
      'page': '$page',
      'size': '$size',
    };
    final uri = Uri.parse('$_baseUrl/api/reviews/hospitals/search')
        .replace(queryParameters: params);

    final response = await http.get(uri).timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final decoded = utf8.decode(response.bodyBytes);
      final json = jsonDecode(decoded);
      // 응답: { data: { hospitals: [...], totalCount: N } }
      final dynamic raw = json['data'];
      final List list = (raw is Map ? (raw['hospitals'] ?? raw['content']) : raw) as List? ?? [];
      return list
          .map((e) => HospitalSearchResult.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    // 비-200 응답은 예외로 변환해 호출부의 에러 상태를 트리거
    debugPrint('SEARCH_HOSPITALS HTTP ${response.statusCode}: ${response.body}');
    throw Exception('HTTP ${response.statusCode}');
  }

  // 내 리뷰 목록 조회
  static Future<List<MyReviewData>> getMyReviews() async {
    try {
      final token = await AuthService.getAccessToken();
      if (token == null || token.isEmpty) return [];

      final response = await http.get(
        Uri.parse('$_baseUrl/api/reviews/my'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final decoded = utf8.decode(response.bodyBytes);
        final json = jsonDecode(decoded);
        final List list = (json['data'] ?? []) as List;
        return list
            .map((e) => MyReviewData.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('GET_MY_REVIEWS ERROR: $e');
      return [];
    }
  }

  // 내 리뷰 삭제 (하드 삭제)
  static Future<bool> deleteMyReview(int reviewId) async {
    try {
      final token = await AuthService.getAccessToken();
      if (token == null || token.isEmpty) return false;

      final response = await http.delete(
        Uri.parse('$_baseUrl/api/reviews/my/$reviewId'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 15));

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      debugPrint('DELETE_MY_REVIEW ERROR: $e');
      return false;
    }
  }
}