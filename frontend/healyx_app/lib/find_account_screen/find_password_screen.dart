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

  void _showSuccessMessage(String message) {
    _showCustomSnackBar(
      message: message,
      isSuccess: true,
    );
  }

  void _showErrorMessage(String message) {
    _showCustomSnackBar(
      message: message,
      isSuccess: false,
    );
  }

  void _showCustomSnackBar({
    required String message,
    required bool isSuccess,
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.fromLTRB(28, 0, 28, 28),
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.10),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: isSuccess
                      ? const Color(0xFFEAF0FF)
                      : const Color(0xFFFFEEEE),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isSuccess
                      ? Icons.check_rounded
                      : Icons.priority_high_rounded,
                  color: isSuccess
                      ? const Color(0xFF2260FF)
                      : const Color(0xFFE5484D),
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isSuccess
                        ? const Color(0xFF2260FF)
                        : const Color(0xFFE5484D),
                  ),
                ),
              ),
            ],
          ),
        ),
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
      _showErrorMessage(AppLanguage.t('pw_enter_email'));
      return;
    }

    if (!_isValidEmail(email)) {
      _showErrorMessage(AppLanguage.t('pw_invalid_email'));
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
      _showSuccessMessage(AppLanguage.t('pw_request_success'));
    } else {
      _showErrorMessage(AppLanguage.t('pw_request_fail'));
    }
  }

  Future<void> _confirmAction() async {
    final username = _idController.text.trim();
    final email = _emailController.text.trim();
    final verificationCode = _codeController.text.trim();

    if (username.isEmpty) {
      _showErrorMessage(AppLanguage.t('pw_enter_username'));
      return;
    }

    if (email.isEmpty) {
      _showErrorMessage(AppLanguage.t('pw_enter_email'));
      return;
    }

    if (!_isValidEmail(email)) {
      _showErrorMessage(AppLanguage.t('pw_invalid_email'));
      return;
    }

    if (verificationCode.isEmpty) {
      _showErrorMessage(AppLanguage.t('pw_enter_verification_code'));
      return;
    }

    if (!_hasRequestedCode) {
      _showErrorMessage(AppLanguage.t('pw_request_verification_first'));
      return;
    }

    if (_remainingSeconds <= 0) {
      _showErrorMessage(AppLanguage.t('pw_verification_timeout_retry'));
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
      _showErrorMessage(AppLanguage.t('pw_invalid_verification_code'));
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
                              AppLanguage.t('pw_reset_title'),
                              style: const TextStyle(
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
                            AppLanguage.t('pw_step1_title'),
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF6A8AF7),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            AppLanguage.t('pw_step1_desc'),
                            style: const TextStyle(
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
                      AppLanguage.t('username_label'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildInputField(
                      controller: _idController,
                      hintText: AppLanguage.t('username_hint'),
                    ),

                    const SizedBox(height: 28),

                    Text(
                      AppLanguage.t('profile_email'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildEmailWithButtonField(
                      controller: _emailController,
                      hintText: AppLanguage.t('email_hint'),
                      buttonText: _isSendingCode
                          ? AppLanguage.t('pw_sending')
                          : AppLanguage.t('request_verification'),
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
                          AppLanguage.t('verification_code_label'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.black,
                          ),
                        ),
                        if (_hasRequestedCode)
                          Text(
                            _isTimerRunning
                                ? _formatRemainingTime()
                                : AppLanguage.t('pw_verification_expired'),
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
                      hintText: AppLanguage.t('verification_code_hint'),
                    ),

                    const SizedBox(height: 34),

                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _isVerifying ? null : _confirmAction,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isVerifying
                              ? const Color(0xFFD7E1FB)
                              : buttonBlue,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                        child: Text(
                          _isVerifying
                              ? AppLanguage.t('pw_verifying')
                              : AppLanguage.t('confirm'),
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
                          AppLanguage.t('find_id_title'),
                          style: const TextStyle(
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
                        child: Text(
                          AppLanguage.t('find_password'),
                          style: const TextStyle(
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
                        child: Text(
                          AppLanguage.t('sign_up'),
                          style: const TextStyle(
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
                      const Icon(
                        Icons.lock,
                        size: 18,
                        color: Color(0xFF9AA7E8),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        AppLanguage.t('privacy_notice'),
                        style: const TextStyle(
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