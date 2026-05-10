// 비밀번호 재설정 완료 화면

import 'package:flutter/material.dart';
import 'package:healyx_app/login_signup_screen/login_screen.dart';
import '../../app_language.dart'; 

class PasswordResetSuccessScreen extends StatelessWidget {
  const PasswordResetSuccessScreen({super.key});

  static const Color mainBlue = Color(0xFF2260FF);
  static const Color lightBlue = Color(0xFFE2EAFF);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: Colors.black, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text( 
          AppLanguage.t('pw_reset_title'), // '비밀번호 재설정'
          style: TextStyle(color: mainBlue, fontSize: 20, fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start, // 위쪽 정렬
                  children: [
                    const SizedBox(height: 40),

                    // 축하 타이틀
                    Text( 
                      AppLanguage.t('pw_congrats'), // '축하드립니다! 🎉'
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: mainBlue,
                      ),
                    ),

                    const SizedBox(height: 28),

                    // 완료 카드
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 48),
                      decoration: BoxDecoration(
                        color: lightBlue,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: mainBlue, width: 4),
                            ),
                            child: const Icon(Icons.check, color: mainBlue, size: 56),
                          ),
                          const SizedBox(height: 20),
                          Text( 
                            AppLanguage.t('pw_change_complete'), // '비밀번호 변경완료!'
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: mainBlue,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text( 
                            AppLanguage.t('pw_change_desc'), // '입력하신 비밀번호로 변경이 완료되었습니다.'
                            style: TextStyle(fontSize: 13, color: Colors.black54),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // 로그인하기 버튼
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () {
                          // 로그인 화면으로 이동 → login_signup_screen/login_screen.dart
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (_) => const LoginScreen()),
                            (route) => false,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: mainBlue,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        ),
                        child: Text( 
                          AppLanguage.t('go_to_login'), // '로그인하기'
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 하단 개인정보 보호 안내
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children:[
                  Icon(Icons.lock_outline, size: 14, color: mainBlue),
                  SizedBox(width: 6),
                  Text(AppLanguage.t('privacy_notice'), style: TextStyle(fontSize: 12, color: Colors.black45)), // '개인정보는 안전하게 보호됩니다.'
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}