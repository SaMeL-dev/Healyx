// 비밀번호 재설정 화면
// STEP 2. 새로운 비밀번호 설정
// 로그인 유효성 검사 실패 시 에러 메시지 노출 (true/false로 분기)
import 'package:flutter/material.dart';
import 'package:healyx_app/menu_screen/reset_password_screen/password_reset_success.dart';
import '../../app_language.dart';

class PasswordResetScreen extends StatefulWidget {
  const PasswordResetScreen({super.key});

  @override
  State<PasswordResetScreen> createState() => _PasswordResetScreenState();
}

class _PasswordResetScreenState extends State<PasswordResetScreen> {
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  // true: 유효성 검사 실패 / false: 기본 상태
  // TODO: 추후 API 연동 시 실제 검증 로직으로 교체
  final bool _hasNewError = false;
  final bool _hasConfirmError = false;

  // ── 색상 팔레트 ──────────────────────────
  static const Color mainBlue = Color(0xFF2260FF); // 메인 컬러
  static const Color midBlue = Color(0xFF6281E3); // 설명 텍스트
  static const Color lightBlue = Color(0xFFECF1FF); // 입력 필드 배경
  static const Color hintColor = Color(0xFF809CFF); // 힌트 텍스트
  // ─────────────────────────────────────────

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  InputDecoration _fieldDecoration({
    required String hint,
    required bool hasError,
    required bool obscure,
    required VoidCallback onToggleObscure,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: hintColor, fontSize: 14),
      filled: true,
      // 에러: 흰색 + 빨간 테두리 / 정상: lightBlue 배경
      fillColor: lightBlue,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide:
            hasError ? const BorderSide(color: Colors.red, width: 1.5) : BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide:
            hasError ? const BorderSide(color: Colors.red, width: 1.5) : BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: hasError
            ? const BorderSide(color: Colors.red, width: 1.5)
            : const BorderSide(color: mainBlue, width: 1.5),
      ),
      suffixIcon: IconButton(
        icon: Icon(
          obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          color: hintColor,
          size: 20,
        ),
        onPressed: onToggleObscure,
      ),
    );
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
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 32),

                    Center(
                      child: Text(
                        AppLanguage.t('pw_step2_title'), // 'STEP 2. 새로운 비밀번호 설정'
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
                        AppLanguage.t('pw_step2_desc'), // '안전한 계정 보호를 위해 새로운 비밀번호를 설정합니다'
                        style: TextStyle(color: midBlue, fontSize: 13),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // 새로운 비밀번호
                    Text(
                      AppLanguage.t('pw_new'), // '새로운 비밀번호'
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),

                    const SizedBox(height: 10),

                    TextField(
                      controller: _newPasswordController,
                      obscureText: _obscureNew,
                      style: const TextStyle(fontSize: 15, color: Colors.black),
                      decoration: _fieldDecoration(
                        hint: AppLanguage.t('pw_new_hint'), // '새 비밀번호를 입력하세요'
                        hasError: _hasNewError,
                        obscure: _obscureNew,
                        onToggleObscure: () =>
                            setState(() => _obscureNew = !_obscureNew),
                      ),
                    ),

                    const SizedBox(height: 6),

                    // 힌트 or 에러 (_hasNewError = false 로 바꾸면 빨간색)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_hasNewError)
                          const Icon(Icons.error, color: Colors.red, size: 14),

                        if (_hasNewError)
                          const SizedBox(width: 4),

                        Expanded(
                          child: Text(
                            AppLanguage.t('pw_format_hint'),
                            // '영문, 숫자, 특수문자(!@#+=)를 포함해주세요.'
                            style: TextStyle(
                              color: _hasNewError ? Colors.red : midBlue,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // 새로운 비밀번호 확인
                    Text(
                      AppLanguage.t('pw_new_confirm'), // '새로운 비밀번호 확인'
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),

                    const SizedBox(height: 10),

                    TextField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirm,
                      style: const TextStyle(fontSize: 15, color: Colors.black),
                      decoration: _fieldDecoration(
                        hint: AppLanguage.t('pw_new_confirm_hint'),
                        // '새 비밀번호를 다시 한 번 입력하세요'
                        hasError: _hasConfirmError,
                        obscure: _obscureConfirm,
                        onToggleObscure: () =>
                            setState(() => _obscureConfirm = !_obscureConfirm),
                      ),
                    ),

                    // 에러 메시지 (_hasConfirmError = false 로 바꾸면 보임)
                    if (_hasConfirmError) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.error, color: Colors.red, size: 14),
                          SizedBox(width: 4),
                          Text(
                            AppLanguage.t('pw_error'),
                            style: TextStyle(color: Colors.red, fontSize: 12),
                          ), // '비밀번호가 일치하지 않습니다.'
                        ],
                      ),
                    ],

                    const SizedBox(height: 32),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () {
                          // TODO: API 연동 시 실제 검증 후 이동
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const PasswordResetSuccessScreen(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: mainBlue,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: Text(
                          AppLanguage.t('confirm'),
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ), // '확인'
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
                    AppLanguage.t('privacy_notice'),
                    style: TextStyle(fontSize: 12, color: midBlue),
                  ), // '개인정보는 안전하게 보호됩니다.'
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}