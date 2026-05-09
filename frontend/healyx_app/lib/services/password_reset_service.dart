import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// API 호출 결과를 화면에서 사용하기 쉽게 담는 클래스
class PasswordResetResult {
  final bool success;
  final String message;

  PasswordResetResult({
    required this.success,
    required this.message,
  });
}

class PasswordResetService {
  /// 예시:
  /// static const String baseUrl = 'http://서버주소';
  /// static const String baseUrl = 'https://서버주소';
  static const String baseUrl = 'https://jwejweiya.com';

  /// 1. 비밀번호 재설정 이메일 인증번호 발송
  ///
  /// POST /api/email/send
  ///
  /// body:
  /// {
  ///   "email": "사용자 이메일",
  ///   "purpose": "reset-pw"
  /// }
  static Future<PasswordResetResult> sendResetPasswordEmailCode({
    required String email,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/api/email/send');

      final response = await http
          .post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'purpose': 'reset-pw',
        }),
      )
          .timeout(const Duration(seconds: 10));

      return _handleResponse(response);
    } on TimeoutException {
      return PasswordResetResult(
        success: false,
        message: '요청 시간이 초과되었습니다. 다시 시도해주세요.',
      );
    } catch (e) {
      return PasswordResetResult(
        success: false,
        message: '인증번호 발송 중 오류가 발생했습니다.',
      );
    }
  }

  /// 2. 비밀번호 재설정 1단계 검증
  ///
  /// POST /api/auth/verify-reset-password
  ///
  /// body:
  /// {
  ///   "username": "사용자 아이디",
  ///   "email": "사용자 이메일",
  ///   "verificationCode": "인증번호"
  /// }
  static Future<PasswordResetResult> verifyResetPassword({
    required String username,
    required String email,
    required String verificationCode,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/api/auth/verify-reset-password');

      final response = await http
          .post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'username': username,
          'email': email,
          'verificationCode': verificationCode,
        }),
      )
          .timeout(const Duration(seconds: 10));

      return _handleResponse(response);
    } on TimeoutException {
      return PasswordResetResult(
        success: false,
        message: '요청 시간이 초과되었습니다. 다시 시도해주세요.',
      );
    } catch (e) {
      return PasswordResetResult(
        success: false,
        message: '본인 인증 중 오류가 발생했습니다.',
      );
    }
  }

  /// 3. 새 비밀번호로 재설정
  ///
  /// PUT /api/auth/reset-password
  ///
  /// body:
  /// {
  ///   "username": "사용자 아이디",
  ///   "newPassword": "새 비밀번호",
  ///   "confirmNewPassword": "새 비밀번호 확인"
  /// }
  static Future<PasswordResetResult> resetPassword({
    required String username,
    required String newPassword,
    required String confirmNewPassword,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/api/auth/reset-password');

      final response = await http
          .put(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'username': username,
          'newPassword': newPassword,
          'confirmNewPassword': confirmNewPassword,
        }),
      )
          .timeout(const Duration(seconds: 10));

      return _handleResponse(response);
    } on TimeoutException {
      return PasswordResetResult(
        success: false,
        message: '요청 시간이 초과되었습니다. 다시 시도해주세요.',
      );
    } catch (e) {
      return PasswordResetResult(
        success: false,
        message: '비밀번호 변경 중 오류가 발생했습니다.',
      );
    }
  }

  /// 공통 응답 처리 함수
  static PasswordResetResult _handleResponse(http.Response response) {
    try {
      final Map<String, dynamic> data = response.body.isNotEmpty
          ? jsonDecode(utf8.decode(response.bodyBytes))
          : {};

      final bool isHttpSuccess =
          response.statusCode >= 200 && response.statusCode < 300;

      final bool isApiSuccess = data['success'] == true;

      final String message = data['message']?.toString() ??
          (isHttpSuccess ? '요청이 성공했습니다.' : '요청에 실패했습니다.');

      if (isHttpSuccess && isApiSuccess) {
        return PasswordResetResult(
          success: true,
          message: message,
        );
      }

      return PasswordResetResult(
        success: false,
        message: message,
      );
    } catch (e) {
      return PasswordResetResult(
        success: false,
        message: '서버 응답을 처리하는 중 오류가 발생했습니다.',
      );
    }
  }
}