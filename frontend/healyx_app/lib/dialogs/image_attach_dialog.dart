// 이미지 첨부 팝업 (글 작성 시 카메라 촬영/갤러리 선택) -> 리뷰 작성과 커뮤니티 글 작성에서 사용
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ImageAttachDialog extends StatelessWidget {
  final void Function(ImageSource source) onSelect;

  const ImageAttachDialog({
    super.key,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF4C5BFF);
    const Color cardBlue = Color(0xFFCAD6FF);
    const Color iconGray = Color(0xFF767676);

    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: EdgeInsets.zero,
      alignment: Alignment.bottomCenter,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
        child: Row(
          children: [
            Expanded(
              child: _AttachOption(
                icon: Icons.camera_alt_outlined,
                title: '카메라 촬영',
                iconColor: iconGray,
                primaryBlue: primaryBlue,
                cardBlue: cardBlue,
                onTap: () {
                  Navigator.pop(context);
                  onSelect(ImageSource.camera);
                },
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: _AttachOption(
                icon: Icons.photo,
                title: '이미지 선택',
                iconColor: iconGray,
                primaryBlue: primaryBlue,
                cardBlue: cardBlue,
                onTap: () {
                  Navigator.pop(context);

                  // 갤러리 선택 시 review_write_screen.dart 에서
                  // pickMultiImage()로 최대 5장 처리
                  onSelect(ImageSource.gallery);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AttachOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color iconColor;
  final Color primaryBlue;
  final Color cardBlue;
  final VoidCallback onTap;

  const _AttachOption({
    required this.icon,
    required this.title,
    required this.iconColor,
    required this.primaryBlue,
    required this.cardBlue,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 210,
        decoration: BoxDecoration(
          color: cardBlue,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 104,
              height: 104,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 52,
              ),
            ),
            const SizedBox(height: 28),
            Text(
              title,
              style: TextStyle(
                color: primaryBlue,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}