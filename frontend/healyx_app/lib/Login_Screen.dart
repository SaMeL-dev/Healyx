// 로그인 화면 구현

import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController idController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isAutoLogin = false;
  bool isObscure = true;

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  void dispose() {
    idController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),

                    // 상단 바
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
                              '로그인',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF4E7CFF),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),

                    const SizedBox(height: 12),

                    const Center(
                      child: Text(
                        '계정으로 로그인 하여 서비스를 이용하세요.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF9AA7E8),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    const SizedBox(height: 56),

                    const Text(
                      '아이디',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),

                    _buildInputField(
                      controller: idController,
                      hintText: '아이디를 입력하세요',
                      obscureText: false,
                    ),

                    const SizedBox(height: 28),

                    const Text(
                      '비밀번호',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),

                    _buildInputField(
                      controller: passwordController,
                      hintText: '비밀번호를 입력하세요',
                      obscureText: isObscure,
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            isObscure = !isObscure;
                          });
                        },
                        icon: Icon(
                          isObscure
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: const Color(0xFF9AA7E8),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    Row(
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: Checkbox(
                            value: isAutoLogin,
                            onChanged: (value) {
                              setState(() {
                                isAutoLogin = value ?? false;
                              });
                            },
                            activeColor: const Color(0xFF4E7CFF),
                            side: const BorderSide(
                              color: Color(0xFF4E7CFF),
                              width: 1.4,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          '자동 로그인',
                          style: TextStyle(
                            fontSize: 15,
                            color: Color(0xFF4E7CFF),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 36),

                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                          _showMessage('로그인 버튼 클릭');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF98A9F4),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                        child: const Text(
                          '로그인',
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
            ),

            // 하단 영역
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
                        onTap: () {
                          _showMessage('아이디 찾기');
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
                        text: '비밀번호 찾기',
                        onTap: () {
                          _showMessage('비밀번호 찾기');
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
                          _showMessage('회원가입');
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

  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    required bool obscureText,
    Widget? suffixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFEFF2FF),
        borderRadius: BorderRadius.circular(14),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        style: const TextStyle(
          fontSize: 16,
          color: Colors.black87,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(
            fontSize: 16,
            color: Color(0xFFB0B9F5),
            fontWeight: FontWeight.w500,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          border: InputBorder.none,
          suffixIcon: suffixIcon,
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