import 'dart:convert';
// JSON 데이터를 Dart에서 사용할 수 있게 변환할 때 사용
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:healyx_app/app_language.dart';
// pubspec.yaml에서 쓴 Flutter에서 서버 API 호출할 때 사용하는 패키지

import 'package:shared_preferences/shared_preferences.dart';
// 앱 내부에 간단한 값을 저장할 때 사용하는 패키지

// 로그인 결과를 담기 위한 클래스
class LoginResult {
  final bool success;
  final String? message;

  LoginResult({
    required this.success,
    this.message,
  });
}

// 회원가입 결과를 담기 위한 클래스
class RegisterResult {
  final bool success;
  final String? message;

  RegisterResult({
    required this.success,
    this.message,
  });
}

// 이메일 인증 코드 발송 결과를 담기 위한 클래스
class EmailSendResult {
  final bool success;
  final String? message;

  EmailSendResult({required this.success, this.message});
}

// 아이디 찾기 결과를 담기 위한 클래스
class FindIdResult {
  final bool success;
  final String? maskedUsername;
  final String? message;

  FindIdResult({required this.success, this.maskedUsername, this.message});
}

// 현재 비밀번호 검증 결과를 담기 위한 클래스
class VerifyPasswordResult {
  final bool success;
  final String? message;

  VerifyPasswordResult({required this.success, this.message});
}

// 비밀번호 변경 결과를 담기 위한 클래스
class ChangePasswordResult {
  final bool success;
  final String? message;

  ChangePasswordResult({required this.success, this.message});
}

// 로그인, 로그아웃, 로그인 여부 확인 같은 기능을 모아둔 클래스
class AuthService {
  // baseUrl 서버 주소
  // static const String baseUrl = 'http://localhost:8080'; // 테스트용
  static const String baseUrl = 'https://jwejweiya.com';

  // 로그인 화면에서 아이디와 비밀번호를 넘겨주면, 이 함수가 서버에 로그인 요청을 보냄
  static Future<LoginResult> login({
    required String username,
    required String password,
  }) async {
    final url = Uri.parse('$baseUrl/api/auth/login');

    try {

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );

      final decodedBody = utf8.decode(response.bodyBytes);


      final Map<String, dynamic> responseData = jsonDecode(decodedBody);

      if (response.statusCode == 200 && responseData['success'] == true) {
        final data = responseData['data'];

        final String? accessToken = data['accessToken'];
        final String? refreshToken = data['refreshToken'];

        if (accessToken == null || accessToken.isEmpty) {

          return LoginResult(
            success: false,
            message: AppLanguage.t('auth_token_error'), // '로그인 토큰을 받지 못했습니다.'
          );
        }

        final prefs = await SharedPreferences.getInstance();

        await prefs.setString('accessToken', accessToken);

        if (refreshToken != null) {
          await prefs.setString('refreshToken', refreshToken);
        }

        if (data['userId'] != null) {
          await prefs.setInt('userId', data['userId']);
        }

        if (data['username'] != null) {
          await prefs.setString('username', data['username']);
        }

        if (data['nickname'] != null) {
          await prefs.setString('nickname', data['nickname']);
        }

        if (data['name'] != null) {
          await prefs.setString('name', data['name']);
        }

        if (data['email'] != null) {
          await prefs.setString('email', data['email']);
        }

        if (data['insuranceStatus'] != null) {
          await prefs.setBool('insuranceStatus', data['insuranceStatus']);
        }


        return LoginResult(
          success: true,
          message: AppLanguage.t('login_success'), // '로그인 성공'
        );
      }


      return LoginResult(
        success: false,
        message: responseData['message'] ?? AppLanguage.t('login_error'), // '아이디 및 비밀번호가 일치하지 않습니다.'
      );
    } catch (e) {
      debugPrint('LOGIN ERROR: $e');

      return LoginResult(
        success: false,
        message: AppLanguage.t('server_error'), // '서버 연결에 실패했습니다. 잠시 후 다시 시도해주세요.'
      );
    }
  }

  // 현재 사용자가 로그인 상태인지 확인하는 함수 (토큰 유무)
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('accessToken');

    return accessToken != null && accessToken.isNotEmpty;
  }

  // 저장된 accessToken을 꺼내오는 함수
  static Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('accessToken');
  }

  // 로그아웃 — 서버에 Refresh Token 삭제 요청 후 로컬 저장소 정리
  static Future<void> logout() async {
    try {
      final token = await getAccessToken();
      if (token != null && token.isNotEmpty) {
        await http.post(
          Uri.parse('$baseUrl/api/auth/logout'),
          headers: {'Authorization': 'Bearer $token'},
        ).timeout(const Duration(seconds: 5));
      }
    } catch (_) {
      // 서버 요청 실패해도 로컬 토큰은 무조건 삭제
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('accessToken');
    await prefs.remove('refreshToken');
    await prefs.remove('userId');
    await prefs.remove('username');
    await prefs.remove('nickname');
    await prefs.remove('name');
    await prefs.remove('email');
    await prefs.remove('insuranceStatus');
    await prefs.remove('pushEnabled');
  }

  // 이메일 사용 가능 여부 확인 — true: 사용 가능, false: 이미 사용 중
  static Future<bool> checkEmailAvailable(String email) async {
    final url = Uri.parse('$baseUrl/api/auth/check-email?email=${Uri.encodeComponent(email)}');
    try {
      final response = await http.get(url);
      final decoded = utf8.decode(response.bodyBytes);
      final data = jsonDecode(decoded);
      if (response.statusCode == 200 && data['success'] == true) {
        return data['data'] == true;
      }
      throw Exception(data['message'] ?? AppLanguage.t('email_taken')); // '이미 사용 중인 이메일입니다.'
    } catch (e) {
      debugPrint('CHECK_EMAIL ERROR: $e');
      rethrow;
    }
  }

  // 아이디 사용 가능 여부 확인 (true: 사용 가능, false: 이미 사용 중)
  static Future<bool> checkUsernameAvailable(String username) async {
    final url = Uri.parse('$baseUrl/api/auth/check-username?username=${Uri.encodeComponent(username)}');
    try {
      final response = await http.get(url);
      final decoded = utf8.decode(response.bodyBytes);
      final data = jsonDecode(decoded);
      if (response.statusCode == 200 && data['success'] == true) {
        return data['data'] == true;
      }
      throw Exception(data['message'] ?? AppLanguage.t('username_taken')); // '이미 사용 중인 아이디입니다.'
    } catch (e) {
      debugPrint('CHECK_USERNAME ERROR: $e');
      rethrow;
    }
  }

  // 이메일 인증 코드 발송 (purpose: find-id | reset-pw)
  static Future<EmailSendResult> sendEmailVerification({
    required String email,
    required String purpose,
  }) async {
    final url = Uri.parse('$baseUrl/api/email/send');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'purpose': purpose}),
      );
      final decoded = utf8.decode(response.bodyBytes);
      final data = jsonDecode(decoded);
      if (response.statusCode == 200 && data['success'] == true) {
        return EmailSendResult(success: true);
      }
      return EmailSendResult(
        success: false,
        message: data['message'] ?? AppLanguage.t('verification_send_failed'), // '인증 코드 발송에 실패했습니다.'
      );
    } catch (e) {
      debugPrint('SEND_EMAIL ERROR: $e');
      return EmailSendResult(
        success: false,
        message: AppLanguage.t('server_error'), // '서버 연결에 실패했습니다. 잠시 후 다시 시도해주세요.'
      );
    }
  }

  // 아이디 찾기 — 인증 코드 검증 및 마스킹된 아이디 반환
  static Future<FindIdResult> findId({
    required String name,
    required String email,
    required String verificationCode,
  }) async {
    final url = Uri.parse('$baseUrl/api/auth/find-id');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'verificationCode': verificationCode,
        }),
      );
      final decoded = utf8.decode(response.bodyBytes);
      final data = jsonDecode(decoded);
      if (response.statusCode == 200 && data['success'] == true) {
        return FindIdResult(
          success: true,
          maskedUsername: data['data']['maskedUsername'],
        );
      }
      return FindIdResult(
        success: false,
        message: data['message'] ?? AppLanguage.t('find_id_not_found'), // '아이디를 찾을 수 없습니다.'
      );
    } catch (e) {
      debugPrint('FIND_ID ERROR: $e');
      return FindIdResult(
        success: false,
        message: AppLanguage.t('server_error'), // '서버 연결에 실패했습니다. 잠시 후 다시 시도해주세요.'
      );
    }
  }

  // 비밀번호 변경 1단계 — 현재 비밀번호 검증 (JWT 필요)
  static Future<VerifyPasswordResult> verifyCurrentPassword(String currentPassword) async {
    final url = Uri.parse('$baseUrl/api/auth/verify-current-password');
    final token = await getAccessToken();
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'currentPassword': currentPassword}),
      );
      final decoded = utf8.decode(response.bodyBytes);
      final data = jsonDecode(decoded);
      if (response.statusCode == 200 && data['success'] == true) {
        return VerifyPasswordResult(success: true);
      }
      return VerifyPasswordResult(
        success: false,
        message: data['message'] ?? AppLanguage.t('pw_mismatch'), // '비밀번호가 일치하지 않습니다.'
      );
    } catch (e) {
      debugPrint('VERIFY_CURRENT_PASSWORD ERROR: $e');
      return VerifyPasswordResult(
        success: false,
        message: AppLanguage.t('server_error'), // '서버 연결에 실패했습니다. 잠시 후 다시 시도해주세요.'
      );
    }
  }

  // 비밀번호 변경 2단계 — 새 비밀번호로 변경 (JWT 필요)
  static Future<ChangePasswordResult> changePassword({
    required String newPassword,
    required String confirmNewPassword,
  }) async {
    final url = Uri.parse('$baseUrl/api/auth/change-password');
    final token = await getAccessToken();
    try {
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'newPassword': newPassword,
          'confirmNewPassword': confirmNewPassword,
        }),
      );
      final decoded = utf8.decode(response.bodyBytes);
      final data = jsonDecode(decoded);
      if (response.statusCode == 200 && data['success'] == true) {
        return ChangePasswordResult(success: true);
      }
      return ChangePasswordResult(
        success: false,
        message: data['message'] ?? AppLanguage.t('pw_change_error'), // '비밀번호 변경에 실패했습니다.'
      );
    } catch (e) {
      debugPrint('CHANGE_PASSWORD ERROR: $e');
      return ChangePasswordResult(
        success: false,
        message: AppLanguage.t('server_error'), // '서버 연결에 실패했습니다. 잠시 후 다시 시도해주세요.'
      );
    }
  }

  // 알림 설정 변경 (JWT 필요) — 성공 여부 반환
  static Future<bool> updatePushEnabled(bool enabled) async {
    final token = await getAccessToken();
    if (token == null || token.isEmpty) return false;

    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/api/users/me/push'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'pushEnabled': enabled}),
      ).timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('UPDATE_PUSH ERROR: $e');
      return false;
    }
  }

  // 선호 언어 변경 (JWT 필요) — 비로그인 시 로컬 저장만 하므로 null 허용
  static Future<void> updateLanguage(String languageCode) async {
    final token = await getAccessToken();
    if (token == null || token.isEmpty) return;

    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/api/users/me/language'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'languageCode': languageCode}),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
          'Language update failed: ${response.statusCode} ${response.body}',
        );
      }
    } catch (e) {
      debugPrint('UPDATE_LANGUAGE ERROR: $e');
    }
  }

  // 회원가입 요청
  static Future<RegisterResult> register({
    required String realName,
    required String email,
    required String username,
    required String password,
    required String passwordConfirm,
    required String nickname,
    String? birthDate,         // yyyy-MM-dd 형식
    String? gender,            // 'M' 또는 'F'
    bool hasHealthInsurance = false,
    String preferredLanguage = 'ko',
  }) async {
    final url = Uri.parse('$baseUrl/api/auth/register');
    try {
      final Map<String, dynamic> body = {
        'realName': realName,
        'email': email,
        'username': username,
        'password': password,
        'passwordConfirm': passwordConfirm,
        'nickname': nickname,
        'hasHealthInsurance': hasHealthInsurance,
        'preferredLanguage': preferredLanguage,
      };
      if (birthDate != null) body['birthDate'] = birthDate;
      if (gender != null) body['gender'] = gender;

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      final decoded = utf8.decode(response.bodyBytes);
      final data = jsonDecode(decoded);

      if (response.statusCode == 201 && data['success'] == true) {
        return RegisterResult(success: true, message: AppLanguage.t('signup_success')); // '회원가입이 완료되었습니다.'
      }
      return RegisterResult(
        success: false,
        message: data['message'] ?? AppLanguage.t('signup_failed'), // '회원가입에 실패했습니다.'
      );
    } catch (e) {
      debugPrint('REGISTER ERROR: $e');
      return RegisterResult(
        success: false,
        message: AppLanguage.t('server_error'), // '서버 연결에 실패했습니다. 잠시 후 다시 시도해주세요.'
      );
    }
  }
}


/*
auth_service.dart는 실제 로그인 요청을 담당하는 파일

사용자가 아이디/비밀번호 입력
        ↓
로그인 버튼 클릭
        ↓
AuthService.login(username, password) 실행
        ↓
서버 로그인 API 호출
        ↓
서버가 accessToken, refreshToken 반환
        ↓
토큰을 앱 내부 저장소에 저장
        ↓
로그인 성공 결과를 로그인 화면에 알려줌
*/