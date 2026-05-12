// 리뷰 관련 API 서비스
// GET    /api/reviews/my              — 내 리뷰 목록 조회
// DELETE /api/reviews/my/{reviewId}  — 내 리뷰 삭제

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

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