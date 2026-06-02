// 프로필 편집 화면
// - GET /api/users/me : 로그인한 사용자 프로필 조회
// - PATCH /api/users/me/profile : 프로필 수정

import 'dart:async';
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

  OverlayEntry? _toastEntry;
  Timer? _toastTimer;

  @override
  void initState() {
    super.initState();
    _fetchMyProfile();
  }

  @override
  void dispose() {
    _removeCustomToast();
    _nameController.dispose();
    _emailController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  void _removeCustomToast() {
    _toastTimer?.cancel();
    _toastTimer = null;
    _toastEntry?.remove();
    _toastEntry = null;
  }

  // 커뮤니티 글쓰기 화면과 동일한 스타일의 경고 토스트
  void _showNameTooLongToast(String message) {
    if (!mounted) return;

    _removeCustomToast();

    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;

    final bottomPadding = MediaQuery.of(context).padding.bottom;

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
                      color: const Color(0xFFFFD6A6),
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
                        decoration: const BoxDecoration(
                          color: Color(0xFFFFF3E0),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.priority_high_rounded,
                          color: Color(0xFFFF8A00),
                          size: 17,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          message,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFFE06B00),
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
          _errorMessage = AppLanguage.t('profile_login_required');
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
          _errorMessage = AppLanguage.t('profile_load_failed');
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = AppLanguage.t('server_connection_failed');
      });
    }
  }

  Future<void> _updateMyProfile() async {
    final realName = _nameController.text.trim();
    final email = _emailController.text.trim();
    final nickname = _nicknameController.text.trim();

    if (realName.isEmpty) {
      _showProfileGuide(AppLanguage.t('profile_error_name_empty'));
      return;
    }

    if (realName.length > 50) {
      _showNameTooLongToast(AppLanguage.t('name_too_long'));
      return;
    }

    if (email.isEmpty) {
      _showProfileGuide(AppLanguage.t('profile_error_email_empty'));
      return;
    }

    if (!_isValidEmail(email)) {
      _showProfileGuide(AppLanguage.t('profile_error_email_invalid'));
      return;
    }

    if (nickname.isEmpty) {
      _showProfileGuide(AppLanguage.t('profile_error_nickname_empty'));
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final token = await AuthService.getAccessToken();

      if (token == null || token.isEmpty) {
        _showAppNotification(AppLanguage.t('profile_login_required'));
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

        _showAppNotification(AppLanguage.t('profile_update_success'));

        Navigator.pop(context, true);
      } else {
        _showAppNotification(AppLanguage.t('profile_update_failed'));
      }
    } catch (e) {
      _showAppNotification(AppLanguage.t('server_connection_failed'));
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

  void _showProfileGuide(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          elevation: 0,
          backgroundColor: Colors.transparent,
          margin: const EdgeInsets.only(
            left: 24,
            right: 24,
            bottom: 24,
          ),
          padding: EdgeInsets.zero,
          content: _buildProfileGuideContent(message),
        ),
      );
  }

  void _showAppNotification(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          elevation: 0,
          backgroundColor: Colors.transparent,
          margin: const EdgeInsets.only(
            left: 28,
            right: 28,
            bottom: 42,
          ),
          padding: EdgeInsets.zero,
          content: _buildAppNotificationContent(message),
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
          AppLanguage.t('profile_title'),
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
                child: Text(AppLanguage.t('retry')),
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
            hintText: AppLanguage.t('profile_name_hint'),
          ),

          const SizedBox(height: 20),

          _buildLabel(AppLanguage.t('profile_email')),
          const SizedBox(height: 8),
          _buildEditableField(
            controller: _emailController,
            hintText: AppLanguage.t('profile_email_hint'),
            keyboardType: TextInputType.emailAddress,
          ),

          const SizedBox(height: 20),

          _buildLabel(AppLanguage.t('profile_nickname')),
          const SizedBox(height: 8),
          _buildEditableField(
            controller: _nicknameController,
            hintText: AppLanguage.t('profile_nickname_hint'),
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
                _hasInsurance
                    ? AppLanguage.t('profile_insured')
                    : AppLanguage.t('profile_uninsured'),
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

  Widget _buildProfileGuideContent(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8F1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFFFB066),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: const BoxDecoration(
              color: Color(0xFFFFE8CC),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text(
                '!',
                style: TextStyle(
                  color: Color(0xFFF26A21),
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFFF26A21),
                fontSize: 14,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppNotificationContent(String message) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(
        minHeight: 58,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE1E9FF),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              color: Color(0xFFF1F5FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check,
              color: Color(0xFF2260FF),
              size: 18,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFF2260FF),
                fontSize: 15,
                fontWeight: FontWeight.w600,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}