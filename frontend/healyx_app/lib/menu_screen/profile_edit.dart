// 프로필 편집 화면
// - GET /api/users/me : 로그인한 사용자 프로필 조회
// - PATCH /api/users/me/profile : 프로필 수정

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../app_language.dart';
import '../services/auth_service.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _nicknameController = TextEditingController();

  bool _hasInsurance = false;

  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchMyProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  // 이메일 형식 검사 함수
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$',
    );

    return emailRegex.hasMatch(email);
  }

  Future<void> _fetchMyProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = await AuthService.getAccessToken();

      if (token == null || token.isEmpty) {
        setState(() {
          _isLoading = false;
          _errorMessage = '로그인이 필요한 기능입니다.';
        });
        return;
      }

      final url = Uri.parse('${AuthService.baseUrl}/api/users/me');

      final response = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final decoded = utf8.decode(response.bodyBytes);
      final Map<String, dynamic> responseData = jsonDecode(decoded);

      if (response.statusCode == 200 && responseData['success'] == true) {
        final data = responseData['data'];

        setState(() {
          _nameController.text = data['name'] ?? data['realName'] ?? '';
          _emailController.text = data['email'] ?? '';
          _nicknameController.text = data['nickname'] ?? '';
          _hasInsurance = data['insuranceStatus'] == true;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = responseData['message'] ?? '프로필 정보를 불러오지 못했습니다.';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = '서버 연결에 실패했습니다. 잠시 후 다시 시도해주세요.';
      });
    }
  }

  Future<void> _updateMyProfile() async {
    final realName = _nameController.text.trim();
    final email = _emailController.text.trim();
    final nickname = _nicknameController.text.trim();

    if (realName.isEmpty) {
      _showSnackBar('실명을 입력해주세요.');
      return;
    }

    if (email.isEmpty) {
      _showSnackBar('이메일을 입력해주세요.');
      return;
    }

    if (!_isValidEmail(email)) {
      _showSnackBar('이메일 형식으로 작성해주세요.');
      return;
    }

    if (nickname.isEmpty) {
      _showSnackBar('닉네임을 입력해주세요.');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final token = await AuthService.getAccessToken();

      if (token == null || token.isEmpty) {
        _showSnackBar('로그인이 필요한 기능입니다.');
        setState(() {
          _isSaving = false;
        });
        return;
      }

      final url = Uri.parse('${AuthService.baseUrl}/api/users/me/profile');

      final requestBody = {
        'realName': realName,
        'email': email,
        'nickname': nickname,
        'insuranceStatus': _hasInsurance ? 'insured' : 'uninsured',
      };

      final response = await http.patch(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      final decoded = utf8.decode(response.bodyBytes);
      final Map<String, dynamic> responseData = jsonDecode(decoded);

      if (response.statusCode == 200 && responseData['success'] == true) {
        await _updateLocalProfileCache(
          name: realName,
          email: email,
          nickname: nickname,
          insuranceStatus: _hasInsurance,
        );

        if (!mounted) return;

        _showSnackBar(responseData['message'] ?? '프로필이 수정되었습니다.');

        Navigator.pop(context, true);
      } else {
        _showSnackBar(responseData['message'] ?? '프로필 수정에 실패했습니다.');
      }
    } catch (e) {
      _showSnackBar('서버 연결에 실패했습니다. 잠시 후 다시 시도해주세요.');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _updateLocalProfileCache({
    required String name,
    required String email,
    required String nickname,
    required bool insuranceStatus,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('name', name);
    await prefs.setString('email', email);
    await prefs.setString('nickname', nickname);
    await prefs.setBool('insuranceStatus', insuranceStatus);
  }

  void _showSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: Colors.black, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          AppLanguage.t('profile_title'), // '프로필 설정'
          style: const TextStyle(
            color: Color(0xFF2260FF),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF2260FF),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchMyProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2260FF),
                  foregroundColor: Colors.white,
                  elevation: 0,
                ),
                child: const Text('다시 시도'),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),

          Center(
            child: Container(
              width: 90,
              height: 90,
              decoration: const BoxDecoration(
                color: Color(0xFFCAD6FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_outline,
                size: 50,
                color: Color(0xFF2260FF),
              ),
            ),
          ),

          const SizedBox(height: 32),

          _buildLabel(AppLanguage.t('profile_name')),
          const SizedBox(height: 8),
          _buildEditableField(
            controller: _nameController,
            hintText: '실명을 입력해주세요',
          ),

          const SizedBox(height: 20),

          _buildLabel(AppLanguage.t('profile_email')),
          const SizedBox(height: 8),
          _buildEditableField(
            controller: _emailController,
            hintText: '이메일을 입력해주세요',
            keyboardType: TextInputType.emailAddress,
          ),

          const SizedBox(height: 20),

          _buildLabel(AppLanguage.t('profile_nickname')),
          const SizedBox(height: 8),
          _buildEditableField(
            controller: _nicknameController,
            hintText: '닉네임을 입력해주세요',
          ),

          const SizedBox(height: 8),
          const Divider(color: Color(0xFF2260FF), thickness: 1.2),

          const SizedBox(height: 20),

          _buildLabel(AppLanguage.t('profile_insurance')),
          const SizedBox(height: 12),

          Row(
            children: [
              Transform.scale(
                scale: 0.9,
                child: Switch(
                  value: _hasInsurance,
                  onChanged: (val) {
                    setState(() {
                      _hasInsurance = val;
                    });
                  },
                  activeColor: Colors.white,
                  activeTrackColor: const Color(0xFF2260FF),
                  inactiveThumbColor: Colors.white,
                  inactiveTrackColor: const Color(0xFFCCCCCC),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _hasInsurance ? '가입' : '미가입',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),
          const Divider(color: Color(0xFFE0E0E0), thickness: 1),

          const SizedBox(height: 36),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _updateMyProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2260FF),
                disabledBackgroundColor: const Color(0xFFB7C8FF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 0,
              ),
              child: _isSaving
                  ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
                  : Text(
                AppLanguage.t('save'),
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildEditableField({
    required TextEditingController controller,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 15, color: Colors.black87),
      decoration: InputDecoration(
        hintText: hintText,
        filled: true,
        fillColor: const Color(0xFFF2F2F7),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: Color(0xFF2260FF),
            width: 1.5,
          ),
        ),
      ),
    );
  }
}