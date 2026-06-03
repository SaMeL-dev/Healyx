import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:healyx_app/app_language.dart';

/// API 호출 결과를 화면에서 사용하기 쉽게 담는 클래스
class PasswordResetResult {
  final bool success;
  final String message;
  final String? errorCode;

  PasswordResetResult({
    required this.success,
    required this.message,
    this.errorCode,
  });
}

class PasswordResetService {
  /// 예시:
  /// static const String baseUrl = 'http://서버주소';
  /// static const String baseUrl = 'https://서버주소';
  static const String baseUrl = 'https://jwejweiya.com';

  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'Accept-Language': AppLanguage.currentLang.value,
  };

  /// 1. 비밀번호 재설정 이메일 인증번호 발송
  ///
  /// POST /api/email/send
  ///
  /// body:
  /// {
  ///   "email": "사용자 이메일",
  ///   "purpose": "reset-pw",
  ///   "username": "사용자 아이디"
  /// }
  static Future<PasswordResetResult> sendResetPasswordEmailCode({
    required String username,
    required String email,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/api/email/send');

      final response = await http
          .post(
        url,
        headers: _headers,
        body: jsonEncode({
          'email': email,
          'purpose': 'reset-pw',
          'username': username,
        }),
      )
          .timeout(const Duration(seconds: 10));

      return _handleResponse(response);
    } on TimeoutException {
      return PasswordResetResult(
        success: false,
        message: AppLanguage.t('pw_request_timeout'),
      );
    } catch (e) {
      return PasswordResetResult(
        success: false,
        message: AppLanguage.t('pw_send_code_error'),
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
        headers: _headers,
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
        message: AppLanguage.t('pw_request_timeout'),
      );
    } catch (e) {
      return PasswordResetResult(
        success: false,
        message: AppLanguage.t('pw_verify_error'),
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
        headers: _headers,
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
        message: AppLanguage.t('pw_request_timeout'),
      );
    } catch (e) {
      return PasswordResetResult(
        success: false,
        message: AppLanguage.t('pw_change_error'),
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

      final String? errorCode = data['errorCode']?.toString();

      final String message = data['message']?.toString() ??
          (isHttpSuccess
              ? AppLanguage.t('pw_request_success')
              : AppLanguage.t('pw_request_fail'));

      if (isHttpSuccess && isApiSuccess) {
        return PasswordResetResult(
          success: true,
          message: message,
          errorCode: errorCode,
        );
      }

      return PasswordResetResult(
        success: false,
        message: message,
        errorCode: errorCode,
      );
    } catch (e) {
      return PasswordResetResult(
        success: false,
        message: AppLanguage.t('pw_response_parse_error'),
      );
    }
  }
}