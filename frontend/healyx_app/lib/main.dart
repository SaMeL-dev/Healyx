import 'package:flutter/material.dart';
import 'package:healyx_app/Initial_Screen.dart';
import 'login_signup_screen/login_screen.dart';
import 'find_hospital_screen/find_hospital_result.dart';
import 'archive_screen/archive_main.dart';
import 'review_screen/review_search.dart';
import 'community_screen/community_notification.dart';
import 'menu_screen/menu_main.dart';
import 'translation_screen/translation_upload.dart';
import 'menu_screen/menu_main.dart';
import 'app_language.dart'; // 공통 언어 관리
import 'main_screen.dart';
import 'review_screen/review_receipt_upload.dart';


// 만약 본인이 만든 화면만 확인하고 싶은 경우 2번째 라인 해당 화면을 개발한 페이지 쓰고
// 하단 home: 파트 수정하면 해당 화면만 확인 가능

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Flutter 초기화
  await AppLanguage.load(); // 퍼블리싱 다국어 테스트를 위한 저장 언어 로드
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: AppLanguage.currentLang,
      builder: (context, lang, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          home: const InitialScreen(),
        );
      },
    );
  }
}