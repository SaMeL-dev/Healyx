// 커뮤니티 관련 API 서비스
// GET  /api/community/bookmarks          — 북마크 목록 조회
// DELETE /api/community/bookmarks/{postId} — 북마크 삭제
// GET  /api/community/my/posts           — 내 게시글 목록
// GET  /api/community/my/comments        — 내 댓글 목록
// DELETE /api/community/my/posts/{postId}    — 내 게시글 삭제
// DELETE /api/community/my/comments/{commentId} — 내 댓글 삭제

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

// 북마크 항목 모델
class BookmarkData {
  final int postId;
  final String title;
  final String authorNickname;
  final String contentPreview;
  final int likeCount;

  BookmarkData({
    required this.postId,
    required this.title,
    required this.authorNickname,
    required this.contentPreview,
    required this.likeCount,
  });

  factory BookmarkData.fromJson(Map<String, dynamic> json) {
    return BookmarkData(
      postId: json['postId'] ?? 0,
      title: json['title'] ?? '',
      authorNickname: json['author'] ?? json['authorNickname'] ?? json['nickname'] ?? '',
      contentPreview: json['contentPreview'] ?? json['content'] ?? '',
      likeCount: json['likeCount'] ?? 0,
    );
  }
}

// 내 게시글 항목 모델
class MyPostData {
  final int postId;
  final String title;
  final String contentPreview;
  final int likeCount;
  final String createdAt;

  MyPostData({
    required this.postId,
    required this.title,
    required this.contentPreview,
    required this.likeCount,
    required this.createdAt,
  });

  factory MyPostData.fromJson(Map<String, dynamic> json) {
    return MyPostData(
      postId: json['postId'] ?? 0,
      title: json['title'] ?? '',
      contentPreview: json['contentPreview'] ?? json['content'] ?? '',
      likeCount: json['likeCount'] ?? 0,
      createdAt: json['createdAt'] ?? '',
    );
  }
}

// 내 댓글 항목 모델
class MyCommentData {
  final int commentId;
  final String postTitle;
  final String commentPreview;
  final String createdAt;

  MyCommentData({
    required this.commentId,
    required this.postTitle,
    required this.commentPreview,
    required this.createdAt,
  });

  factory MyCommentData.fromJson(Map<String, dynamic> json) {
    return MyCommentData(
      commentId: json['commentId'] ?? 0,
      postTitle: json['postTitle'] ?? '',
      commentPreview: json['commentPreview'] ?? json['content'] ?? '',
      createdAt: json['createdAt'] ?? '',
    );
  }
}

class CommunityService {
  static const String _baseUrl = 'https://jwejweiya.com';

  // 북마크 목록 조회
  static Future<List<BookmarkData>> getBookmarks() async {
    try {
      final token = await AuthService.getAccessToken();
      if (token == null || token.isEmpty) return [];

      final response = await http.get(
        Uri.parse('$_baseUrl/api/community/bookmarks'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final decoded = utf8.decode(response.bodyBytes);
        final json = jsonDecode(decoded);
        final List list = (json['data'] ?? []) as List;
        return list
            .map((e) => BookmarkData.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('GET_BOOKMARKS ERROR: $e');
      return [];
    }
  }

  // 북마크 삭제
  static Future<bool> deleteBookmark(int postId) async {
    try {
      final token = await AuthService.getAccessToken();
      if (token == null || token.isEmpty) return false;

      final response = await http.delete(
        Uri.parse('$_baseUrl/api/community/bookmarks/$postId'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 15));

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      debugPrint('DELETE_BOOKMARK ERROR: $e');
      return false;
    }
  }

  // 내 게시글 목록 조회
  static Future<List<MyPostData>> getMyPosts() async {
    try {
      final token = await AuthService.getAccessToken();
      if (token == null || token.isEmpty) return [];

      final response = await http.get(
        Uri.parse('$_baseUrl/api/community/my/posts'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final decoded = utf8.decode(response.bodyBytes);
        final json = jsonDecode(decoded);
        final List list = (json['data'] ?? []) as List;
        return list
            .map((e) => MyPostData.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('GET_MY_POSTS ERROR: $e');
      return [];
    }
  }

  // 내 게시글 삭제
  static Future<bool> deleteMyPost(int postId) async {
    try {
      final token = await AuthService.getAccessToken();
      if (token == null || token.isEmpty) return false;

      final response = await http.delete(
        Uri.parse('$_baseUrl/api/community/my/posts/$postId'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 15));

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      debugPrint('DELETE_MY_POST ERROR: $e');
      return false;
    }
  }

  // 내 댓글 목록 조회
  static Future<List<MyCommentData>> getMyComments() async {
    try {
      final token = await AuthService.getAccessToken();
      if (token == null || token.isEmpty) return [];

      final response = await http.get(
        Uri.parse('$_baseUrl/api/community/my/comments'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final decoded = utf8.decode(response.bodyBytes);
        final json = jsonDecode(decoded);
        final List list = (json['data'] ?? []) as List;
        return list
            .map((e) => MyCommentData.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('GET_MY_COMMENTS ERROR: $e');
      return [];
    }
  }

  // 내 댓글 삭제
  static Future<bool> deleteMyComment(int commentId) async {
    try {
      final token = await AuthService.getAccessToken();
      if (token == null || token.isEmpty) return false;

      final response = await http.delete(
        Uri.parse('$_baseUrl/api/community/my/comments/$commentId'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 15));

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      debugPrint('DELETE_MY_COMMENT ERROR: $e');
      return false;
    }
  }
}