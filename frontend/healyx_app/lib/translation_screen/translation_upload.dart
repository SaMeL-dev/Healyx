// 번역 업로드 화면
// 번역 업로드 화면에서는 사용자가 카메라 촬영 또는 갤러리 선택을 통해 이미지를 업로드할 수 있도록 구성
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../app_language.dart'; 
import 'translation_loading.dart';

class TranslationUploadScreen extends StatefulWidget {
  const TranslationUploadScreen({super.key});

  @override
  State<TranslationUploadScreen> createState() =>
      _TranslationUploadScreenState();
}

class _TranslationUploadScreenState extends State<TranslationUploadScreen> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (!mounted) return;
      if (image == null) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TranslationLoadingScreen(
            isFromCamera: true,
            imagePath: image.path,
          ),
        ),
      );
    } catch (e) {
      _showMessage(AppLanguage.t('translation_camera_error')); // '카메라를 여는 중 문제가 발생했습니다.'
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (!mounted) return;
      if (image == null) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TranslationLoadingScreen(
            isFromCamera: false,
            imagePath: image.path,
          ),
        ),
      );
    } catch (e) {
      _showMessage(AppLanguage.t('translation_gallery_error')); // '이미지를 불러오는 중 문제가 발생했습니다.'
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF2260FF);
    const Color cardBlue = Color(0xFFCAD6FF);
    const Color bgColor = Color(0xFFFFFFFF);
    const Color grayText = Color(0xFF767676);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 16),
              Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: () {
                        if (Navigator.canPop(context)) {
                          Navigator.pop(context);
                        }
                      },
                      icon: const Icon(
                        Icons.arrow_back_ios_new,
                        color: primaryBlue,
                        size: 24,
                      ),
                    ),
                  ),
                  Text(
                    AppLanguage.t('translation_title'), // '의료번역'
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: primaryBlue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 120),
              Text(
                AppLanguage.t('translation_upload_select_method'), // '이미지 업로드 방식을 선택해주세요.'
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: primaryBlue,
                ),
              ),
              const SizedBox(height: 36),
              _UploadOptionCard(
                icon: Icons.camera_alt_outlined,
                title: AppLanguage.t('review_upload_camera_title'), // '카메라 촬영'
                subtitle: AppLanguage.t('translation_upload_camera_subtitle'), // '사진을 촬영하세요'
                backgroundColor: cardBlue,
                titleColor: primaryBlue,
                subtitleColor: grayText,
                onTap: _pickFromCamera,
              ),
              const SizedBox(height: 28),
              _UploadOptionCard(
                icon: Icons.image_outlined,
                title: AppLanguage.t('review_upload_gallery_title'), // '이미지 선택'
                subtitle: AppLanguage.t('translation_upload_gallery_subtitle'), // '사진을 선택하세요'
                backgroundColor: cardBlue,
                titleColor: primaryBlue,
                subtitleColor: grayText,
                onTap: _pickFromGallery,
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

class _UploadOptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color backgroundColor;
  final Color titleColor;
  final Color subtitleColor;
  final VoidCallback onTap;

  const _UploadOptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.backgroundColor,
    required this.titleColor,
    required this.subtitleColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 165,
        padding: const EdgeInsets.symmetric(horizontal: 28),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Container(
              width: 108,
              height: 108,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 54,
                color: const Color(0xFF767676),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: titleColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: subtitleColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}