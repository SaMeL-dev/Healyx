import 'package:flutter/material.dart';
import 'find_id_result_screen.dart';
import 'sign_up_screen.dart';
import 'find_password_screen.dart';

class FindIdScreen extends StatefulWidget {
  const FindIdScreen({super.key});

  @override
  State<FindIdScreen> createState() => _FindIdScreenState();
}

class _FindIdScreenState extends State<FindIdScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController codeController = TextEditingController();

  bool get isEmailFilled => emailController.text.trim().isNotEmpty;

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    emailController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    codeController.dispose();
    super.dispose();
  }

  void _requestVerification() {
    if (!isEmailFilled) return;
    _showMessage('인증요청이 전송되었습니다.');
  }

  void _confirmFindId() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const FindIdResultScreen(),
      ),
    );
  }

  void _goToFindPasswordScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const FindPasswordScreen(),
      ),
    );
  }

  void _goToSignUpScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SignUpScreen(),
      ),
    );
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
                        '아이디 확인을 위해 본인 확인이 필요합니다',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF9AA7E8),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    const SizedBox(height: 56),

                    const Text(
                      '이름',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildInputField(
                      controller: nameController,
                      hintText: '이름을 입력하세요',
                    ),

                    const SizedBox(height: 28),

                    const Text(
                      '이메일',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildEmailField(),

                    const SizedBox(height: 28),

                    const Text(
                      '인증번호',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildInputField(
                      controller: codeController,
                      hintText: '인증번호를 입력하세요',
                    ),

                    const SizedBox(height: 40),

                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _confirmFindId,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2260FF),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                        child: const Text(
                          '확인',
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
                      const Text(
                        '아이디 찾기',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF8EA0F5),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Text(
                        ' | ',
                        style: TextStyle(
                          color: Color(0xFF8EA0F5),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      GestureDetector(
                        onTap: _goToFindPasswordScreen,
                        child: const Text(
                          '비밀번호 찾기',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF8EA0F5),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Text(
                        ' | ',
                        style: TextStyle(
                          color: Color(0xFF8EA0F5),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      GestureDetector(
                        onTap: _goToSignUpScreen,
                        child: const Text(
                          '회원가입',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF8EA0F5),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
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
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFEFF2FF),
        borderRadius: BorderRadius.circular(14),
      ),
      child: TextField(
        controller: controller,
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
        ),
      ),
    );
  }

  Widget _buildEmailField() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFEFF2FF),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
              decoration: const InputDecoration(
                hintText: '이메일을 입력하세요',
                hintStyle: TextStyle(
                  fontSize: 16,
                  color: Color(0xFFB0B9F5),
                  fontWeight: FontWeight.w500,
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                border: InputBorder.none,
              ),
            ),
          ),
          GestureDetector(
            onTap: isEmailFilled ? _requestVerification : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              alignment: Alignment.center,
              width: 92,
              height: 54,
              decoration: BoxDecoration(
                color: isEmailFilled
                    ? const Color(0xFF6F8EF6)
                    : const Color(0xFFBFCBF8),
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(14),
                  bottomRight: Radius.circular(14),
                ),
              ),
              child: const Text(
                '인증요청',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}