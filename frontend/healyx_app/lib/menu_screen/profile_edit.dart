// 프로필 편집 화면
// - 프로필 이미지 (기본 아이콘으로 표시, 추후 사진 업로드 기능 추가 예정)
// - 실명, 이메일, 닉네임 (읽기 전용으로 표시)
// - 건강보험 여부 (토글로 표시, 수정 가능)
import 'package:flutter/material.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final TextEditingController _nameController =
      TextEditingController(text: '홍길동');
  final TextEditingController _emailController =
      TextEditingController(text: '이메일123@example.com');
  final TextEditingController _nicknameController =
      TextEditingController(text: '닉네임123');
  bool _hasInsurance = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _nicknameController.dispose();
    super.dispose();
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
        title: const Text(
          '프로필 설정',
          style: TextStyle(
            color: Color(0xFF2260FF),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),

            // 프로필 이미지
            Center(
              child: Stack(
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
                ],
              ),
            ),

            const SizedBox(height: 32),

            // 실명
            _buildLabel('실명'),
            const SizedBox(height: 8),
            _buildReadOnlyField(_nameController),

            const SizedBox(height: 20),

            // 이메일
            _buildLabel('이메일'),
            const SizedBox(height: 8),
            _buildReadOnlyField(_emailController),

            const SizedBox(height: 20),

            // 닉네임 - 읽기 전용으로 변경
            _buildLabel('닉네임'),
            const SizedBox(height: 8),
            _buildReadOnlyField(_nicknameController),

            const SizedBox(height: 8),
            const Divider(color: Color(0xFF2260FF), thickness: 1.2),

            const SizedBox(height: 20),

            // 건강보험 여부 - 토글만 활성화
            _buildLabel('건강보험 여부'),
            const SizedBox(height: 12),
            Row(
              children: [
                Transform.scale(
                  scale: 0.9,
                  child: Switch(
                    value: _hasInsurance,
                    onChanged: (val) => setState(() => _hasInsurance = val),
                    activeColor: Colors.white,
                    activeTrackColor: const Color(0xFF2260FF),
                    inactiveThumbColor: Colors.white,
                    inactiveTrackColor: const Color(0xFFCCCCCC),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),
            const Divider(color: Color(0xFFE0E0E0), thickness: 1),

            const SizedBox(height: 36),

            // 저장 버튼
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  // 저장 로직
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2260FF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  '저장',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
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

  Widget _buildReadOnlyField(TextEditingController controller) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F7),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        controller.text,
        style: const TextStyle(fontSize: 15, color: Colors.black87),
      ),
    );
  }

  Widget _buildEditableField(
    TextEditingController controller,
    String hint,
  ) {
    return TextField(
      controller: controller,
      style: const TextStyle(fontSize: 15, color: Colors.black87),
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFFF2F2F7),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
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
          borderSide: const BorderSide(color: Color(0xFF2260FF), width: 1.5),
        ),
      ),
    );
  }
}