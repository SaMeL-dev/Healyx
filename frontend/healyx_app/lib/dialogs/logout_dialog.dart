// 로그아웃 확인 팝업
// 로그아웃 하시겠습니까? 예/아니오 버튼
import 'package:flutter/material.dart';
import 'package:healyx_app/menu_screen/menu_main.dart';
import '../app_language.dart';
import '../services/auth_service.dart';

class LogoutDialog extends StatelessWidget {
  const LogoutDialog({super.key});

  @override
  Widget build(BuildContext context) {
    const Color mainBlue    = Color(0xFF2260FF); // 메인 컬러
    const Color lightPurple = Color(0xFFE2EAFF); // 연한 배경

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      alignment: Alignment.bottomCenter,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(34, 34, 34, 40),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text( 
              AppLanguage.t('logout_confirm'), //'로그아웃 하시겠습니까?'
              style: TextStyle(
                color: mainBlue,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 36),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 46,
                    child: ElevatedButton(
                      onPressed: () async {
                        // 서버 Refresh Token 삭제 + 로컬 토큰 정리
                        await AuthService.logout();
                        if (!context.mounted) return;
                        // 로그아웃 → menu_screen/menu_main.dart (비로그인 화면)
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const MenuScreen(isLoggedIn: false),
                          ),
                          (route) => false,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: mainBlue,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: Text( 
                        AppLanguage.t('yes'), //'예'
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: SizedBox(
                    height: 46,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: lightPurple,
                        foregroundColor: mainBlue,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: Text( 
                        AppLanguage.t('no'), // '아니요'  
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}