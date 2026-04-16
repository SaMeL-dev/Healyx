import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'sign_up_screen.dart';
import 'find_password_screen.dart';

class FindIdResultScreen extends StatelessWidget {
  const FindIdResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
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
                            size: 20,
                            color: Color(0xFF4E7CFF),
                          ),
                        ),
                        const Expanded(
                          child: Center(
                            child: Text(
                              '아이디 찾기',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF2F66FF),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),

                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            '아이디는\nkimc******\n입니다.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 30,
                              height: 1.45,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF2F66FF),
                            ),
                          ),
                          const SizedBox(height: 44),

                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const LoginScreen(),
                                  ),
                                      (route) => false,
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2F66FF),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(28),
                                ),
                              ),
                              child: const Text(
                                '로그인하기',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: Color(0xFFD6DDFB),
                    width: 1.2,
                  ),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildBottomTextButton(
                        text: '아이디 찾기',
                        onTap: () {},
                      ),
                      const Text(
                        ' | ',
                        style: TextStyle(
                          color: Color(0xFF8EA0F5),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      _buildBottomTextButton(
                        text: '비밀번호 찾기',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const FindPasswordScreen(),
                            ),
                          );
                        },
                      ),
                      const Text(
                        ' | ',
                        style: TextStyle(
                          color: Color(0xFF8EA0F5),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      _buildBottomTextButton(
                        text: '회원가입',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SignUpScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(
                        Icons.lock,
                        size: 16,
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

  Widget _buildBottomTextButton({
    required String text,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          color: Color(0xFF8EA0F5),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}