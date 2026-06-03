// 회원가입 화면 구현
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../app_language.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController idController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController passwordCheckController = TextEditingController();
  final TextEditingController nicknameController = TextEditingController();

  String selectedYear = 'yyyy';
  String selectedMonth = 'mm';
  String selectedDay = 'dd';
  String selectedGender = '';

  // 선택된 연/월에 따른 최대 일 수 계산
  int _maxDaysInMonth(String year, String month) {
    if (month == 'mm') return 31;
    final m = int.tryParse(month) ?? 1;
    final y = int.tryParse(year) ?? 2000;
    // 윤년 처리 포함
    return DateTime(y, m + 1, 0).day;
  }

  bool hasInsurance = false;

  // 상태 플래그
  bool _isLoading = false;
  bool _isEmailChecked = false;
  bool _isUsernameChecked = false;

  OverlayEntry? _toastEntry;
  Timer? _toastTimer;

  @override
  void initState() {
    super.initState();
    // 이메일 변경 시 중복확인 상태 초기화
    emailController.addListener(() {
      if (_isEmailChecked) {
        setState(() => _isEmailChecked = false);
      }
    });
    // 아이디 변경 시 중복확인 상태 초기화
    idController.addListener(() {
      if (_isUsernameChecked) {
        setState(() => _isUsernameChecked = false);
      }
    });
  }

  @override
  void dispose() {
    _removeCustomToast();
    nameController.dispose();
    emailController.dispose();
    idController.dispose();
    passwordController.dispose();
    passwordCheckController.dispose();
    nicknameController.dispose();
    super.dispose();
  }

  void _removeCustomToast() {
    _toastTimer?.cancel();
    _toastTimer = null;
    _toastEntry?.remove();
    _toastEntry = null;
  }

  // 커뮤니티 글쓰기 화면과 동일한 스타일의 토스트 (isWarning=true: 주황, false: 파랑)
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

  // 이메일 중복확인
  Future<void> _handleCheckEmail() async {
    final email = emailController.text.trim();
    if (email.isEmpty) return;

    // 이메일 형식 검증
    final emailRegex = RegExp(r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$');
    if (!emailRegex.hasMatch(email)) {
      _showCustomToast(AppLanguage.t('profile_error_email_invalid'));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final isAvailable = await AuthService.checkEmailAvailable(email);
      if (!mounted) return;
      if (isAvailable) {
        setState(() => _isEmailChecked = true);
        _showCustomToast(AppLanguage.t('email_available'), isWarning: false);
      } else {
        _showCustomToast(AppLanguage.t('email_taken'));
      }
    } catch (e) {
      if (!mounted) return;
      _showCustomToast(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 아이디 중복확인
  Future<void> _handleCheckUsername() async {
    final username = idController.text.trim();
    if (username.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final isAvailable = await AuthService.checkUsernameAvailable(username);
      if (!mounted) return;
      if (isAvailable) {
        setState(() => _isUsernameChecked = true);
        _showCustomToast(AppLanguage.t('username_available'), isWarning: false);
      } else {
        _showCustomToast(AppLanguage.t('username_taken'));
      }
    } catch (e) {
      if (!mounted) return;
      _showCustomToast(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 회원가입 처리
  Future<void> _handleRegister() async {
    if (nameController.text.trim().isEmpty) {
      _showCustomToast(AppLanguage.t('signup_error_name'));
      return;
    }
    if (nameController.text.trim().length > 50) {
      _showCustomToast(AppLanguage.t('name_too_long'));
      return;
    }
    if (!_isEmailChecked) {
      _showCustomToast(AppLanguage.t('signup_error_email_check'));
      return;
    }
    if (!_isUsernameChecked) {
      _showCustomToast(AppLanguage.t('signup_error_id_check'));
      return;
    }
    if (passwordController.text.isEmpty) {
      _showCustomToast(AppLanguage.t('signup_error_password'));
      return;
    }
    // 비밀번호 형식 검사: 영문+숫자+특수기호 조합, 7~12자
    final passwordRegex = RegExp(
      r'^(?=.*[a-zA-Z])(?=.*\d)(?=.*[!@#$%^&*()\-_+=\[\]{}|;:,.<>?/~]).{7,12}$',
    );
    if (!passwordRegex.hasMatch(passwordController.text)) {
      _showCustomToast(AppLanguage.t('signup_error_password_rule'));
      return;
    }
    if (passwordController.text != passwordCheckController.text) {
      _showCustomToast(AppLanguage.t('pw_error'));
      return;
    }
    if (nicknameController.text.trim().isEmpty) {
      _showCustomToast(AppLanguage.t('signup_error_nickname'));
      return;
    }
    if (nicknameController.text.trim().length > 10) {
      _showCustomToast(AppLanguage.t('signup_error_nickname_too_long'));
      return;
    }
    if (selectedGender.isEmpty ||
        selectedYear == 'yyyy' ||
        selectedMonth == 'mm' ||
        selectedDay == 'dd') {
      _showCustomToast(AppLanguage.t('signup_error_gender_birth_required'));
      return;
    }

    // 생년월일 조합
    final String birthDate = '$selectedYear-$selectedMonth-$selectedDay';

    // 성별 변환: 남성 → M, 여성 → F
    final String gender = selectedGender == '남성' ? 'M' : 'F';

    // SharedPreferences에서 선호 언어 조회 (기본값: ko)
    final prefs = await SharedPreferences.getInstance();
    final preferredLanguage = prefs.getString('language_pref') ?? 'ko';

    setState(() => _isLoading = true);
    try {
      final result = await AuthService.register(
        realName: nameController.text.trim(),
        email: emailController.text.trim(),
        username: idController.text.trim(),
        password: passwordController.text,
        passwordConfirm: passwordCheckController.text,
        nickname: nicknameController.text.trim(),
        birthDate: birthDate,
        gender: gender,
        hasHealthInsurance: hasInsurance,
        preferredLanguage: preferredLanguage,
      );
      if (!mounted) return;
      if (result.success) {
        _showCustomToast(AppLanguage.t('signup_success'), isWarning: false);
        Navigator.pop(context);
      } else {
        _showCustomToast(result.message ?? AppLanguage.t('signup_failed'));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final years = [
      'yyyy',
      ...List.generate(100, (index) => '${2025 - index}'),
    ];
    final months = [
      'mm',
      ...List.generate(12, (index) => '${index + 1}'.padLeft(2, '0')),
    ];
    final maxDays = _maxDaysInMonth(selectedYear, selectedMonth);
    final days = [
      'dd',
      ...List.generate(maxDays, (index) => '${index + 1}'.padLeft(2, '0')),
    ];

    final bool isEmailEntered = emailController.text.trim().isNotEmpty;
    final bool isIdEntered = idController.text.trim().isNotEmpty;

    // 이메일 버튼 상태
    final String emailButtonText = _isEmailChecked
        ? AppLanguage.t('check_done') // '확인완료'
        : AppLanguage.t('check_duplicate'); // '중복확인'
    final bool emailButtonEnabled = isEmailEntered && !_isEmailChecked && !_isLoading;

    // 아이디 버튼 상태
    final String usernameButtonText = _isUsernameChecked
        ? AppLanguage.t('check_done') // '확인완료'
        : AppLanguage.t('check_duplicate'); // '중복확인'
    final bool usernameButtonEnabled = isIdEntered && !_isUsernameChecked && !_isLoading;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 8, 22, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.arrow_back_ios_new,
                          size: 20,
                          color: Color(0xFF4E7CFF),
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            AppLanguage.t('sign_up'), // '회원가입'
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
                  const SizedBox(height: 18),

                  // 이름
                  Text(
                    AppLanguage.t('name_label'), // '이름'
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildInputField(
                    controller: nameController,
                    hintText: AppLanguage.t('name_hint'), // '이름을 입력하세요'
                  ),
                  const SizedBox(height: 18),

                  // 이메일
                  Text(
                    AppLanguage.t('profile_email'), // '이메일'
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildCheckRowField(
                    controller: emailController,
                    hintText: AppLanguage.t('email_hint'), // '이메일을 입력하세요'
                    buttonText: emailButtonText,
                    isEnabled: emailButtonEnabled,
                    onTap: _handleCheckEmail,
                  ),
                  const SizedBox(height: 18),

                  // 아이디
                  Text(
                    AppLanguage.t('username_label'), // '아이디'
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildCheckRowField(
                    controller: idController,
                    hintText: AppLanguage.t('username_hint'), // '아이디를 입력하세요'
                    buttonText: usernameButtonText,
                    isEnabled: usernameButtonEnabled,
                    onTap: _handleCheckUsername,
                  ),
                  const SizedBox(height: 18),

                  // 비밀번호
                  Text(
                    AppLanguage.t('password_label'), // '비밀번호'
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildInputField(
                    controller: passwordController,
                    hintText: AppLanguage.t('password_hint'), // '비밀번호를 입력하세요'
                    obscureText: true,
                  ),
                  const SizedBox(height: 18),

                  // 비밀번호 확인
                  Text(
                    AppLanguage.t('password_confirm_label'), // '비밀번호 확인'
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildInputField(
                    controller: passwordCheckController,
                    hintText: AppLanguage.t('password_hint'), // '비밀번호를 입력하세요'
                    obscureText: true,
                  ),
                  const SizedBox(height: 18),

                  // 닉네임
                  Text(
                     AppLanguage.t('profile_nickname'), // '닉네임'
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildInputField(
                    controller: nicknameController,
                    hintText: AppLanguage.t('nickname_hint'), // '닉네임을 입력하세요'
                  ),
                  const SizedBox(height: 18),

                  // 생년월일
                  Text(
                    AppLanguage.t('birthdate_label'), // '생년월일:'
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDropdownBox(
                          value: selectedYear,
                          items: years,
                          onChanged: (value) {
                            setState(() {
                              selectedYear = value!;
                              // 연도 변경 후 현재 선택된 일이 유효한지 검사
                              final newMax = _maxDaysInMonth(selectedYear, selectedMonth);
                              final currentDay = int.tryParse(selectedDay);
                              if (currentDay != null && currentDay > newMax) {
                                selectedDay = 'dd';
                              }
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildDropdownBox(
                          value: selectedMonth,
                          items: months,
                          onChanged: (value) {
                            setState(() {
                              selectedMonth = value!;
                              // 월 변경 후 현재 선택된 일이 유효한지 검사
                              final newMax = _maxDaysInMonth(selectedYear, selectedMonth);
                              final currentDay = int.tryParse(selectedDay);
                              if (currentDay != null && currentDay > newMax) {
                                selectedDay = 'dd';
                              }
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildDropdownBox(
                          value: selectedDay,
                          items: days,
                          onChanged: (value) => setState(() => selectedDay = value!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // 성별 + 건강보험
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            AppLanguage.t('gender_label'), // '성별'
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(width: 12),
                          _buildGenderRadio('남성'),
                          const SizedBox(width: 14),
                          _buildGenderRadio('여성'),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Text(
                            AppLanguage.t('insurance_label'), // '건강보험 여부:'
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Switch(
                            value: hasInsurance,
                            onChanged: (value) => setState(() => hasInsurance = value),
                            activeColor: const Color(0xFF4E7CFF),
                            activeTrackColor: const Color(0xFFBFCBFF),
                            inactiveThumbColor: Colors.white,
                            inactiveTrackColor: const Color(0xFFD9DDE8),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 26),

                  // 회원가입 버튼
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleRegister,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2260FF),
                        disabledBackgroundColor: const Color(0xFFBFCBFF),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      child: Text(
                        AppLanguage.t('sign_up'), // '회원가입'
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

            // 전체 화면 로딩 오버레이
            if (_isLoading)
              const Positioned.fill(
                child: ColoredBox(
                  color: Color(0x33000000),
                  child: Center(
                    child: CircularProgressIndicator(color: Color(0xFF4E7CFF)),
                  ),
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
    bool obscureText = false,
  }) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: const Color(0xFFEFF2FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(
            color: Color(0xFFB0B9F5),
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildCheckRowField({
    required TextEditingController controller,
    required String hintText,
    required String buttonText,
    required bool isEnabled,
    required VoidCallback onTap,
  }) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 50,
            decoration: const BoxDecoration(
              color: Color(0xFFEFF2FF),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
            ),
            child: TextField(
              controller: controller,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: const TextStyle(
                  color: Color(0xFFB0B9F5),
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
              ),
            ),
          ),
        ),
        GestureDetector(
          onTap: isEnabled ? onTap : null,
          child: Container(
            width: 86,
            height: 50,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isEnabled
                  ? const Color(0xFF98A9F4)
                  : const Color(0xFFCCD5FB),
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: Text(
              buttonText,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownBox({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF2FF),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(
            Icons.arrow_drop_down,
            color: Color(0xFF7F90D9),
          ),
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF7F90D9),
            fontWeight: FontWeight.w600,
          ),
          items: items.map((item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildGenderRadio(String gender) {
    return GestureDetector(
      onTap: () => setState(() => selectedGender = gender),
      child: Row(
        children: [
          Icon(
            selectedGender == gender
                ? Icons.radio_button_checked
                : Icons.radio_button_off,
            size: 20,
            color: const Color(0xFFB0B9F5),
          ),
          const SizedBox(width: 4),
          Text(
            gender == '남성'
                ? AppLanguage.t('gender_male') // '남성'
                : AppLanguage.t('gender_female'), // '여성'
            style: const TextStyle(
              fontSize: 15,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}