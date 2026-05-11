// 비밀번호 재설정 본인 인증 화면
// STEP 1. 기존 비밀번호 입력하여 본인 인증
// API: POST /api/auth/verify-current-password (JWT 필요)

import 'package:flutter/material.dart';
import 'package:healyx_app/menu_screen/reset_password_screen/password_reset.dart';
import '../../app_language.dart';
import 'package:healyx_app/services/auth_service.dart';

class PasswordVerifyScreen extends StatefulWidget {
  const PasswordVerifyScreen({super.key});

  @override
  State<PasswordVerifyScreen> createState() => _PasswordVerifyScreenState();
}

class _PasswordVerifyScreenState extends State<PasswordVerifyScreen> {
  final TextEditingController _passwordController = TextEditingController();
  bool _obscureText = true;
  bool _hasError = false;
  bool _isLoading = false;
  String _errorMessage = '';

  // ── 색상 팔레트 ──────────────────────────
  static const Color mainBlue = Color(0xFF2260FF); // 메인 컬러
  static const Color midBlue = Color(0xFF6281E3); // 설명 텍스트
  static const Color lightBlue = Color(0xFFECF1FF); // 입력 필드 배경
  static const Color hintColor = Color(0xFF809CFF); // 힌트 텍스트
  // ─────────────────────────────────────────

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _verifyPassword() async {
    final password = _passwordController.text.trim();
    if (password.isEmpty) {
      setState(() {
        _hasError = true;
        _errorMessage = AppLanguage.t('pw_enter_new'); // '비밀번호를 입력해주세요.'
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    final result = await AuthService.verifyCurrentPassword(password);

    if (!mounted) return;

    if (result.success) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PasswordResetScreen()),
      );
    } else {
      setState(() {
        _hasError = true;
        _errorMessage = result.message ?? AppLanguage.t('pw_mismatch'); // '비밀번호가 일치하지 않습니다.'
      });
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: Colors.black, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          AppLanguage.t('pw_reset_title'), // '비밀번호 재설정'
          style: TextStyle(
            color: mainBlue,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 32),

                    // 스텝 안내
                    Center(
                      child: Text(
                        AppLanguage.t('pw_step1_title'), // 'STEP 1. 본인 인증'
                        style: TextStyle(
                          color: mainBlue,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Center(
                      child: Text(
                        AppLanguage.t('pw_step1_desc'),
                        // '안전한 비밀번호 변경을 위해 본인 확인이 필요합니다.'
                        style: TextStyle(color: midBlue, fontSize: 13),
                      ),
                    ),

                    const SizedBox(height: 40),

                    Text(
                      AppLanguage.t('pw_current'), // '기존 비밀번호'
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 10),

                    TextField(
                      controller: _passwordController,
                      obscureText: _obscureText,
                      style:
                          const TextStyle(fontSize: 15, color: Colors.black),
                      onChanged: (_) {
                        if (_hasError) {
                          setState(() => _hasError = false);
                        }
                      },
                      decoration: InputDecoration(
                        hintText: AppLanguage.t('pw_hint'),
                        // '비밀번호를 입력하세요'
                        hintStyle: const TextStyle(
                          color: hintColor,
                          fontSize: 14,
                        ),
                        filled: true,
                        fillColor: lightBlue,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 15,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: _hasError
                              ? const BorderSide(
                                  color: Colors.red,
                                  width: 1.5,
                                )
                              : BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: _hasError
                              ? const BorderSide(
                                  color: Colors.red,
                                  width: 1.5,
                                )
                              : BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: _hasError
                              ? const BorderSide(
                                  color: Colors.red,
                                  width: 1.5,
                                )
                              : const BorderSide(
                                  color: mainBlue,
                                  width: 1.5,
                                ),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureText
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: hintColor,
                            size: 20,
                          ),
                          onPressed: () => setState(
                            () => _obscureText = !_obscureText,
                          ),
                        ),
                      ),
                    ),

                    // 에러 메시지
                    if (_hasError) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.error,
                            color: Colors.red,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _errorMessage,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 32),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _verifyPassword,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: mainBlue,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor:
                              mainBlue.withOpacity(0.6),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : Text(
                                AppLanguage.t('confirm'), // '확인'
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock_outline, size: 14, color: midBlue),
                  SizedBox(width: 6),
                  Text(
                    AppLanguage.t('privacy_notice'), // '개인정보는 안전하게 보호됩니다.'
                    style: TextStyle(fontSize: 12, color: midBlue),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}