import 'package:flutter/material.dart';
import 'package:healyx_app/Initial_Screen.dart';
import 'login_signup_screen/login_screen.dart';
// 만약 본인이 만든 화면만 확인하고 싶은 경우 2번째 라인 해당 화면을 개발한 페이지 쓰고
// 하단 17라인 부근 home: 파트 수정하면 해당 화면만 확인 가능

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const LoginScreen(),
    );
  }
}