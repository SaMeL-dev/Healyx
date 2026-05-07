
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'choose_language_screen.dart';
import 'main_screen.dart';

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

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) =>
            hasLanguage ? const MainScreen() : const ChooseLanguageScreen(),
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