import 'dart:convert';
// JSON 데이터를 Dart에서 사용할 수 있게 변환할 때 사용
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
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

// 로그인, 로그아웃, 로그인 여부 확인 같은 기능을 모아둔 클래스
class AuthService {
  // baseUrl 서버 주소
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
            message: '로그인 토큰을 받지 못했습니다.',
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
          message: '로그인 성공',
        );
      }


      return LoginResult(
        success: false,
        message: responseData['message'] ?? '아이디 또는 비밀번호가 일치하지 않습니다.',
      );
    } catch (e) {
      debugPrint('LOGIN ERROR: $e');

      return LoginResult(
        success: false,
        message: '서버 연결에 실패했습니다. 잠시 후 다시 시도해주세요.',
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

  // 로그아웃할 때 저장된 로그인 정보를 삭제하는 함수
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('accessToken');
    await prefs.remove('refreshToken');
    await prefs.remove('userId');
    await prefs.remove('username');
    await prefs.remove('nickname');
    await prefs.remove('name');
    await prefs.remove('email');
    await prefs.remove('insuranceStatus');
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