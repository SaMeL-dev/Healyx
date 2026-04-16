// 변경할 비밀번호 입력 화면
import 'package:flutter/material.dart';
import 'find_id_screen.dart';
import 'find_password_screen.dart';
import 'sign_up_screen.dart';
import 'find_password_success_screen.dart';

class FindPasswordResetScreen extends StatefulWidget {
  const FindPasswordResetScreen({super.key});

  @override
  State<FindPasswordResetScreen> createState() =>
      _FindPasswordResetScreenState();
}

class _FindPasswordResetScreenState extends State<FindPasswordResetScreen> {
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
  TextEditingController();

  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _goToFindIdScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const FindIdScreen()),
    );
  }

  void _goToFindPasswordScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const FindPasswordScreen()),
    );
  }

  void _goToSignUpScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SignUpScreen()),
    );
  }

  void _onConfirm() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const FindPasswordSuccessScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF2F64F5);
    const Color subBlue = Color(0xFF6A8AF7);
    const Color lightBlue = Color(0xFFEDF2FF);
    const Color hintBlue = Color(0xFF8EA6F3);
    const Color buttonBlue = Color(0xFF2260FF);
    const Color borderBlue = Color(0xFFD6E0FF);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),

                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
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

                    const SizedBox(height: 34),

                    const Center(
                      child: Column(
                        children: [
                          Text(
                            'STEP 2. 새로운 비밀번호 설정',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: subBlue,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 6),
                          Text(
                            '안전한 계정 보호를 위해 새로운 비밀번호를 설정합니다',
                            style: TextStyle(
                              fontSize: 14,
                              color: subBlue,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 46),

                    const Text(
                      '새로운 비밀번호',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 10),

                    _buildPasswordField(
                      controller: _newPasswordController,
                      hintText: '새 비밀번호 입력',
                      obscureText: _obscureNewPassword,
                      onToggleVisibility: () {
                        setState(() {
                          _obscureNewPassword = !_obscureNewPassword;
                        });
                      },
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      '영문, 숫자, 특수문자(!@#+=)를 포함해주세요.',
                      style: TextStyle(
                        fontSize: 13,
                        color: subBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 28),

                    const Text(
                      '새로운 비밀번호 확인',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 10),

                    _buildPasswordField(
                      controller: _confirmPasswordController,
                      hintText: '새 비밀번호 확인',
                      obscureText: _obscureConfirmPassword,
                      onToggleVisibility: () {
                        setState(() {
                          _obscureConfirmPassword =
                          !_obscureConfirmPassword;
                        });
                      },
                    ),

                    const SizedBox(height: 34),

                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _onConfirm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: buttonBlue,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                        child: const Text(
                          '확인',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),
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
                        onPressed: _goToFindIdScreen,
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
                        onPressed: _goToFindPasswordScreen,
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
                        onPressed: _goToSignUpScreen,
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

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hintText,
    required bool obscureText,
    required VoidCallback onToggleVisibility,
  }) {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        color: const Color(0xFFEDF2FF),
        borderRadius: BorderRadius.circular(14),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(
            color: Color(0xFF8EA6F3),
            fontSize: 16,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          suffixIcon: IconButton(
            onPressed: onToggleVisibility,
            icon: Icon(
              obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              color: const Color(0xFF8EA6F3),
            ),
          ),
        ),
      ),
    );
  }
}