import 'package:flutter/material.dart';
import 'find_id_screen.dart';
import 'find_password_screen.dart';
import 'sign_up_screen.dart';
import 'Login_Screen.dart';

class FindPasswordSuccessScreen extends StatelessWidget {
  const FindPasswordSuccessScreen({super.key});

  void _goToFindIdScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const FindIdScreen()),
    );
  }

  void _goToFindPasswordScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const FindPasswordScreen()),
    );
  }

  void _goToSignUpScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SignUpScreen()),
    );
  }

  void _goToLoginScreen(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => const LoginScreen(),
      ),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF2F64F5);
    const Color buttonBlue = Color(0xFF2F64F5);
    const Color borderBlue = Color(0xFFD6E0FF);
    const Color cardBlue = Color(0xFFEFF3FF);
    const Color descGray = Color(0xFF9AA7C7);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  children: [
                    const SizedBox(height: 8),

                    Row(
                      children: [
                        IconButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          icon: const Icon(
                            Icons.arrow_back_ios_new,
                            color: primaryBlue,
                            size: 22,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        const Expanded(
                          child: Center(
                            child: Text(
                              '비밀번호 재설정',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: primaryBlue,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 22),
                      ],
                    ),

                    const SizedBox(height: 90),

                    const Text(
                      '축하드립니다! 🎉',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: primaryBlue,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 24),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 28,
                      ),
                      decoration: BoxDecoration(
                        color: cardBlue,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: primaryBlue,
                                width: 8,
                              ),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.check,
                                size: 60,
                                color: primaryBlue,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            '비밀번호 변경완료!',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: primaryBlue,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            '입력하신 비밀번호로 변경이 완료되었습니다.',
                            style: TextStyle(
                              fontSize: 13,
                              color: descGray,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 26),

                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: () => _goToLoginScreen(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: buttonBlue,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                        child: const Text(
                          '로그인하기',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),

                    const Spacer(),
                  ],
                ),
              ),
            ),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 26),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: borderBlue,
                    width: 1.2,
                  ),
                ),
              ),
              child: Column(
                children: [
                  Wrap(
                    alignment: WrapAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () => _goToFindIdScreen(context),
                        style: TextButton.styleFrom(
                          minimumSize: Size.zero,
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          '아이디 찾기',
                          style: TextStyle(
                            fontSize: 15,
                            color: Color(0xFF8EA0F5),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Text(
                        ' | ',
                        style: TextStyle(
                          fontSize: 15,
                          color: Color(0xFF8EA0F5),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextButton(
                        onPressed: () => _goToFindPasswordScreen(context),
                        style: TextButton.styleFrom(
                          minimumSize: Size.zero,
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          '비밀번호 찾기',
                          style: TextStyle(
                            fontSize: 15,
                            color: Color(0xFF8EA0F5),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Text(
                        ' | ',
                        style: TextStyle(
                          fontSize: 15,
                          color: Color(0xFF8EA0F5),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextButton(
                        onPressed: () => _goToSignUpScreen(context),
                        style: TextButton.styleFrom(
                          minimumSize: Size.zero,
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          '회원가입',
                          style: TextStyle(
                            fontSize: 15,
                            color: Color(0xFF8EA0F5),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.lock,
                        size: 18,
                        color: Color(0xFF9AA7E8),
                      ),
                      SizedBox(width: 6),
                      Text(
                        '개인정보는 안전하게 보호됩니다.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF9AA7E8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}