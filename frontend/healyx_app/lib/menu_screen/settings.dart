// 설정 화면
// 로그인 상태일 때: 사용 언어 변경, 알림 설정, 회원 탈퇴
// 비로그인 상태일 때: 사용 언어 변경만 표시
// 12번째 줄 true/false 있는데 그냥 false로 냅두면 메인메뉴 로그인 여부에 따라서 자동으로 반영됨!

import 'package:flutter/material.dart';
import 'package:healyx_app/choose_language_screen.dart';
import 'package:healyx_app/dialogs/withdraw_dialog.dart';

class SettingsScreen extends StatefulWidget {
  final bool isLoggedIn;

  const SettingsScreen({super.key, this.isLoggedIn = false}); // true=로그인, false=비로그인 (기본값은 false로 설정)

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationEnabled = true;

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
        title: const Text(
          '설정',
          style: TextStyle(
            color: Color(0xFF2260FF),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Column(
          children: [
            // 사용 언어 변경 - 항상 표시
            _buildArrowTile(
              icon: Icons.language,
              label: '사용 언어 변경',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ChooseLanguageScreen(),
                  ),
                );
              },
            ),

            // 로그인 상태일 때만 표시 (알림설정 + 회원탈퇴)
            if (widget.isLoggedIn) ...[
              const Divider(height: 1, thickness: 1, color: Color(0xFFF2F2F2)),

              _buildToggleTile(
                icon: Icons.notifications_none,
                label: '알림 설정',
                value: _notificationEnabled,
                onChanged: (val) => setState(() => _notificationEnabled = val),
              ),

              const Divider(height: 1, thickness: 1, color: Color(0xFFF2F2F2)),

              _buildSimpleTile(
                icon: Icons.logout,
                label: '회원 탈퇴',
                onTap: () {
                  showDialog(
                    context: context,
                    barrierColor: const Color(0xFF2260FF).withOpacity(0.4),
                    builder: (_) => const WithdrawDialog(),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildArrowTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Row(
          children: [
            Icon(icon, color: Colors.black87, size: 22),
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
            const Icon(Icons.chevron_right, color: Color(0xFFBBBBBB), size: 22),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleTile({
    required IconData icon,
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: Colors.black87, size: 22),
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
          Transform.scale(
            scale: 0.85,
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeColor: Colors.white,
              activeTrackColor: const Color(0xFF2260FF),
              inactiveThumbColor: Colors.white,
              inactiveTrackColor: const Color(0xFFCCCCCC),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Row(
          children: [
            Icon(icon, color: Colors.black87, size: 22),
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
          ],
        ),
      ),
    );
  }
}