import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import 'package:healyx_app/services/auth_service.dart';

class CommunityService {
  static const String baseUrl = 'https://jwejweiya.com';

  String _bearerToken(String token) {
    if (token.startsWith('Bearer ')) {
      return token;
    }
    return 'Bearer $token';
  }

  String _parseErrorMessage({
    required String responseBody,
    required String defaultMessage,
  }) {
    try {
      final decoded = jsonDecode(responseBody);

      if (decoded is Map<String, dynamic>) {
        return decoded['message'] ?? decoded['errorCode'] ?? defaultMessage;
      }
    } catch (_) {
      if (responseBody.isNotEmpty) {
        return responseBody;
      }
    }

    return defaultMessage;
  }

  Future<String> _getValidAccessToken() async {
    final token = await AuthService.getAccessToken();

    if (token == null || token.isEmpty) {
      throw Exception('로그인이 필요한 기능입니다.');
    }

    return token;
  }

  Future<http.Response> _retryGetWithRefresh({
    required Uri uri,
    required String token,
    Map<String, String>? extraHeaders,
  }) async {
    Map<String, String> buildHeaders(String accessToken) {
      return {
        'Authorization': _bearerToken(accessToken),
        'Accept': 'application/json',
        ...?extraHeaders,
      };
    }

    http.Response response = await http.get(
      uri,
      headers: buildHeaders(token),
    );

    if (response.statusCode == 401) {
      debugPrint('[Community] get accessToken expired. Trying refresh.');

      final String? newToken = await AuthService.refreshAccessToken();

      if (newToken == null || newToken.isEmpty) {
        throw Exception('로그인이 만료되었습니다. 다시 로그인해주세요.');
      }

      response = await http.get(
        uri,
        headers: buildHeaders(newToken),
      );
    }

    return response;
  }

  Future<http.Response> _retryPostWithRefresh({
    required Uri uri,
    required String token,
  }) async {
    http.Response response = await http.post(
      uri,
      headers: {
        'Authorization': _bearerToken(token),
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 401) {
      debugPrint('[Community] accessToken expired or invalid. Trying refresh.');

      final String? newToken = await AuthService.refreshAccessToken();

      if (newToken == null || newToken.isEmpty) {
        throw Exception('로그인이 만료되었습니다. 다시 로그인해주세요.');
      }

      response = await http.post(
        uri,
        headers: {
          'Authorization': _bearerToken(newToken),
          'Accept': 'application/json',
        },
      );
    }

    return response;
  }

  Future<http.Response> _retryJsonPostWithRefresh({
    required Uri uri,
    required String token,
    required Map<String, dynamic> body,
    Map<String, String>? extraHeaders,
  }) async {
    Map<String, String> buildHeaders(String accessToken) {
      return {
        'Authorization': _bearerToken(accessToken),
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        ...?extraHeaders,
      };
    }

    http.Response response = await http.post(
      uri,
      headers: buildHeaders(token),
      body: jsonEncode(body),
    );

    if (response.statusCode == 401) {
      debugPrint('[Community] json post accessToken expired. Trying refresh.');

      final String? newToken = await AuthService.refreshAccessToken();

      if (newToken == null || newToken.isEmpty) {
        throw Exception('로그인이 만료되었습니다. 다시 로그인해주세요.');
      }

      response = await http.post(
        uri,
        headers: buildHeaders(newToken),
        body: jsonEncode(body),
      );
    }

    return response;
  }

  Future<http.Response> _retryDeleteWithRefresh({
    required Uri uri,
    required String token,
  }) async {
    http.Response response = await http.delete(
      uri,
      headers: {
        'Authorization': _bearerToken(token),
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 401) {
      debugPrint('[Community] delete accessToken expired. Trying refresh.');

      final String? newToken = await AuthService.refreshAccessToken();

      if (newToken == null || newToken.isEmpty) {
        throw Exception('로그인이 만료되었습니다. 다시 로그인해주세요.');
      }

      response = await http.delete(
        uri,
        headers: {
          'Authorization': _bearerToken(newToken),
          'Accept': 'application/json',
        },
      );
    }

    return response;
  }

  // =========================
  // 게시글 등록 API
  // POST /api/community/posts
  // multipart/form-data
  // =========================
  Future<http.Response> _sendCreatePostRequest({
    required String token,
    required String title,
    required String content,
    required List<XFile> images,
  }) async {
    final uri = Uri.parse('$baseUrl/api/community/posts');

    final request = http.MultipartRequest('POST', uri);

    request.headers.addAll({
      'Authorization': _bearerToken(token),
      'Accept': 'application/json',
    });

    request.fields['title'] = title;
    request.fields['content'] = content;

    for (final image in images) {
      request.files.add(
        await http.MultipartFile.fromPath(
          'images',
          image.path,
        ),
      );
    }

    final streamedResponse = await request.send();
    return http.Response.fromStream(streamedResponse);
  }

  Future<void> createPost({
    required String title,
    required String content,
    required List<XFile> images,
  }) async {
    String? token = await AuthService.getAccessToken();

    if (token == null || token.isEmpty) {
      throw Exception('로그인이 필요한 기능입니다.');
    }

    http.Response response = await _sendCreatePostRequest(
      token: token,
      title: title,
      content: content,
      images: images,
    );

    if (response.statusCode == 401) {
      debugPrint('[Community] createPost accessToken expired. Trying refresh.');

      final String? newToken = await AuthService.refreshAccessToken();

      if (newToken == null || newToken.isEmpty) {
        throw Exception('로그인이 만료되었습니다. 다시 로그인해주세요.');
      }

      response = await _sendCreatePostRequest(
        token: newToken,
        title: title,
        content: content,
        images: images,
      );
    }

    final responseBody = utf8.decode(response.bodyBytes);

    debugPrint('[Community] createPost status: ${response.statusCode}');
    debugPrint('[Community] createPost body: $responseBody');

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (responseBody.isEmpty) return;

      try {
        final decoded = jsonDecode(responseBody);

        if (decoded is Map<String, dynamic> && decoded['success'] == false) {
          throw Exception(decoded['message'] ?? '게시글 등록에 실패했습니다.');
        }
      } on FormatException {
        return;
      }

      return;
    }

    final errorMessage = _parseErrorMessage(
      responseBody: responseBody,
      defaultMessage: '게시글 등록에 실패했습니다.',
    );

    throw Exception('$errorMessage (${response.statusCode})');
  }

  // =========================
  // 게시글 수정 API
  // PUT /api/community/posts/{postId}
  // multipart/form-data
  // 본인 게시글만 수정 가능
  // 이미지 전체 교체 방식
  // =========================
  Future<http.Response> _sendUpdatePostRequest({
    required String token,
    required int postId,
    required String title,
    required String content,
    required List<XFile> images,
  }) async {
    final uri = Uri.parse('$baseUrl/api/community/posts/$postId');

    final request = http.MultipartRequest('PUT', uri);

    request.headers.addAll({
      'Authorization': _bearerToken(token),
      'Accept': 'application/json',
    });

    request.fields['title'] = title;
    request.fields['content'] = content;

    for (final image in images) {
      request.files.add(
        await http.MultipartFile.fromPath(
          'images',
          image.path,
        ),
      );
    }

    final streamedResponse = await request.send();
    return http.Response.fromStream(streamedResponse);
  }

  Future<void> updatePost({
    required int postId,
    required String title,
    required String content,
    required List<XFile> images,
  }) async {
    String? token = await AuthService.getAccessToken();

    if (token == null || token.isEmpty) {
      throw Exception('로그인이 필요한 기능입니다.');
    }

    http.Response response = await _sendUpdatePostRequest(
      token: token,
      postId: postId,
      title: title,
      content: content,
      images: images,
    );

    if (response.statusCode == 401) {
      debugPrint('[Community] updatePost accessToken expired. Trying refresh.');

      final String? newToken = await AuthService.refreshAccessToken();

      if (newToken == null || newToken.isEmpty) {
        throw Exception('로그인이 만료되었습니다. 다시 로그인해주세요.');
      }

      response = await _sendUpdatePostRequest(
        token: newToken,
        postId: postId,
        title: title,
        content: content,
        images: images,
      );
    }

    final responseBody = utf8.decode(response.bodyBytes);

    debugPrint('[Community] updatePost status: ${response.statusCode}');
    debugPrint('[Community] updatePost body: $responseBody');

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (responseBody.isEmpty) return;

      try {
        final decoded = jsonDecode(responseBody);

        if (decoded is Map<String, dynamic> && decoded['success'] == false) {
          throw Exception(decoded['message'] ?? '게시글 수정에 실패했습니다.');
        }
      } on FormatException {
        return;
      }

      return;
    }

    final errorMessage = _parseErrorMessage(
      responseBody: responseBody,
      defaultMessage: '게시글 수정에 실패했습니다.',
    );

    throw Exception('$errorMessage (${response.statusCode})');
  }

  // =========================
  // 게시글 목록 / 검색 조회 API
  // GET /api/community/posts
  // =========================
  Future<CommunityPostPage> getPosts({
    int page = 0,
    int size = 10,
    String sort = 'latest',
    String? keyword,
    String searchField = 'all',
  }) async {
    final queryParameters = <String, String>{
      'page': page.toString(),
      'size': size.toString(),
      'sort': sort,
    };

    if (keyword != null && keyword.trim().isNotEmpty) {
      queryParameters['keyword'] = keyword.trim();
      queryParameters['searchField'] = searchField;
    }

    final uri = Uri.parse('$baseUrl/api/community/posts').replace(
      queryParameters: queryParameters,
    );

    final response = await http.get(
      uri,
      headers: {
        'Accept': 'application/json',
      },
    );

    final responseBody = utf8.decode(response.bodyBytes);

    debugPrint('[Community] getPosts status: ${response.statusCode}');
    debugPrint('[Community] getPosts body: $responseBody');

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final decoded = jsonDecode(responseBody);

      if (decoded is Map<String, dynamic> && decoded['success'] == true) {
        return CommunityPostPage.fromJson(decoded['data']);
      }

      throw Exception(
        decoded is Map<String, dynamic>
            ? decoded['message'] ?? '게시글 목록 조회에 실패했습니다.'
            : '게시글 목록 조회에 실패했습니다.',
      );
    }

    final errorMessage = _parseErrorMessage(
      responseBody: responseBody,
      defaultMessage: '게시글 목록 조회에 실패했습니다.',
    );

    throw Exception('$errorMessage (${response.statusCode})');
  }

  // =========================
  // 게시글 상세 조회 API
  // GET /api/community/posts/{postId}
  // =========================
  Future<CommunityPostDetail> getPostDetail({
    required int postId,
  }) async {
    final uri = Uri.parse('$baseUrl/api/community/posts/$postId');

    final token = await AuthService.getAccessToken();

    final headers = <String, String>{
      'Accept': 'application/json',
    };

    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = _bearerToken(token);
    }

    http.Response response = await http.get(
      uri,
      headers: headers,
    );

    if (response.statusCode == 401 && token != null && token.isNotEmpty) {
      debugPrint('[Community] detail accessToken expired. Trying refresh.');

      final String? newToken = await AuthService.refreshAccessToken();

      if (newToken != null && newToken.isNotEmpty) {
        response = await http.get(
          uri,
          headers: {
            'Accept': 'application/json',
            'Authorization': _bearerToken(newToken),
          },
        );
      }
    }

    final responseBody = utf8.decode(response.bodyBytes);

    debugPrint('[Community] getPostDetail status: ${response.statusCode}');
    debugPrint('[Community] getPostDetail body: $responseBody');

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final decoded = jsonDecode(responseBody);

      if (decoded is Map<String, dynamic> && decoded['success'] == true) {
        return CommunityPostDetail.fromJson(decoded['data']);
      }

      throw Exception(
        decoded is Map<String, dynamic>
            ? decoded['message'] ?? '게시글 상세 조회에 실패했습니다.'
            : '게시글 상세 조회에 실패했습니다.',
      );
    }

    final errorMessage = _parseErrorMessage(
      responseBody: responseBody,
      defaultMessage: '게시글 상세 조회에 실패했습니다.',
    );

    throw Exception('$errorMessage (${response.statusCode})');
  }

  // =========================
  // 좋아요 토글 API
  // POST /api/community/posts/{postId}/likes
  // 좋아요가 없으면 추가, 이미 있으면 취소
  // =========================
  Future<LikeToggleResult> toggleLike({
    required int postId,
  }) async {
    final token = await _getValidAccessToken();

    final uri = Uri.parse('$baseUrl/api/community/posts/$postId/likes');

    final response = await _retryPostWithRefresh(
      uri: uri,
      token: token,
    );

    final responseBody = utf8.decode(response.bodyBytes);

    debugPrint('[Community] toggleLike status: ${response.statusCode}');
    debugPrint('[Community] toggleLike body: $responseBody');

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final decoded = jsonDecode(responseBody);

      if (decoded is Map<String, dynamic> && decoded['success'] == true) {
        return LikeToggleResult.fromJson(decoded['data']);
      }

      throw Exception(
        decoded is Map<String, dynamic>
            ? decoded['message'] ?? '좋아요 처리에 실패했습니다.'
            : '좋아요 처리에 실패했습니다.',
      );
    }

    final errorMessage = _parseErrorMessage(
      responseBody: responseBody,
      defaultMessage: '좋아요 처리에 실패했습니다.',
    );

    throw Exception('$errorMessage (${response.statusCode})');
  }

  // =========================
  // 북마크 토글 API
  // POST /api/community/posts/{postId}/bookmarks
  // 북마크가 없으면 추가, 이미 있으면 취소
  // =========================
  Future<BookmarkToggleResult> toggleBookmark({
    required int postId,
  }) async {
    final token = await _getValidAccessToken();

    final uri = Uri.parse('$baseUrl/api/community/posts/$postId/bookmarks');

    final response = await _retryPostWithRefresh(
      uri: uri,
      token: token,
    );

    final responseBody = utf8.decode(response.bodyBytes);

    debugPrint('[Community] toggleBookmark status: ${response.statusCode}');
    debugPrint('[Community] toggleBookmark body: $responseBody');

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final decoded = jsonDecode(responseBody);

      if (decoded is Map<String, dynamic> && decoded['success'] == true) {
        return BookmarkToggleResult.fromJson(decoded['data']);
      }

      throw Exception(
        decoded is Map<String, dynamic>
            ? decoded['message'] ?? '북마크 처리에 실패했습니다.'
            : '북마크 처리에 실패했습니다.',
      );
    }

    final errorMessage = _parseErrorMessage(
      responseBody: responseBody,
      defaultMessage: '북마크 처리에 실패했습니다.',
    );

    throw Exception('$errorMessage (${response.statusCode})');
  }

  // =========================
  // 게시글 삭제 API
  // DELETE /api/community/posts/{postId}
  // 본인 게시글만 삭제 가능
  // =========================
  Future<void> deletePost({
    required int postId,
  }) async {
    final token = await _getValidAccessToken();

    final uri = Uri.parse('$baseUrl/api/community/posts/$postId');

    final response = await _retryDeleteWithRefresh(
      uri: uri,
      token: token,
    );

    final responseBody = utf8.decode(response.bodyBytes);

    debugPrint('[Community] deletePost status: ${response.statusCode}');
    debugPrint('[Community] deletePost body: $responseBody');

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (responseBody.isEmpty) return;

      try {
        final decoded = jsonDecode(responseBody);

        if (decoded is Map<String, dynamic> && decoded['success'] == false) {
          throw Exception(decoded['message'] ?? '게시글 삭제에 실패했습니다.');
        }
      } on FormatException {
        return;
      }

      return;
    }

    final errorMessage = _parseErrorMessage(
      responseBody: responseBody,
      defaultMessage: '게시글 삭제에 실패했습니다.',
    );

    throw Exception('$errorMessage (${response.statusCode})');
  }

  // =========================
  // 댓글 작성 API
  // POST /api/community/posts/{postId}/comments
  // parentCommentId가 있으면 대댓글
  // =========================
  Future<void> createComment({
    required int postId,
    required String content,
    int? parentCommentId,
    int? mentionUserId,
  }) async {
    final token = await _getValidAccessToken();

    final uri = Uri.parse('$baseUrl/api/community/posts/$postId/comments');

    final body = <String, dynamic>{
      'content': content,
    };

    if (parentCommentId != null) {
      body['parentCommentId'] = parentCommentId;
    }

    if (mentionUserId != null) {
      body['mentionUserId'] = mentionUserId;
    }

    final response = await _retryJsonPostWithRefresh(
      uri: uri,
      token: token,
      body: body,
    );

    final responseBody = utf8.decode(response.bodyBytes);

    debugPrint('[Community] createComment status: ${response.statusCode}');
    debugPrint('[Community] createComment body: $responseBody');

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (responseBody.isEmpty) return;

      try {
        final decoded = jsonDecode(responseBody);

        if (decoded is Map<String, dynamic> && decoded['success'] == false) {
          throw Exception(decoded['message'] ?? '댓글 등록에 실패했습니다.');
        }
      } on FormatException {
        return;
      }

      return;
    }

    final errorMessage = _parseErrorMessage(
      responseBody: responseBody,
      defaultMessage: '댓글 등록에 실패했습니다.',
    );

    throw Exception('$errorMessage (${response.statusCode})');
  }

  // =========================
  // 댓글 삭제 API
  // DELETE /api/community/comments/{commentId}
  // 상세 화면에서 내가 쓴 댓글 삭제 시 사용
  // =========================
  Future<void> deleteComment({
    required int commentId,
  }) async {
    final token = await _getValidAccessToken();

    final uri = Uri.parse('$baseUrl/api/community/comments/$commentId');

    final response = await _retryDeleteWithRefresh(
      uri: uri,
      token: token,
    );

    final responseBody = utf8.decode(response.bodyBytes);

    debugPrint('[Community] deleteComment status: ${response.statusCode}');
    debugPrint('[Community] deleteComment body: $responseBody');

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (responseBody.isEmpty) return;

      try {
        final decoded = jsonDecode(responseBody);

        if (decoded is Map<String, dynamic> && decoded['success'] == false) {
          throw Exception(decoded['message'] ?? '댓글 삭제에 실패했습니다.');
        }
      } on FormatException {
        return;
      }

      return;
    }

    final errorMessage = _parseErrorMessage(
      responseBody: responseBody,
      defaultMessage: '댓글 삭제에 실패했습니다.',
    );

    throw Exception('$errorMessage (${response.statusCode})');
  }

  // =========================
  // 내 게시글 목록 조회 API
  // GET /api/community/my/posts
  // =========================
  Future<List<MyCommunityPost>> getMyPosts({
    String acceptLanguage = 'ko',
  }) async {
    final token = await _getValidAccessToken();

    final uri = Uri.parse('$baseUrl/api/community/my/posts');

    final response = await _retryGetWithRefresh(
      uri: uri,
      token: token,
      extraHeaders: {
        'Accept-Language': acceptLanguage,
      },
    );

    final responseBody = utf8.decode(response.bodyBytes);

    debugPrint('[Community] getMyPosts status: ${response.statusCode}');
    debugPrint('[Community] getMyPosts body: $responseBody');

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final decoded = jsonDecode(responseBody);

      if (decoded is Map<String, dynamic> && decoded['success'] == true) {
        final data = decoded['data'];

        if (data is List) {
          return data
              .whereType<Map<String, dynamic>>()
              .map((item) => MyCommunityPost.fromJson(item))
              .toList();
        }

        return [];
      }

      throw Exception(
        decoded is Map<String, dynamic>
            ? decoded['message'] ?? '내 게시글 목록 조회에 실패했습니다.'
            : '내 게시글 목록 조회에 실패했습니다.',
      );
    }

    final errorMessage = _parseErrorMessage(
      responseBody: responseBody,
      defaultMessage: '내 게시글 목록 조회에 실패했습니다.',
    );

    throw Exception('$errorMessage (${response.statusCode})');
  }

  // =========================
  // 내 댓글 목록 조회 API
  // GET /api/community/my/comments
  // =========================
  Future<List<MyCommunityComment>> getMyComments({
    String acceptLanguage = 'ko',
  }) async {
    final token = await _getValidAccessToken();

    final uri = Uri.parse('$baseUrl/api/community/my/comments');

    final response = await _retryGetWithRefresh(
      uri: uri,
      token: token,
      extraHeaders: {
        'Accept-Language': acceptLanguage,
      },
    );

    final responseBody = utf8.decode(response.bodyBytes);

    debugPrint('[Community] getMyComments status: ${response.statusCode}');
    debugPrint('[Community] getMyComments body: $responseBody');

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final decoded = jsonDecode(responseBody);

      if (decoded is Map<String, dynamic> && decoded['success'] == true) {
        final data = decoded['data'];

        if (data is List) {
          return data
              .whereType<Map<String, dynamic>>()
              .map((item) => MyCommunityComment.fromJson(item))
              .toList();
        }

        return [];
      }

      throw Exception(
        decoded is Map<String, dynamic>
            ? decoded['message'] ?? '내 댓글 목록 조회에 실패했습니다.'
            : '내 댓글 목록 조회에 실패했습니다.',
      );
    }

    final errorMessage = _parseErrorMessage(
      responseBody: responseBody,
      defaultMessage: '내 댓글 목록 조회에 실패했습니다.',
    );

    throw Exception('$errorMessage (${response.statusCode})');
  }

  // =========================
  // 내 댓글 삭제 API
  // DELETE /api/community/my/comments/{commentId}
  // 보관함 > 내 댓글 목록에서 삭제 시 사용
  // =========================
  Future<void> deleteMyComment({
    required int commentId,
  }) async {
    final token = await _getValidAccessToken();

    final uri = Uri.parse('$baseUrl/api/community/my/comments/$commentId');

    final response = await _retryDeleteWithRefresh(
      uri: uri,
      token: token,
    );

    final responseBody = utf8.decode(response.bodyBytes);

    debugPrint('[Community] deleteMyComment status: ${response.statusCode}');
    debugPrint('[Community] deleteMyComment body: $responseBody');

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (responseBody.isEmpty) return;

      try {
        final decoded = jsonDecode(responseBody);

        if (decoded is Map<String, dynamic> && decoded['success'] == false) {
          throw Exception(decoded['message'] ?? '내 댓글 삭제에 실패했습니다.');
        }
      } on FormatException {
        return;
      }

      return;
    }

    final errorMessage = _parseErrorMessage(
      responseBody: responseBody,
      defaultMessage: '내 댓글 삭제에 실패했습니다.',
    );

    throw Exception('$errorMessage (${response.statusCode})');
  }

  // =========================
  // 신고 API
  // POST /api/community/reports
  // 게시글 또는 댓글 신고
  // 현재 앱에서는 게시글 신고만 사용
  // =========================
  Future<void> reportContent({
    required String targetType,
    required int targetId,
    required String reason,
    String acceptLanguage = 'ko',
  }) async {
    final token = await _getValidAccessToken();

    final uri = Uri.parse('$baseUrl/api/community/reports');

    final response = await _retryJsonPostWithRefresh(
      uri: uri,
      token: token,
      body: {
        'targetType': targetType,
        'targetId': targetId,
        'reason': reason,
      },
      extraHeaders: {
        'Accept-Language': acceptLanguage,
      },
    );

    final responseBody = utf8.decode(response.bodyBytes);

    debugPrint('[Community] reportContent status: ${response.statusCode}');
    debugPrint('[Community] reportContent body: $responseBody');

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (responseBody.isEmpty) return;

      try {
        final decoded = jsonDecode(responseBody);

        if (decoded is Map<String, dynamic> && decoded['success'] == false) {
          throw Exception(decoded['message'] ?? '신고 접수에 실패했습니다.');
        }
      } on FormatException {
        return;
      }

      return;
    }

    final errorMessage = _parseErrorMessage(
      responseBody: responseBody,
      defaultMessage: '신고 접수에 실패했습니다.',
    );

    throw Exception('$errorMessage (${response.statusCode})');
  }
}

// =========================
// 게시글 목록 페이지 모델
// =========================
class CommunityPostPage {
  final int totalElements;
  final int totalPages;
  final bool first;
  final bool last;
  final int size;
  final int number;
  final int numberOfElements;
  final bool empty;
  final List<CommunityPostSummary> content;

  CommunityPostPage({
    required this.totalElements,
    required this.totalPages,
    required this.first,
    required this.last,
    required this.size,
    required this.number,
    required this.numberOfElements,
    required this.empty,
    required this.content,
  });

  factory CommunityPostPage.fromJson(Map<String, dynamic> json) {
    final List<dynamic> contentJson = json['content'] ?? [];

    return CommunityPostPage(
      totalElements: json['totalElements'] ?? 0,
      totalPages: json['totalPages'] ?? 0,
      first: json['first'] ?? true,
      last: json['last'] ?? true,
      size: json['size'] ?? 0,
      number: json['number'] ?? 0,
      numberOfElements: json['numberOfElements'] ?? 0,
      empty: json['empty'] ?? true,
      content: contentJson
          .map(
            (item) => CommunityPostSummary.fromJson(
          item as Map<String, dynamic>,
        ),
      )
          .toList(),
    );
  }
}

// =========================
// 게시글 목록 카드용 모델
// =========================
class CommunityPostSummary {
  final int postId;
  final String title;
  final String contentPreview;
  final String authorNickname;
  final int likeCount;
  final int commentCount;
  final String createdAt;

  CommunityPostSummary({
    required this.postId,
    required this.title,
    required this.contentPreview,
    required this.authorNickname,
    required this.likeCount,
    required this.commentCount,
    required this.createdAt,
  });

  factory CommunityPostSummary.fromJson(Map<String, dynamic> json) {
    return CommunityPostSummary(
      postId: json['postId'] ?? 0,
      title: json['title'] ?? '',
      contentPreview: json['contentPreview'] ?? '',
      authorNickname: json['authorNickname'] ?? '',
      likeCount: json['likeCount'] ?? 0,
      commentCount: json['commentCount'] ?? 0,
      createdAt: json['createdAt'] ?? '',
    );
  }
}

// =========================
// 게시글 상세 모델
// =========================
class CommunityPostDetail {
  final int postId;
  final int authorId;
  final String authorNickname;
  final String title;
  final String content;
  final int likeCount;
  final int viewCount;
  final String createdAt;
  final String updatedAt;
  final List<String> imageUrls;
  final bool myLikeExists;
  final bool myBookmarkExists;

  // 부모 댓글 목록
  // 대댓글은 각 CommunityComment의 replies 안에 유지됨
  final List<CommunityComment> comments;

  final bool blinded;

  CommunityPostDetail({
    required this.postId,
    required this.authorId,
    required this.authorNickname,
    required this.title,
    required this.content,
    required this.likeCount,
    required this.viewCount,
    required this.createdAt,
    required this.updatedAt,
    required this.imageUrls,
    required this.myLikeExists,
    required this.myBookmarkExists,
    required this.comments,
    required this.blinded,
  });

  int get totalCommentCount {
    int count = 0;

    for (final comment in comments) {
      count += comment.totalCount;
    }

    return count;
  }

  factory CommunityPostDetail.fromJson(Map<String, dynamic> json) {
    final List<dynamic> imageJson = json['imageUrls'] ?? [];
    final List<dynamic> commentJson = json['comments'] ?? [];

    return CommunityPostDetail(
      postId: json['postId'] ?? 0,
      authorId: json['authorId'] ?? 0,
      authorNickname: json['authorNickname'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      likeCount: json['likeCount'] ?? 0,
      viewCount: json['viewCount'] ?? 0,
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
      imageUrls: imageJson.map((item) => item.toString()).toList(),
      myLikeExists: json['myLikeExists'] ?? false,
      myBookmarkExists: json['myBookmarkExists'] ?? false,
      comments: commentJson
          .whereType<Map<String, dynamic>>()
          .map((item) => CommunityComment.fromJson(item))
          .toList(),
      blinded: json['blinded'] ?? false,
    );
  }
}

// =========================
// 댓글 모델
// =========================
class CommunityComment {
  final int commentId;
  final int authorId;
  final String authorNickname;
  final String content;
  final int depth;
  final int? parentCommentId;
  final int? mentionUserId;
  final String createdAt;
  final bool deleted;

  // 상세 조회 응답에서 대댓글은 부모 댓글의 replies 배열 안에 내려옴
  final List<CommunityComment> replies;

  CommunityComment({
    required this.commentId,
    required this.authorId,
    required this.authorNickname,
    required this.content,
    required this.depth,
    required this.parentCommentId,
    required this.mentionUserId,
    required this.createdAt,
    required this.deleted,
    required this.replies,
  });

  int get totalCount {
    int count = 1;

    for (final reply in replies) {
      count += reply.totalCount;
    }

    return count;
  }

  factory CommunityComment.fromJson(Map<String, dynamic> json) {
    final List<dynamic> repliesJson = json['replies'] ?? [];

    return CommunityComment(
      commentId: json['commentId'] ?? 0,
      authorId: json['authorId'] ?? 0,
      authorNickname: json['authorNickname'] ?? '',
      content: json['content'] ?? '',
      depth: json['depth'] ?? 0,
      parentCommentId: json['parentCommentId'],
      mentionUserId: json['mentionUserId'],
      createdAt: json['createdAt'] ?? '',
      deleted: json['deleted'] ?? false,
      replies: repliesJson
          .whereType<Map<String, dynamic>>()
          .map((item) => CommunityComment.fromJson(item))
          .toList(),
    );
  }
}

// =========================
// 내 게시글 모델
// GET /api/community/my/posts
// =========================
class MyCommunityPost {
  final int postId;
  final String title;
  final String contentPreview;
  final int likeCount;
  final String createdAt;

  MyCommunityPost({
    required this.postId,
    required this.title,
    required this.contentPreview,
    required this.likeCount,
    required this.createdAt,
  });

  factory MyCommunityPost.fromJson(Map<String, dynamic> json) {
    return MyCommunityPost(
      postId: json['postId'] ?? 0,
      title: json['title'] ?? '',
      contentPreview: json['contentPreview'] ?? '',
      likeCount: json['likeCount'] ?? 0,
      createdAt: json['createdAt'] ?? '',
    );
  }
}

// =========================
// 내 댓글 모델
// GET /api/community/my/comments
// =========================
class MyCommunityComment {
  final int commentId;
  final int postId;
  final String postTitle;
  final String content;
  final String createdAt;

  MyCommunityComment({
    required this.commentId,
    required this.postId,
    required this.postTitle,
    required this.content,
    required this.createdAt,
  });

  factory MyCommunityComment.fromJson(Map<String, dynamic> json) {
    return MyCommunityComment(
      commentId: json['commentId'] ?? 0,
      postId: json['postId'] ?? 0,
      postTitle: json['postTitle'] ?? '',
      content: json['content'] ?? '',
      createdAt: json['createdAt'] ?? '',
    );
  }
}

// =========================
// 좋아요 토글 결과 모델
// =========================
class LikeToggleResult {
  final bool liked;
  final int likeCount;

  LikeToggleResult({
    required this.liked,
    required this.likeCount,
  });

  factory LikeToggleResult.fromJson(Map<String, dynamic>? json) {
    return LikeToggleResult(
      liked: json?['liked'] ?? false,
      likeCount: json?['likeCount'] ?? 0,
    );
  }
}

// =========================
// 북마크 토글 결과 모델
// =========================
class BookmarkToggleResult {
  final bool bookmarked;

  BookmarkToggleResult({
    required this.bookmarked,
  });

  factory BookmarkToggleResult.fromJson(Map<String, dynamic>? json) {
    return BookmarkToggleResult(
      bookmarked: json?['bookmarked'] ?? false,
    );
  }
}