// 비밀번호 재설정 화면
// STEP 2. 새로운 비밀번호 설정
// API: PUT /api/auth/change-password (JWT 필요)

import 'package:flutter/material.dart';
import 'package:healyx_app/menu_screen/reset_password_screen/password_reset_success.dart';
import 'package:healyx_app/services/auth_service.dart';

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
  bool _hasNewError = false;
  bool _hasConfirmError = false;
  bool _isLoading = false;
  String _newErrorMessage = '영문, 숫자, 특수문자(!@#+=)를 포함해주세요.';
  String _confirmErrorMessage = '비밀번호가 일치하지 않습니다.';

  // ── 색상 팔레트 ──────────────────────────
  static const Color mainBlue  = Color(0xFF2260FF); // 메인 컬러
  static const Color midBlue   = Color(0xFF6281E3); // 설명 텍스트
  static const Color lightBlue = Color(0xFFECF1FF); // 입력 필드 배경
  static const Color hintColor = Color(0xFF809CFF); // 힌트 텍스트
  // ─────────────────────────────────────────

  // 비밀번호 정책: 영문 + 숫자 + 특수문자(!@#+=) 포함, 7~12자
  static final _passwordRegex = RegExp(r'^(?=.*[a-zA-Z])(?=.*\d)(?=.*[!@#+=])[a-zA-Z\d!@#+=]{7,12}$');

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool _validateInputs() {
    final newPw = _newPasswordController.text;
    final confirmPw = _confirmPasswordController.text;
    bool valid = true;

    if (!_passwordRegex.hasMatch(newPw)) {
      setState(() {
        _hasNewError = true;
        _newErrorMessage = '영문, 숫자, 특수문자(!@#+=)를 포함한 7~12자로 입력하세요.';
      });
      valid = false;
    } else {
      setState(() => _hasNewError = false);
    }

    if (newPw != confirmPw) {
      setState(() {
        _hasConfirmError = true;
        _confirmErrorMessage = '비밀번호가 일치하지 않습니다.';
      });
      valid = false;
    } else {
      setState(() => _hasConfirmError = false);
    }

    return valid;
  }

  Future<void> _changePassword() async {
    if (!_validateInputs()) return;

    setState(() => _isLoading = true);

    final result = await AuthService.changePassword(
      newPassword: _newPasswordController.text,
      confirmNewPassword: _confirmPasswordController.text,
    );

    if (!mounted) return;

    if (result.success) {
      // 비밀번호 변경 성공 — 서버에서 모든 Refresh Token 삭제됨, 로컬 토큰도 정리
      await AuthService.logout();
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PasswordResetSuccessScreen()),
      );
    } else {
      setState(() {
        _hasNewError = true;
        _newErrorMessage = result.message ?? '비밀번호 변경에 실패했습니다.';
      });
    }

    setState(() => _isLoading = false);
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
      fillColor: lightBlue,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: hasError ? const BorderSide(color: Colors.red, width: 1.5) : BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: hasError ? const BorderSide(color: Colors.red, width: 1.5) : BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: hasError ? const BorderSide(color: Colors.red, width: 1.5) : const BorderSide(color: mainBlue, width: 1.5),
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
        title: const Text(
          '비밀번호 재설정',
          style: TextStyle(color: mainBlue, fontSize: 20, fontWeight: FontWeight.w600),
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

                    const Center(
                      child: Text(
                        'STEP 2. 새로운 비밀번호 설정',
                        style: TextStyle(color: mainBlue, fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Center(
                      child: Text(
                        '안전한 계정 보호를 위해 새로운 비밀번호를 설정합니다',
                        style: TextStyle(color: midBlue, fontSize: 13),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // 새로운 비밀번호
                    const Text('새로운 비밀번호',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black)),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _newPasswordController,
                      obscureText: _obscureNew,
                      style: const TextStyle(fontSize: 15, color: Colors.black),
                      onChanged: (_) {
                        if (_hasNewError) setState(() => _hasNewError = false);
                      },
                      decoration: _fieldDecoration(
                        hint: '새 비밀번호를 입력하세요',
                        hasError: _hasNewError,
                        obscure: _obscureNew,
                        onToggleObscure: () => setState(() => _obscureNew = !_obscureNew),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (_hasNewError) const Icon(Icons.error, color: Colors.red, size: 14),
                        if (_hasNewError) const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            _hasNewError ? _newErrorMessage : '영문, 숫자, 특수문자(!@#+=)를 포함해주세요.',
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
                    const Text('새로운 비밀번호 확인',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black)),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirm,
                      style: const TextStyle(fontSize: 15, color: Colors.black),
                      onChanged: (_) {
                        if (_hasConfirmError) setState(() => _hasConfirmError = false);
                      },
                      decoration: _fieldDecoration(
                        hint: '새 비밀번호를 다시 한 번 입력하세요',
                        hasError: _hasConfirmError,
                        obscure: _obscureConfirm,
                        onToggleObscure: () => setState(() => _obscureConfirm = !_obscureConfirm),
                      ),
                    ),
                    if (_hasConfirmError) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.error, color: Colors.red, size: 14),
                          const SizedBox(width: 4),
                          Text(_confirmErrorMessage, style: const TextStyle(color: Colors.red, fontSize: 12)),
                        ],
                      ),
                    ],

                    const SizedBox(height: 32),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _changePassword,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: mainBlue,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: mainBlue.withOpacity(0.6),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                              )
                            : const Text('확인', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
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
                children: const [
                  Icon(Icons.lock_outline, size: 14, color: midBlue),
                  SizedBox(width: 6),
                  Text('개인정보는 안전하게 보호됩니다.', style: TextStyle(fontSize: 12, color: midBlue)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
