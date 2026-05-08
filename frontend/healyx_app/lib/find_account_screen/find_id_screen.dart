import 'dart:async';
import 'package:flutter/material.dart';
import 'find_id_result_screen.dart';
import '../login_signup_screen/sign_up_screen.dart';
import 'find_password_screen.dart';
import '../services/auth_service.dart';

class FindIdScreen extends StatefulWidget {
  const FindIdScreen({super.key});

  @override
  State<FindIdScreen> createState() => _FindIdScreenState();
}

class _FindIdScreenState extends State<FindIdScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController codeController = TextEditingController();

  bool _isSendingCode = false;
  bool _isLoading = false;

  // 인증번호 타이머
  Timer? _timer;
  int _remainingSeconds = 0;
  bool get _isTimerRunning => _remainingSeconds > 0;

  // 남은 시간을 MM:SS 형식으로 반환
  String get _timerText {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  bool get isEmailFilled => emailController.text.trim().isNotEmpty;

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
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

  // 3분(180초) 카운트다운 시작
  void _startTimer() {
    _timer?.cancel();
    setState(() => _remainingSeconds = 180);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds <= 1) {
        timer.cancel();
        setState(() => _remainingSeconds = 0);
        _showMessage('인증번호가 만료되었습니다. 다시 요청해주세요.');
      } else {
        setState(() => _remainingSeconds--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    nameController.dispose();
    emailController.dispose();
    codeController.dispose();
    super.dispose();
  }

  // 인증 코드 발송 — POST /api/email/send
  Future<void> _requestVerification() async {
    final email = emailController.text.trim();
    if (email.isEmpty) return;

    setState(() => _isSendingCode = true);
    final result = await AuthService.sendEmailVerification(
      email: email,
      purpose: 'find-id',
    );
    setState(() => _isSendingCode = false);

    if (result.success) {
      _startTimer();
      _showMessage('인증번호가 이메일로 발송되었습니다.');
    } else {
      _showMessage(result.message ?? '인증 코드 발송에 실패했습니다.');
    }
  }

  // 아이디 찾기 확인 — POST /api/auth/find-id
  Future<void> _confirmFindId() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final code = codeController.text.trim();

    if (name.isEmpty || email.isEmpty || code.isEmpty) {
      _showMessage('이름, 이메일, 인증번호를 모두 입력해주세요.');
      return;
    }

    setState(() => _isLoading = true);
    final result = await AuthService.findId(
      name: name,
      email: email,
      verificationCode: code,
    );
    setState(() => _isLoading = false);

    if (result.success) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FindIdResultScreen(
            maskedUsername: result.maskedUsername!,
          ),
        ),
      );
    } else {
      _showMessage(result.message ?? '아이디를 찾을 수 없습니다.');
    }
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
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF2FF),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: TextField(
                        controller: codeController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                        decoration: InputDecoration(
                          hintText: '인증번호를 입력하세요',
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
                          suffixIcon: _isTimerRunning
                              ? Padding(
                                  padding: const EdgeInsets.only(right: 14),
                                  child: Text(
                                    _timerText,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFFFF4D4D),
                                    ),
                                  ),
                                )
                              : null,
                          suffixIconConstraints: const BoxConstraints(
                            minWidth: 0,
                            minHeight: 0,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _confirmFindId,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2260FF),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Text(
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
            onTap: (isEmailFilled && !_isSendingCode) ? _requestVerification : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              alignment: Alignment.center,
              width: 92,
              height: 54,
              decoration: BoxDecoration(
                color: (isEmailFilled && !_isSendingCode)
                    ? const Color(0xFF6F8EF6)
                    : const Color(0xFFBFCBF8),
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(14),
                  bottomRight: Radius.circular(14),
                ),
              ),
              child: _isSendingCode
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      _isTimerRunning ? '재전송' : '인증요청',
                      style: const TextStyle(
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