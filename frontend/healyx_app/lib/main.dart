import 'package:flutter/material.dart';
import 'translation_screen/translation_upload.dart';
// import 'package:healyx_app/Initial_Screen.dart';
// import 'login_signup_screen/login_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const TranslationUploadScreen(),
    );
  }
}