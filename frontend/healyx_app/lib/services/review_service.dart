// 리뷰 관련 API 서비스
// GET    /api/reviews/hospitals/search       — 리뷰용 병원 검색
// GET    /api/reviews/hospitals/{ykiho}      — 병원 상세 + 리뷰 목록
// GET    /api/reviews/my                     — 내 리뷰 목록 조회
// DELETE /api/reviews/my/{reviewId}          — 내 리뷰 삭제

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

// 병원 상세 화면의 개별 리뷰 모델
class ReviewItem {
  final int reviewId;
  final String nickname;
  final String content;
  final int rating;
  final List<String> imageUrls;
  final String createdAt;

  ReviewItem({
    required this.reviewId,
    required this.nickname,
    required this.content,
    required this.rating,
    required this.imageUrls,
    required this.createdAt,
  });

  factory ReviewItem.fromJson(Map<String, dynamic> json) {
    final rawRating = json['rating'] ?? 0;
    return ReviewItem(
      reviewId: json['reviewId'] ?? 0,
      nickname: json['nickname'] ?? '',
      content: json['content'] ?? '',
      rating: rawRating is double ? rawRating.round() : rawRating as int,
      imageUrls: List<String>.from(json['images'] ?? []),
      createdAt: json['createdAt'] ?? '',
    );
  }
}

// 병원 상세 + 리뷰 목록 응답 모델
class HospitalDetailData {
  final String ykiho;
  final String hospitalName;
  final String hospitalType;
  final String address;
  final String telephone;
  final double averageRating;
  final int reviewCount;
  final bool foreignCertified;
  final bool myReviewExists;
  final List<ReviewItem> reviews;

  HospitalDetailData({
    required this.ykiho,
    required this.hospitalName,
    required this.hospitalType,
    required this.address,
    required this.telephone,
    required this.averageRating,
    required this.reviewCount,
    required this.foreignCertified,
    required this.myReviewExists,
    required this.reviews,
  });

  factory HospitalDetailData.fromJson(Map<String, dynamic> json) {
    return HospitalDetailData(
      ykiho: json['ykiho'] ?? '',
      hospitalName: json['hospitalName'] ?? json['name'] ?? '',
      hospitalType: json['hospitalType'] ?? '',
      address: json['address'] ?? '',
      telephone: json['telephone'] ?? '',
      averageRating: (json['averageRating'] ?? json['avgRating'] ?? 0).toDouble(),
      reviewCount: json['totalCount'] ?? json['reviewCount'] ?? 0,
      foreignCertified: json['foreignCertified'] ?? false,
      myReviewExists: json['myReviewExists'] ?? false,
      reviews: (json['reviews'] as List? ?? [])
          .map((e) => ReviewItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

// 메인화면 최신 리뷰 미리보기 항목 모델
class LatestReviewData {
  final int reviewId;
  final String hospitalName;
  final String nickname;
  final String content;
  final int rating;

  LatestReviewData({
    required this.reviewId,
    required this.hospitalName,
    required this.nickname,
    required this.content,
    required this.rating,
  });

  factory LatestReviewData.fromJson(Map<String, dynamic> json) {
    return LatestReviewData(
      reviewId: json['reviewId'] ?? 0,
      hospitalName: json['hospitalName'] ?? '',
      nickname: json['nickname'] ?? '',
      content: json['content'] ?? '',
      rating: json['rating'] ?? 0,
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

  // 병원 상세 + 리뷰 목록 — GET /api/reviews/hospitals/{ykiho}?page=&size=
  // 로그인 시 Authorization 헤더 포함 → myReviewExists 응답에 포함됨
  static Future<HospitalDetailData> getHospitalDetail(
    String ykiho, {
    int page = 0,
    int size = 10,
  }) async {
    final token = await AuthService.getAccessToken();
    final encodedYkiho = Uri.encodeComponent(ykiho);
    final uri = Uri.parse('$_baseUrl/api/reviews/hospitals/$encodedYkiho')
        .replace(queryParameters: {'page': '$page', 'size': '$size'});

    final headers = <String, String>{};
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    final response = await http
        .get(uri, headers: headers)
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final decoded = utf8.decode(response.bodyBytes);
      final json = jsonDecode(decoded);
      return HospitalDetailData.fromJson(
          json['data'] as Map<String, dynamic>);
    }
    debugPrint('HOSPITAL_DETAIL HTTP ${response.statusCode}: ${response.body}');
    throw Exception('HTTP ${response.statusCode}');
  }

  // 영수증 OCR 인증 — POST /api/reviews/ocr (multipart: receiptImage, ykiho)
  // 성공 시 서버가 Redis에 10분간 인증 상태 저장
  // 401 수신 시 토큰 갱신 후 1회 재시도
  static Future<bool> verifyReceipt(String ykiho, String imagePath) async {
    String? token = await AuthService.getAccessToken();
    debugPrint('VERIFY_RECEIPT token=${token != null ? "exists(${token.length}chars)" : "NULL"}');
    if (token == null || token.isEmpty) throw Exception('not_logged_in');

    Future<http.Response> _doRequest(String t) async {
      final uri = Uri.parse('$_baseUrl/api/reviews/ocr');
      final request = http.MultipartRequest('POST', uri)
        ..headers['Authorization'] = 'Bearer $t'
        ..fields['ykiho'] = ykiho
        ..files.add(await http.MultipartFile.fromPath('receiptImage', imagePath));
      final streamed = await request.send().timeout(const Duration(seconds: 30));
      return http.Response.fromStream(streamed);
    }

    var response = await _doRequest(token);
    debugPrint('VERIFY_RECEIPT first attempt: ${response.statusCode}');

    // Access Token 만료 시 갱신 후 재시도
    if (response.statusCode == 401) {
      debugPrint('VERIFY_RECEIPT 401 → attempting token refresh');
      final newToken = await AuthService.refreshAccessToken();
      debugPrint('VERIFY_RECEIPT refresh result: ${newToken != null ? "success" : "FAILED"}');
      if (newToken == null) throw Exception('not_logged_in');
      response = await _doRequest(newToken);
      debugPrint('VERIFY_RECEIPT retry: ${response.statusCode}');
    }

    if (response.statusCode == 200) return true;
    debugPrint('VERIFY_RECEIPT HTTP ${response.statusCode}: ${response.body}');
    return false;
  }

  // 리뷰 등록 — POST /api/reviews (multipart: ykiho, rating, content?, images?)
  // OCR 인증 완료(Redis) 후 호출해야 하며, 이미지 최대 5장
  // 401 수신 시 토큰 갱신 후 1회 재시도
  static Future<void> submitReview({
    required String ykiho,
    required int rating,
    String? content,
    List<String> imagePaths = const [],
  }) async {
    String? token = await AuthService.getAccessToken();
    if (token == null || token.isEmpty) throw Exception('not_logged_in');

    Future<http.Response> _doRequest(String t) async {
      final uri = Uri.parse('$_baseUrl/api/reviews');
      final request = http.MultipartRequest('POST', uri)
        ..headers['Authorization'] = 'Bearer $t'
        ..fields['ykiho'] = ykiho
        ..fields['rating'] = rating.toString();

      if (content != null && content.isNotEmpty) {
        request.fields['content'] = content;
      }

      for (final path in imagePaths) {
        request.files.add(await http.MultipartFile.fromPath('images', path));
      }

      final streamed = await request.send().timeout(const Duration(seconds: 30));
      return http.Response.fromStream(streamed);
    }

    var response = await _doRequest(token);

    // Access Token 만료 시 갱신 후 재시도
    if (response.statusCode == 401) {
      final newToken = await AuthService.refreshAccessToken();
      if (newToken == null) throw Exception('not_logged_in');
      response = await _doRequest(newToken);
    }

    if (response.statusCode == 200 || response.statusCode == 201) return;

    final decoded = utf8.decode(response.bodyBytes);
    debugPrint('SUBMIT_REVIEW HTTP ${response.statusCode}: $decoded');

    // 중복 리뷰 등록 시도 (409)
    if (response.statusCode == 409) throw Exception('duplicate_review');
    throw Exception('HTTP ${response.statusCode}');
  }

  // 메인화면 최신 리뷰 N건 조회 — GET /api/reviews/latest?size=N (게스트 허용)
  static Future<List<LatestReviewData>> getLatestReviews({int size = 2}) async {
    try {
      final uri = Uri.parse('$_baseUrl/api/reviews/latest')
          .replace(queryParameters: {'size': '$size'});

      final response = await http.get(uri).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final decoded = utf8.decode(response.bodyBytes);
        final json = jsonDecode(decoded);
        final List list = (json['data'] ?? []) as List;
        return list
            .map((e) => LatestReviewData.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      debugPrint('GET_LATEST_REVIEWS HTTP ${response.statusCode}: ${response.body}');
      return [];
    } catch (e) {
      debugPrint('GET_LATEST_REVIEWS ERROR: $e');
      return [];
    }
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