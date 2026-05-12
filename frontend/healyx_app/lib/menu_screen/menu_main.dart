// 메뉴 메인 화면
// 로그인/비로그인 상태에 따라 보여지는 메뉴 항목이 달라지는 화면
// isLoggedIn은 main_screen.dart의 _openMenu()에서 AuthService.isLoggedIn() 결과를 받아 전달됨
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'profile_edit.dart';
import 'settings.dart';
import 'reset_password_screen/password_verify.dart';

import '../archive_screen/archive_main.dart';
import '../dialogs/logout_dialog.dart';
import '../login_signup_screen/login_screen.dart';
import '../app_language.dart';

class MenuScreen extends StatefulWidget {
  final bool isLoggedIn;

  const MenuScreen({super.key, this.isLoggedIn = false}); // false=비로그인 기본값

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  String _nickname = '';

  @override
  void initState() {
    super.initState();
    if (widget.isLoggedIn) _loadNickname();
  }

  // SharedPreferences에서 닉네임 로드
  Future<void> _loadNickname() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _nickname = prefs.getString('nickname') ?? '';
    });
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
          AppLanguage.t('menu_title'), // '메뉴'
          style: const TextStyle(
            color: Color(0xFF2260FF),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: widget.isLoggedIn
          ? _LoggedInBody(
              nickname: _nickname,
              onProfileUpdated: () {
                if (mounted) _loadNickname();
              },
            )
          : const _GuestBody(),
    );
  }
}

// ─────────────────────────────────────────
// 비로그인 UI
// ─────────────────────────────────────────
class _GuestBody extends StatelessWidget {
  const _GuestBody();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 28),

          // → LoginScreen으로 이동
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
            child: Row(
              children: [
                Text(
                  AppLanguage.t('menu_login_prompt'), // '로그인을 해주세요'
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.chevron_right,
                  color: Color(0xFF2260FF),
                  size: 26,
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),

          _MenuTile(
            icon: Icons.settings_outlined,
            label: AppLanguage.t('settings_title'), // '설정'
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const SettingsScreen(isLoggedIn: false)),
              );
            },
            isLast: true,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// 로그인 UI
// ─────────────────────────────────────────
class _LoggedInBody extends StatelessWidget {
  final String nickname;
  final VoidCallback onProfileUpdated;

  const _LoggedInBody({required this.nickname, required this.onProfileUpdated});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 24),

          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileEditScreen()),
              ).then((_) => onProfileUpdated());
            },
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
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
                Positioned(
                  bottom: 2,
                  right: 2,
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFE0E0E0)),
                    ),
                    child: const Icon(
                      Icons.edit_outlined,
                      size: 14,
                      color: Color(0xFF2260FF),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          Text(
            AppLanguage.t('menu_greeting').replaceAll('{nickname}', nickname),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),

          const SizedBox(height: 36),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                _MenuTile(
                  icon: Icons.inventory_2_outlined,
                  label: AppLanguage.t('menu_archive'), // '보관함'
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ArchiveMainScreen(),
                      ),
                    );
                  },
                ),
                _MenuTile(
                  icon: Icons.settings_outlined,
                  label: AppLanguage.t('settings_title'), // '설정'
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              const SettingsScreen(isLoggedIn: true)),
                    );
                  },
                ),
                _MenuTile(
                  icon: Icons.lock_outline,
                  label: AppLanguage.t('menu_change_password'), // '비밀번호 변경'
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const PasswordVerifyScreen()),
                    );
                  },
                ),
                _MenuTile(
                  icon: Icons.logout,
                  label: AppLanguage.t('menu_logout'), // '로그아웃'
                  onTap: () {
                    showDialog(
                      context: context,
                      barrierColor:
                          const Color(0xFF2260FF).withValues(alpha: 0.4),
                      builder: (_) => const LogoutDialog(),
                    );
                  },
                  isLast: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// 공통 메뉴 타일
// ─────────────────────────────────────────
class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isLast;

  const _MenuTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2EAFF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: const Color(0xFF2260FF), size: 22),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: Color(0xFFBBBBBB),
                  size: 22,
                ),
              ],
            ),
          ),
        ),
        if (!isLast)
          const Divider(height: 1, thickness: 1, color: Color(0xFFF2F2F2)),
      ],
    );
  }
}