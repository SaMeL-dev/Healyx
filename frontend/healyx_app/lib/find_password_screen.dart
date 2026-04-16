import 'package:flutter/material.dart';
import 'find_id_screen.dart';
import 'sign_up_screen.dart';
import 'find_password_reset_screen.dart';

class FindPasswordScreen extends StatefulWidget {
  const FindPasswordScreen({super.key});

  @override
  State<FindPasswordScreen> createState() => _FindPasswordScreenState();
}

class _FindPasswordScreenState extends State<FindPasswordScreen> {
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();

  bool get _isEmailEntered => _emailController.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _idController.dispose();
    _emailController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  void _goToFindIdScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const FindIdScreen()),
    );
  }

  void _goToSignUpScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SignUpScreen()),
    );
  }

  void _requestVerification() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('인증요청이 전송되었습니다.'),
      ),
    );
  }

  void _confirmAction() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const FindPasswordResetScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF2F64F5);
    const Color buttonBlue = Color(0xFF2260FF);
    const Color borderBlue = Color(0xFFD6E0FF);
    const Color backgroundColor = Colors.white;

    return Scaffold(
      backgroundColor: backgroundColor,
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

                    const SizedBox(height: 26),

                    const Center(
                      child: Column(
                        children: [
                          Text(
                            'STEP 1. 본인 인증',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF6A8AF7),
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            '안전한 비밀번호 변경을 위해 본인 확인이 필요합니다.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF6A8AF7),
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 44),

                    const Text(
                      '아이디',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildInputField(
                      controller: _idController,
                      hintText: '아이디를 입력하세요',
                    ),

                    const SizedBox(height: 28),

                    const Text(
                      '이메일',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildEmailWithButtonField(
                      controller: _emailController,
                      hintText: '이메일을 입력하세요',
                      buttonText: '인증요청',
                      enabled: _isEmailEntered,
                      onPressed: _isEmailEntered ? _requestVerification : null,
                    ),

                    const SizedBox(height: 28),

                    const Text(
                      '인증번호',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildInputField(
                      controller: _codeController,
                      hintText: '인증번호를 입력하세요',
                    ),

                    const SizedBox(height: 34),

                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _confirmAction,
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
                        onPressed: () {},
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

  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
  }) {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        color: const Color(0xFFEDF2FF),
        borderRadius: BorderRadius.circular(14),
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(
            color: Color(0xFF8EA6F3),
            fontSize: 16,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildEmailWithButtonField({
    required TextEditingController controller,
    required String hintText,
    required String buttonText,
    required bool enabled,
    required VoidCallback? onPressed,
  }) {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        color: const Color(0xFFEDF2FF),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: const TextStyle(
                  color: Color(0xFF8EA6F3),
                  fontSize: 16,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              ),
            ),
          ),
          SizedBox(
            width: 98,
            height: 54,
            child: ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: enabled
                    ? const Color(0xFF9FB6F5)
                    : const Color(0xFFD7E1FB),
                elevation: 0,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(14),
                    bottomRight: Radius.circular(14),
                  ),
                ),
              ),
              child: Text(
                buttonText,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: enabled ? Colors.white : const Color(0xFF94A7DE),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}