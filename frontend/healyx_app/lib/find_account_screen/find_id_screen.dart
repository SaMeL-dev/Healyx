import 'dart:async';
import 'package:flutter/material.dart';
import 'find_id_result_screen.dart';
import '../login_signup_screen/sign_up_screen.dart';
import 'find_password_screen.dart';
import '../services/auth_service.dart';
import '../app_language.dart'; 

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

  OverlayEntry? _toastEntry;
  Timer? _toastTimer;

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

  void _removeCustomToast() {
    _toastTimer?.cancel();
    _toastTimer = null;
    _toastEntry?.remove();
    _toastEntry = null;
  }

  void _showCustomToast(String message, {bool isWarning = true}) {
    if (!mounted) return;

    _removeCustomToast();

    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;

    final bottomPadding = MediaQuery.of(context).padding.bottom;

    final Color borderColor = isWarning ? const Color(0xFFFFD6A6) : const Color(0xFFD8E4FF);
    final Color iconBg = isWarning ? const Color(0xFFFFF3E0) : const Color(0xFFEFF2FF);
    final Color iconColor = isWarning ? const Color(0xFFFF8A00) : const Color(0xFF2260FF);
    final Color textColor = isWarning ? const Color(0xFFE06B00) : const Color(0xFF2260FF);
    final IconData iconData = isWarning ? Icons.priority_high_rounded : Icons.check_rounded;

    _toastEntry = OverlayEntry(
      builder: (context) {
        return Positioned(
          left: 20,
          right: 20,
          bottom: bottomPadding + 26,
          child: IgnorePointer(
            ignoring: true,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 16 * (1 - value)),
                    child: child,
                  ),
                );
              },
              child: Material(
                color: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 13,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: borderColor,
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 14,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: iconBg,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          iconData,
                          color: iconColor,
                          size: 17,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          message,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 14,
                            height: 1.35,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    overlay.insert(_toastEntry!);

    _toastTimer = Timer(const Duration(milliseconds: 2200), () {
      _removeCustomToast();
    });
  }

  bool get isEmailFilled =>
      nameController.text.trim().isNotEmpty &&
      emailController.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();

    nameController.addListener(() {
      setState(() {});
    });

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
        _showCustomToast(AppLanguage.t('verification_expired')); // '인증번호가 만료되었습니다. 다시 요청해주세요.'
      } else {
        setState(() => _remainingSeconds--);
      }
    });
  }

  @override
  void dispose() {
    _removeCustomToast();
    _timer?.cancel();
    nameController.dispose();
    emailController.dispose();
    codeController.dispose();
    super.dispose();
  }

  // 인증 코드 발송 — POST /api/email/send
  Future<void> _requestVerification() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    if (name.isEmpty || email.isEmpty) return;

    setState(() => _isSendingCode = true);
    final result = await AuthService.sendEmailVerification(
      email: email,
      purpose: 'find-id',
      name: name,
    );
    if (!mounted) return;
    setState(() => _isSendingCode = false);

    if (result.success) {
      _startTimer();
      _showCustomToast(AppLanguage.t('verification_sent'), isWarning: false); // '인증번호가 이메일로 발송되었습니다.'
    } else {
      _showCustomToast(result.message ?? AppLanguage.t('verification_send_failed')); // '인증 코드 발송에 실패했습니다.'
    }
  }

  // 아이디 찾기 확인 — POST /api/auth/find-id
  Future<void> _confirmFindId() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final code = codeController.text.trim();

    if (name.isEmpty || email.isEmpty || code.isEmpty) {
      _showCustomToast(AppLanguage.t('find_id_empty_fields')); // '이름, 이메일, 인증번호를 모두 입력해주세요.'
      return;
    }

    setState(() => _isLoading = true);
    final result = await AuthService.findId(
      name: name,
      email: email,
      verificationCode: code,
    );
    if (!mounted) return;
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
      _showCustomToast(result.message ?? AppLanguage.t('find_id_not_found')); // '아이디를 찾을 수 없습니다.'
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
                        Expanded(
                          child: Center(
                            child: Text(
                              AppLanguage.t('find_id_title'), // '아이디 찾기'
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

                    Center(
                      child: Text(
                        AppLanguage.t('find_id_subtitle'), // '아이디 확인을 위해 본인 확인이 필요합니다'
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF9AA7E8),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    const SizedBox(height: 56),

                    Text(
                      AppLanguage.t('name_label'), // '이름'
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildInputField(
                      controller: nameController,
                      hintText: AppLanguage.t('name_hint'), // '이름을 입력하세요'
                    ),

                    const SizedBox(height: 28),

                    Text(
                      AppLanguage.t('profile_email'), // '이메일'
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildEmailField(),

                    const SizedBox(height: 28),

                    Text(
                      AppLanguage.t('verification_code_label'), // '인증번호'
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
                          hintText: AppLanguage.t('verification_code_hint'), // '인증번호를 입력하세요'
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
                            : Text(
                               AppLanguage.t('confirm'), // '확인'
                                style: const TextStyle(
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
                      Text(
                        AppLanguage.t('find_id_title'), // '아이디 찾기'
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF8EA0F5),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        ' | ',
                        style: TextStyle(
                          color: Color(0xFF8EA0F5),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      GestureDetector(
                        onTap: _goToFindPasswordScreen,
                        child: Text(
                          AppLanguage.t('find_password'), // '비밀번호 찾기'
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF8EA0F5),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        ' | ',
                        style: TextStyle(
                          color: Color(0xFF8EA0F5),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      GestureDetector(
                        onTap: _goToSignUpScreen,
                        child: Text(
                          AppLanguage.t('sign_up'), // '회원가입'
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
                    children: [
                      Icon(
                        Icons.lock,
                        size: 16,
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
              decoration: InputDecoration(
                hintText: AppLanguage.t('email_hint'), // '이메일을 입력하세요'
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
              width: 112,
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
                      _isTimerRunning ? AppLanguage.t('resend') : AppLanguage.t('request_verification'), // '재전송'
                      style: const TextStyle(
                        fontSize: 12,
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
