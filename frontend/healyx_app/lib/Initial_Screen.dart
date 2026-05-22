import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'choose_language_screen.dart';
import 'main_screen.dart';
import 'services/auth_service.dart';

class InitialScreen extends StatefulWidget {
  const InitialScreen({super.key});

  @override
  State<InitialScreen> createState() => _InitialScreenState();
}

class _InitialScreenState extends State<InitialScreen> {
  @override
  void initState() {
    super.initState();
    _navigateAfterSplash();
  }

  Future<void> _navigateAfterSplash() async {
    // 스플래시 최소 노출 시간과 SharedPreferences 로드를 병렬 처리
    final results = await Future.wait([
      Future.delayed(const Duration(seconds: 2)),
      SharedPreferences.getInstance(),
    ]);

    if (!mounted) return;

    final prefs = results[1] as SharedPreferences;
    final hasLanguage = prefs.getString('language_pref') != null;

    // 언어 선택을 하지 않은 사용자는 기존처럼 언어 선택 화면으로 이동
    if (!hasLanguage) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const ChooseLanguageScreen(),
        ),
      );
      return;
    }

    // 언어 선택이 되어 있는 경우 자동 로그인 시도
    final isAutoLoggedIn = await AuthService.tryAutoLogin();

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => MainScreen(
          isLoggedIn: isAutoLoggedIn,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 로고 이미지
              Image.asset(
                'assets/images/healyx_logo.png',
                width: 330,
                height: 330,
                fit: BoxFit.contain,
              ),
            ],
          ),
        ),
      ),
    );
  }
}