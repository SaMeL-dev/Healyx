import 'dart:async';

import 'package:flutter/material.dart';
import 'find_id_screen.dart';
import '../login_signup_screen/sign_up_screen.dart';
import 'find_password_reset_screen.dart';
import '../app_language.dart';
import '../services/password_reset_service.dart';

class FindPasswordScreen extends StatefulWidget {
  const FindPasswordScreen({super.key});

  @override
  State<FindPasswordScreen> createState() => _FindPasswordScreenState();
}

class _FindPasswordScreenState extends State<FindPasswordScreen> {
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();

  bool _isSendingCode = false;
  bool _isVerifying = false;

  Timer? _verificationTimer;
  int _remainingSeconds = 0;
  bool _hasRequestedCode = false;

  bool get _isEmailEntered => _emailController.text.trim().isNotEmpty;
  bool get _isTimerRunning => _remainingSeconds > 0;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _verificationTimer?.cancel();
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

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[\w\.-]+@[\w\.-]+\.\w+$',
    );
    return emailRegex.hasMatch(email);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  void _startVerificationCountdown() {
    _verificationTimer?.cancel();

    setState(() {
      _hasRequestedCode = true;
      _remainingSeconds = 180;
    });

    _verificationTimer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
        if (_remainingSeconds <= 1) {
          timer.cancel();

          if (!mounted) return;

          setState(() {
            _remainingSeconds = 0;
          });

          return;
        }

        if (!mounted) return;

        setState(() {
          _remainingSeconds--;
        });
      },
    );
  }

  String _formatRemainingTime() {
    final minutes = (_remainingSeconds ~/ 60).toString();
    final seconds = (_remainingSeconds % 60).toString().padLeft(2, '0');

    return '$minutes:$seconds';
  }

  Future<void> _requestVerification() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      _showMessage(AppLanguage.t('pw_enter_email')); // '이메일을 입력해주세요.'
      return;
    }

    if (!_isValidEmail(email)) {
      _showMessage(AppLanguage.t('pw_invalid_email')); // '올바른 이메일 형식이 아닙니다.'
      return;
    }

    setState(() {
      _isSendingCode = true;
    });

    final result = await PasswordResetService.sendResetPasswordEmailCode(
      email: email,
    );

    if (!mounted) return;

    setState(() {
      _isSendingCode = false;
    });

    if (result.success) {
      _startVerificationCountdown();
    }

    _showMessage(result.message);
  }

  Future<void> _confirmAction() async {
    final username = _idController.text.trim();
    final email = _emailController.text.trim();
    final verificationCode = _codeController.text.trim();

    if (username.isEmpty) {
      _showMessage(AppLanguage.t('pw_enter_username')); // '아이디를 입력해주세요.'
      return;
    }

    if (email.isEmpty) {
      _showMessage(AppLanguage.t('pw_enter_email')); // '이메일을 입력해주세요.'
      return;
    }

    if (!_isValidEmail(email)) {
      _showMessage(AppLanguage.t('pw_invalid_email')); // '올바른 이메일 형식이 아닙니다.'
      return;
    }

    if (verificationCode.isEmpty) {
      _showMessage(AppLanguage.t('pw_enter_verification_code')); // '인증번호를 입력해주세요.'
      return;
    }

    if (!_hasRequestedCode) {
      _showMessage(AppLanguage.t('pw_request_verification_first')); // '인증요청을 먼저 진행해주세요.'
      return;
    }

    if (_remainingSeconds <= 0) {
      _showMessage(AppLanguage.t('pw_verification_timeout_retry')); // '인증시간이 만료되었습니다. 인증요청을 다시 눌러주세요.'
      return;
    }

    setState(() {
      _isVerifying = true;
    });

    final result = await PasswordResetService.verifyResetPassword(
      username: username,
      email: email,
      verificationCode: verificationCode,
    );

    if (!mounted) return;

    setState(() {
      _isVerifying = false;
    });

    if (result.success) {
      _verificationTimer?.cancel();

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FindPasswordResetScreen(
            username: username,
          ),
        ),
      );
    } else {
      _showMessage(result.message);
    }
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
                        Expanded(
                          child: Center(
                            child: Text(
                              AppLanguage.t('pw_reset_title'), // '비밀번호 재설정'
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

                    Center(
                      child: Column(
                        children: [
                          Text(
                            AppLanguage.t('pw_step1_title'), // 'STEP 1. 본인 인증'
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF6A8AF7),
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            AppLanguage.t('pw_step1_desc'), // '안전한 비밀번호 변경을 위해 본인 확인이 필요합니다.'
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

                    Text(
                      AppLanguage.t('username_label'), // '아이디'
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildInputField(
                      controller: _idController,
                      hintText: AppLanguage.t('username_hint'), // '아이디를 입력하세요'
                    ),

                    const SizedBox(height: 28),

                    Text(
                      AppLanguage.t('profile_email'), // '이메일'
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildEmailWithButtonField(
                      controller: _emailController,
                      hintText: AppLanguage.t('email_hint'), // '이메일을 입력하세요'
                      buttonText: _isSendingCode
                          ? AppLanguage.t('pw_sending') // '전송중'
                          : AppLanguage.t('request_verification'), // '인증요청'
                      enabled:
                          _isEmailEntered && !_isSendingCode && !_isTimerRunning,
                      onPressed:
                          _isEmailEntered && !_isSendingCode && !_isTimerRunning
                              ? _requestVerification
                              : null,
                    ),

                    const SizedBox(height: 28),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppLanguage.t('verification_code_label'), // '인증번호'
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.black,
                          ),
                        ),
                        if (_hasRequestedCode)
                          Text(
                            _isTimerRunning
                                ? _formatRemainingTime()
                                : AppLanguage.t('pw_verification_expired'), // '인증시간 만료'
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: _isTimerRunning
                                  ? buttonBlue
                                  : Colors.red,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _buildInputField(
                      controller: _codeController,
                      hintText: AppLanguage.t('verification_code_hint'), // '인증번호를 입력하세요'
                    ),

                    const SizedBox(height: 34),

                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _isVerifying ? null : _confirmAction,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              _isVerifying ? const Color(0xFFD7E1FB) : buttonBlue,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                        child: Text(
                          _isVerifying
                              ? AppLanguage.t('pw_verifying') // '확인 중...'
                              : AppLanguage.t('confirm'), // '확인'
                          style: const TextStyle(
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
                        child: Text(
                          AppLanguage.t('find_id_title'), // '아이디 찾기'
                          style: TextStyle(
                            fontSize: 15,
                            color: Color(0xFF8EA0F5),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
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
                        child: Text(
                          AppLanguage.t('find_password'), // '비밀번호 찾기'
                          style: TextStyle(
                            fontSize: 15,
                            color: Color(0xFF8EA0F5),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
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
                        child: Text(
                          AppLanguage.t('sign_up'), // '회원가입'
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.lock,
                        size: 18,
                        color: Color(0xFF9AA7E8),
                      ),
                      SizedBox(width: 6),
                      Text(
                        AppLanguage.t('privacy_notice'), // '개인정보는 안전하게 보호됩니다.'
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
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 16,
          ),
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
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 16,
                ),
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
                    ? const Color(0xFF2260FF)
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