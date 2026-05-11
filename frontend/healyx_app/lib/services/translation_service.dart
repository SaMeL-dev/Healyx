// 의료 번역 API 서비스
// POST /api/translations/medical — OCR + DeepL 번역 + 이미지 오버레이 + S3 저장
// GET  /api/translations/archive — 번역 보관함 목록 조회
// DELETE /api/translations/archive/{id} — 번역 보관함 항목 삭제
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

// 번역 요청 결과 모델
class TranslationResult {
  final int? translationId;
  final String translatedImageUrl;       // 로그인 사용자: S3 URL
  final String translatedImageBase64;    // 게스트: Base64 인코딩 이미지
  final String originalText;
  final String translatedText;
  final bool isSaved; // 로그인 사용자는 백엔드에서 자동 저장됨

  TranslationResult({
    this.translationId,
    required this.translatedImageUrl,
    required this.translatedImageBase64,
    required this.originalText,
    required this.translatedText,
    required this.isSaved,
  });

  factory TranslationResult.fromJson(Map<String, dynamic> json) {
    return TranslationResult(
      translationId: json['translationId'],
      translatedImageUrl: json['translatedImageUrl'] ?? '',
      translatedImageBase64: json['translatedImageBase64'] ?? '',
      originalText: json['originalText'] ?? '',
      translatedText: json['translatedText'] ?? '',
      isSaved: json['translationId'] != null,
    );
  }
}

// 번역 보관함 항목 모델
class TranslationArchiveItem {
  final int id;
  final String originalImageUrl;
  final String translatedImageUrl;
  final String originalText;
  final String translatedText;
  final String createdAt;
  final String language;

  TranslationArchiveItem({
    required this.id,
    required this.originalImageUrl,
    required this.translatedImageUrl,
    required this.originalText,
    required this.translatedText,
    required this.createdAt,
    required this.language,
  });

  factory TranslationArchiveItem.fromJson(Map<String, dynamic> json) {
    return TranslationArchiveItem(
      id: json['translationId'],
      // 백엔드 필드명: imageUrl (원본), translatedImageUrl (오버레이)
      originalImageUrl: json['imageUrl'] ?? json['originalImageUrl'] ?? '',
      translatedImageUrl: json['translatedImageUrl'] ?? '',
      originalText: json['originalText'] ?? '',
      translatedText: json['translatedText'] ?? '',
      createdAt: json['createdAt'] ?? '',
      // 백엔드 필드명: targetLanguage
      language: json['targetLanguage'] ?? json['language'] ?? '',
    );
  }

  // 날짜 형식 변환 (ISO → YYYY-MM-DD)
  String get formattedDate {
    try {
      final date = DateTime.parse(createdAt);
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    } catch (_) {
      return createdAt;
    }
  }

  // 언어 코드 → 표시 이름 (대소문자 무관하게 처리)
  String get languageName {
    const names = {
      'ko': '한국어',
      'en': 'English',
      'zh': '中文',
      'ja': '日本語',
      'vi': 'Tiếng Việt',
      'th': 'ภาษาไทย',
    };
    return names[language.toLowerCase()] ?? language;
  }
}

class TranslationService {
  static const String _baseUrl = 'https://jwejweiya.com';

  // 의료 문서 번역 요청 (OCR → DeepL → 이미지 오버레이)
  // 백엔드는 JSON + Base64 이미지 형식을 요구함
  // 로그인 사용자: S3 저장 + translatedImageUrl 반환
  // 게스트: translatedImageBase64 반환
  static Future<TranslationResult?> translateMedicalDocument({
    required String imagePath,
    required String targetLanguage,
  }) async {
    try {
      // 이미지를 Base64로 인코딩
      final imageBytes = await File(imagePath).readAsBytes();
      final imageBase64 = base64Encode(imageBytes);
      debugPrint('[Translation] 이미지 크기: ${(imageBytes.length / 1024).toStringAsFixed(1)} KB');

      final langCode = targetLanguage;
      debugPrint('[Translation] 요청 언어: $langCode');

      final token = await AuthService.getAccessToken();

      // OCR + 번역 + 이미지 오버레이 처리 시간 고려 (최대 90초)
      final response = await http.post(
        Uri.parse('$_baseUrl/api/translations/medical'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null && token.isNotEmpty)
            'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'imageBase64': imageBase64,
          'targetLanguage': langCode,
        }),
      ).timeout(const Duration(seconds: 90));

      debugPrint('[Translation] 응답 상태: ${response.statusCode}');

      if (response.statusCode == 200) {
        final decoded = utf8.decode(response.bodyBytes);
        final json = jsonDecode(decoded);
        final data = json['data'] ?? json;
        return TranslationResult.fromJson(data as Map<String, dynamic>);
      } else {
        // 오류 응답 내용 출력
        debugPrint('[Translation] 오류 응답: ${utf8.decode(response.bodyBytes)}');
        return null;
      }
    } catch (e, stackTrace) {
      debugPrint('[Translation] 예외 발생: $e');
      debugPrint('[Translation] 스택트레이스: $stackTrace');
      return null;
    }
  }

  // 번역 보관함 목록 조회 (로그인 필수)
  static Future<List<TranslationArchiveItem>> getArchive() async {
    try {
      final token = await AuthService.getAccessToken();
      if (token == null || token.isEmpty) return [];

      final response = await http.get(
        Uri.parse('$_baseUrl/api/translations/archive'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final decoded = utf8.decode(response.bodyBytes);
        final json = jsonDecode(decoded);
        final List list = (json['data'] ?? json) as List;
        return list
            .map((e) =>
                TranslationArchiveItem.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  // 번역 보관함 항목 삭제 (S3 이미지 포함 삭제)
  static Future<bool> deleteArchiveItem(int id) async {
    try {
      final token = await AuthService.getAccessToken();
      if (token == null || token.isEmpty) return false;

      final response = await http.delete(
        Uri.parse('$_baseUrl/api/translations/archive/$id'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 15));

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (_) {
      return false;
    }
  }
}
