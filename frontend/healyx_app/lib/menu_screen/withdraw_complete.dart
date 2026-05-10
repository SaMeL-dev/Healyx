// 회원 탈퇴 완료 화면
// 탈퇴 완료 체크 아이콘과 확인 버튼 표시
// 확인 버튼 탭 → main_screen.dart (메인 화면)으로 이동
import 'package:flutter/material.dart';
import 'package:healyx_app/main_screen.dart';
import '../app_language.dart'; 

class WithdrawCompleteScreen extends StatelessWidget {
  const WithdrawCompleteScreen({super.key});

  static const Color mainBlue  = Color(0xFF2260FF);
  static const Color lightBlue = Color(0xFFE2EAFF);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 체크 카드
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
                      const SizedBox(height: 24),
                      Text( 
                        AppLanguage.t('withdraw_complete'), // '회원탈퇴 완료'
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: mainBlue,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // 확인 버튼 → MainScreen으로 이동
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const MainScreen()),
                        (route) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: mainBlue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: Text( 
                      AppLanguage.t('confirm'), // '확인'
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}