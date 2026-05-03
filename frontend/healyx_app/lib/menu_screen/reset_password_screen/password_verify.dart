import 'package:flutter/material.dart';
import 'package:healyx_app/menu_screen/reset_password_screen/password_reset.dart';

class PasswordVerifyScreen extends StatefulWidget {
  const PasswordVerifyScreen({super.key});

  @override
  State<PasswordVerifyScreen> createState() => _PasswordVerifyScreenState();
}

class _PasswordVerifyScreenState extends State<PasswordVerifyScreen> {
  final TextEditingController _passwordController = TextEditingController();
  bool _obscureText = true;

  // true: 유효성 검사 실패 / false: 기본 상태
  // TODO: 추후 API 연동 시 실제 검증 로직으로 교체
  final bool _hasError = false;

  // ── 색상 팔레트 ──────────────────────────
  static const Color mainBlue   = Color(0xFF2260FF); // 메인 컬러
  static const Color midBlue    = Color(0xFF6281E3); // 설명 텍스트
  static const Color lightBlue  = Color(0xFFECF1FF); // 입력 필드 배경
  static const Color hintColor  = Color(0xFF809CFF); // 힌트 텍스트
  // ─────────────────────────────────────────

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
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

                    // 스텝 안내
                    const Center(
                      child: Text(
                        'STEP 1. 본인 인증',
                        style: TextStyle(color: mainBlue, fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Center(
                      child: Text(
                        '안전한 비밀번호 변경을 위해 본인 확인이 필요합니다.',
                        style: TextStyle(color: midBlue, fontSize: 13),
                      ),
                    ),

                    const SizedBox(height: 40),

                    const Text(
                      '기존 비밀번호',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black),
                    ),
                    const SizedBox(height: 10),

                    TextField(
                      controller: _passwordController,
                      obscureText: _obscureText,
                      style: const TextStyle(fontSize: 15, color: Colors.black),
                      decoration: InputDecoration(
                        hintText: '비밀번호를 입력하세요',
                        hintStyle: const TextStyle(color: hintColor, fontSize: 14),
                        filled: true,
                        // 에러: 흰색 + 빨간 테두리 / 정상: lightBlue 배경
                        fillColor: lightBlue,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: _hasError ? const BorderSide(color: Colors.red, width: 1.5) : BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: _hasError ? const BorderSide(color: Colors.red, width: 1.5) : BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: _hasError ? const BorderSide(color: Colors.red, width: 1.5) : const BorderSide(color: mainBlue, width: 1.5),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            color: hintColor,
                            size: 20,
                          ),
                          onPressed: () => setState(() => _obscureText = !_obscureText),
                        ),
                      ),
                    ),

                    // 에러 메시지 (_hasError = false 로 바꾸면 보임)
                    if (_hasError) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: const [
                          Icon(Icons.error, color: Colors.red, size: 14),
                          SizedBox(width: 4),
                          Text('비밀번호가 일치하지 않습니다.', style: TextStyle(color: Colors.red, fontSize: 12)),
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
                            MaterialPageRoute(builder: (_) => const PasswordResetScreen()),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: mainBlue,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        ),
                        child: const Text('확인', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
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