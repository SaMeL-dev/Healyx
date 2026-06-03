// 로그인 화면 구현
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:healyx_app/app_language.dart';

import '../login_signup_screen/sign_up_screen.dart';
import '../find_account_screen/find_id_screen.dart';
import '../find_account_screen/find_password_screen.dart';
import '../Main_Screen.dart'; // MainScreen 파일명에 맞게 경로 확인
import '../services/auth_service.dart';

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
  bool isLoading = false;

  String? idErrorText;
  String? passwordErrorText;
  String? loginErrorText;

  // 로그인 실패 잠금 관련 상태값
  int loginFailCount = 0;
  bool isLoginLocked = false;
  int lockRemainingSeconds = 0;
  Timer? lockTimer;

  Future<void> _handleLogin() async {
    if (isLoginLocked) {
      setState(() {
        loginErrorText = _getLoginLockedMessage();
      });
      return;
    }

    final String id = idController.text.trim();
    final String password = passwordController.text.trim();

    setState(() {
      idErrorText = null;
      passwordErrorText = null;
      loginErrorText = null;
    });

    bool hasError = false;

    if (id.isEmpty) {
      idErrorText = AppLanguage.t('required_field'); // '필수 항목입니다.'
      hasError = true;
    }

    if (password.isEmpty) {
      passwordErrorText = AppLanguage.t('required_field'); // '필수 항목입니다.'
      hasError = true;
    }

    if (hasError) {
      setState(() {});
      return;
    }

    setState(() {
      isLoading = true;
    });

    final result = await AuthService.login(
      username: id,
      password: password,
      autoLogin: isAutoLogin,
    );

    if (!mounted) return;

    setState(() {
      isLoading = false;
    });

    if (result.success) {
      _resetLoginFailState();

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const MainScreen(
            isLoggedIn: true,
          ),
        ),
      );
    } else {
      final bool shouldCountFailure = _shouldCountLoginFailure(result.message);

      if (shouldCountFailure) {
        loginFailCount++;

        if (loginFailCount >= 5) {
          _startLoginLock();
          return;
        }
      }

      setState(() {
        loginErrorText = _getLoginErrorMessage(result.message);
      });
    }
  }

  bool _shouldCountLoginFailure(String? message) {
    final String? trimmedMessage = message?.trim();

    // 서버 연결 실패나 토큰 오류는 사용자의 로그인 정보 오입력으로 보지 않음
    if (trimmedMessage == AppLanguage.t('server_error') ||
        trimmedMessage == AppLanguage.t('auth_token_error')) {
      return false;
    }

    return true;
  }

  void _startLoginLock() {
    lockTimer?.cancel();

    setState(() {
      isLoginLocked = true;
      lockRemainingSeconds = 30;
      loginErrorText = _getLoginLockedMessage();
    });

    lockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (lockRemainingSeconds <= 1) {
        timer.cancel();

        setState(() {
          isLoginLocked = false;
          lockRemainingSeconds = 0;
          loginFailCount = 0;
          loginErrorText = null;
        });

        return;
      }

      setState(() {
        lockRemainingSeconds--;
      });
    });
  }

  void _resetLoginFailState() {
    lockTimer?.cancel();
    lockTimer = null;
    loginFailCount = 0;
    isLoginLocked = false;
    lockRemainingSeconds = 0;
    loginErrorText = null;
  }

  String _getLoginErrorMessage(String? message) {
    final String? trimmedMessage = message?.trim();

    // 서버 연결 실패, 토큰 오류처럼 로그인 정보 불일치가 아닌 경우는 기존 메시지 유지
    if (trimmedMessage == AppLanguage.t('server_error') ||
        trimmedMessage == AppLanguage.t('auth_token_error')) {
      return trimmedMessage!;
    }

    // 아이디가 없거나, 비밀번호가 틀렸거나, 서버에서 User not found를 내려줘도
    // 화면에는 다국어 처리된 공통 로그인 실패 문구만 표시
    return AppLanguage.t('login_error');
  }

  String _getLoginLockedMessage() {
    return AppLanguage.t('login_locked_message');
  }

  String _formatLockTimer() {
    final int minutes = lockRemainingSeconds ~/ 60;
    final int seconds = lockRemainingSeconds % 60;

    final String minuteText = minutes.toString().padLeft(2, '0');
    final String secondText = seconds.toString().padLeft(2, '0');

    return '$minuteText:$secondText';
  }

  @override
  void dispose() {
    lockTimer?.cancel();
    idController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isLoginButtonDisabled = isLoading || isLoginLocked;

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
                        Expanded(
                          child: Center(
                            child: Text(
                              AppLanguage.t('login_title'), // '로그인'
                              style: const TextStyle(
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

                    Center(
                      child: Text(
                        AppLanguage.t('login_subtitle'), // '계정으로 로그인 하여 서비스를 이용하세요.'
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF9AA7E8),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    const SizedBox(height: 56),

                    Text(
                      AppLanguage.t('username_label'), // '아이디'
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),

                    _buildInputField(
                      controller: idController,
                      hintText: AppLanguage.t('username_hint'), // '아이디를 입력하세요'
                      obscureText: false,
                      errorText: idErrorText,
                    ),

                    const SizedBox(height: 28),

                    Text(
                      AppLanguage.t('password_label'), // '비밀번호'
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),

                    _buildInputField(
                      controller: passwordController,
                      hintText: AppLanguage.t('password_hint'), // '비밀번호를 입력하세요'
                      obscureText: isObscure,
                      errorText: passwordErrorText,
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
                            onChanged: isLoginLocked
                                ? null
                                : (value) {
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
                        Text(
                          AppLanguage.t('auto_login'), // '자동 로그인'
                          style: const TextStyle(
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
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned.fill(
                            child: ElevatedButton(
                              onPressed:
                              isLoginButtonDisabled ? null : _handleLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2260FF),
                                disabledBackgroundColor:
                                const Color(0xFF9AA7E8),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(28),
                                ),
                              ),
                              child: isLoading
                                  ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                                  : Text(
                                AppLanguage.t('login_title'), // '로그인'
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),

                          if (isLoginLocked)
                            Positioned(
                              right: 4,
                              top: -24,
                              child: Text(
                                _formatLockTimer(),
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.red,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    if (loginErrorText != null) ...[
                      const SizedBox(height: 10),
                      Center(
                        child: Text(
                          loginErrorText!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.red,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
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
                        text: AppLanguage.t('find_id_title'), // '아이디 찾기'
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const FindIdScreen(),
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
                        text: AppLanguage.t('find_password'), // '비밀번호 찾기'
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
                        text: AppLanguage.t('sign_up'), // '회원가입'
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
                    children: [
                      const Icon(
                        Icons.lock,
                        size: 16,
                        color: Color(0xFF9AA7E8),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        AppLanguage.t('privacy_notice'), // '개인정보는 안전하게 보호됩니다.'
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
    required bool obscureText,
    String? errorText,
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
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
            onChanged: (_) {
              if (isLoginLocked) {
                return;
              }

              if (errorText != null || loginErrorText != null) {
                setState(() {
                  if (controller == idController) {
                    idErrorText = null;
                  }

                  if (controller == passwordController) {
                    passwordErrorText = null;
                  }

                  loginErrorText = null;
                });
              }
            },
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
        ),

        if (errorText != null) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              errorText,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
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