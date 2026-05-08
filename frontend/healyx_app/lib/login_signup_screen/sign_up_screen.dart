// 회원가입 화면 구현
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';

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
  bool hasInsurance = false;

  // 상태 플래그
  bool _isLoading = false;
  bool _isEmailChecked = false;
  bool _isUsernameChecked = false;

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
    nameController.dispose();
    emailController.dispose();
    idController.dispose();
    passwordController.dispose();
    passwordCheckController.dispose();
    nicknameController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // 이메일 중복확인
  Future<void> _handleCheckEmail() async {
    final email = emailController.text.trim();
    if (email.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final isAvailable = await AuthService.checkEmailAvailable(email);
      if (!mounted) return;
      if (isAvailable) {
        setState(() => _isEmailChecked = true);
        _showMessage('사용 가능한 이메일입니다.');
      } else {
        _showMessage('이미 사용 중인 이메일입니다.');
      }
    } catch (e) {
      if (!mounted) return;
      _showMessage(e.toString().replaceFirst('Exception: ', ''));
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
        _showMessage('사용 가능한 아이디입니다.');
      } else {
        _showMessage('이미 사용 중인 아이디입니다.');
      }
    } catch (e) {
      if (!mounted) return;
      _showMessage(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 회원가입 처리
  Future<void> _handleRegister() async {
    if (nameController.text.trim().isEmpty) {
      _showMessage('이름을 입력해주세요.');
      return;
    }
    if (!_isEmailChecked) {
      _showMessage('이메일 중복확인을 완료해주세요.');
      return;
    }
    if (!_isUsernameChecked) {
      _showMessage('아이디 중복확인을 완료해주세요.');
      return;
    }
    if (passwordController.text.isEmpty) {
      _showMessage('비밀번호를 입력해주세요.');
      return;
    }
    if (passwordController.text != passwordCheckController.text) {
      _showMessage('비밀번호가 일치하지 않습니다.');
      return;
    }
    if (nicknameController.text.trim().isEmpty) {
      _showMessage('닉네임을 입력해주세요.');
      return;
    }

    // 생년월일 조합 (선택사항)
    String? birthDate;
    if (selectedYear != 'yyyy' && selectedMonth != 'mm' && selectedDay != 'dd') {
      birthDate = '$selectedYear-$selectedMonth-$selectedDay';
    }

    // 성별 변환: 남성 → M, 여성 → F
    String? gender;
    if (selectedGender == '남성') {
      gender = 'M';
    } else if (selectedGender == '여성') {
      gender = 'F';
    }

    // SharedPreferences에서 선호 언어 조회 (기본값: ko)
    final prefs = await SharedPreferences.getInstance();
    final preferredLanguage = prefs.getString('selectedLanguage') ?? 'ko';

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
        _showMessage('회원가입이 완료되었습니다.');
        Navigator.pop(context);
      } else {
        _showMessage(result.message ?? '회원가입에 실패했습니다.');
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
    final days = [
      'dd',
      ...List.generate(31, (index) => '${index + 1}'.padLeft(2, '0')),
    ];

    final bool isEmailEntered = emailController.text.trim().isNotEmpty;
    final bool isIdEntered = idController.text.trim().isNotEmpty;

    // 이메일 버튼 상태
    final String emailButtonText = _isEmailChecked ? '확인완료' : '중복확인';
    final bool emailButtonEnabled = isEmailEntered && !_isEmailChecked && !_isLoading;

    // 아이디 버튼 상태
    final String usernameButtonText = _isUsernameChecked ? '확인완료' : '중복확인';
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
                      const Expanded(
                        child: Center(
                          child: Text(
                            '회원가입',
                            style: TextStyle(
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
                  const Text(
                    '이름',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildInputField(
                    controller: nameController,
                    hintText: '이름을 입력하세요',
                  ),
                  const SizedBox(height: 18),

                  // 이메일
                  const Text(
                    '이메일',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildCheckRowField(
                    controller: emailController,
                    hintText: '이메일을 입력하세요',
                    buttonText: emailButtonText,
                    isEnabled: emailButtonEnabled,
                    onTap: _handleCheckEmail,
                  ),
                  const SizedBox(height: 18),

                  // 아이디
                  const Text(
                    '아이디',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildCheckRowField(
                    controller: idController,
                    hintText: '아이디를 입력하세요',
                    buttonText: usernameButtonText,
                    isEnabled: usernameButtonEnabled,
                    onTap: _handleCheckUsername,
                  ),
                  const SizedBox(height: 18),

                  // 비밀번호
                  const Text(
                    '비밀번호',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildInputField(
                    controller: passwordController,
                    hintText: '비밀번호를 입력하세요',
                    obscureText: true,
                  ),
                  const SizedBox(height: 18),

                  // 비밀번호 확인
                  const Text(
                    '비밀번호 확인',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildInputField(
                    controller: passwordCheckController,
                    hintText: '비밀번호를 입력하세요',
                    obscureText: true,
                  ),
                  const SizedBox(height: 18),

                  // 닉네임
                  const Text(
                    '닉네임',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildInputField(
                    controller: nicknameController,
                    hintText: '닉네임을 입력하세요',
                  ),
                  const SizedBox(height: 18),

                  // 생년월일
                  const Text(
                    '생년월일:',
                    style: TextStyle(
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
                          onChanged: (value) => setState(() => selectedYear = value!),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildDropdownBox(
                          value: selectedMonth,
                          items: months,
                          onChanged: (value) => setState(() => selectedMonth = value!),
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
                          const Text(
                            '성별',
                            style: TextStyle(
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
                          const Text(
                            '건강보험 여부:',
                            style: TextStyle(
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
                      child: const Text(
                        '회원가입',
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
            gender,
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