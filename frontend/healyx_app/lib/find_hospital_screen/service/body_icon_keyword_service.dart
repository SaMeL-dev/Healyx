import 'dart:convert';

import 'package:http/http.dart' as http;

class BodyIconKeywordService {
  static const String _baseUrl = 'https://jwejweiya.com';

  static Future<String> fetchKeywords({
    required String iconId,
  }) async {
    final encodedIconId = Uri.encodeComponent(iconId);
    final uri = Uri.parse(
      '$_baseUrl/api/hospitals/body-icons/$encodedIconId/keywords',
    );

    try {
      final response = await http.get(uri);

      final Map<String, dynamic> jsonBody =
      jsonDecode(utf8.decode(response.bodyBytes));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final success = jsonBody['success'] == true;

        if (!success) {
          throw BodyIconKeywordException(
            message: jsonBody['message']?.toString() ?? '아이콘 키워드 조회에 실패했습니다.',
            statusCode: response.statusCode,
          );
        }

        final data = jsonBody['data'];

        if (data is Map<String, dynamic>) {
          final keywords = data['keywords']?.toString();

          if (keywords != null && keywords.trim().isNotEmpty) {
            return keywords.trim();
          }
        }

        throw BodyIconKeywordException(
          message: '아이콘에 연결된 증상 키워드가 없습니다.',
          statusCode: response.statusCode,
        );
      }

      throw BodyIconKeywordException(
        message: jsonBody['message']?.toString() ?? '아이콘 키워드 조회에 실패했습니다.',
        statusCode: response.statusCode,
      );
    } catch (e) {
      if (e is BodyIconKeywordException) {
        rethrow;
      }

      throw BodyIconKeywordException(
        message: '아이콘 키워드 조회 중 오류가 발생했습니다.',
      );
    }
  }

  static Future<String> fetchMultipleKeywords({
    required List<String> iconIds,
  }) async {
    final results = await Future.wait(
      iconIds.map((iconId) => fetchKeywords(iconId: iconId)),
    );

    return results
        .where((keyword) => keyword.trim().isNotEmpty)
        .join(', ');
  }
}

class BodyIconKeywordException implements Exception {
  final String message;
  final int? statusCode;

  BodyIconKeywordException({
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