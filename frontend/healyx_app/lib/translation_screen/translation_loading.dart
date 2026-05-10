// 번역 인식 로딩 화면
// 번역 인식이 진행되는 동안 로딩 애니메이션과 함께 이미지 미리보기를 보여주는 화면
// 성공 시 번역 결과 화면으로 이동, 실패 시 번역 인식 에러 화면으로 이동 (True/false로 분기)
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../app_language.dart'; //추가
import 'translation_result.dart';
import 'translation_upload.dart';
import 'translation_error.dart';

class TranslationLoadingScreen extends StatefulWidget {
  final bool isFromCamera;
  final String imagePath;

  const TranslationLoadingScreen({
    super.key,
    required this.isFromCamera,
    required this.imagePath,
  });

  @override
  State<TranslationLoadingScreen> createState() =>
      _TranslationLoadingScreenState();
}

class _TranslationLoadingScreenState extends State<TranslationLoadingScreen> {
  Timer? _timer;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();

    _timer = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;

      final bool isSuccess = true; // 퍼블리싱 단계용 임시값

      if (isSuccess) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => TranslationResultScreen(
              originalImagePath: widget.imagePath,
              translatedImagePath: widget.imagePath,
            ),
          ),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => TranslationErrorScreen(
              isCameraError: widget.isFromCamera,
            ),
          ),
        );
      }
    });
  }

  Future<void> _retryPickImage() async {
    _timer?.cancel();

    final XFile? image = await _picker.pickImage(
      source: widget.isFromCamera ? ImageSource.camera : ImageSource.gallery,
      imageQuality: 85,
    );

    if (!mounted) return;

    if (image == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const TranslationUploadScreen(),
        ),
      );
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => TranslationLoadingScreen(
          isFromCamera: widget.isFromCamera,
          imagePath: image.path,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF2260FF);
    const Color bgColor = Color(0xFFFFFFFF);
    const Color darkGray = Color(0xFF5B5959);
    const Color lightGray = Color(0xFFA1A9C4);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 16),
              Center(
                child: Text(
                  AppLanguage.t('translation_title'), // '의료번역'
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: primaryBlue,
                  ),
                ),
              ),
              const SizedBox(height: 110),
              Text(
                AppLanguage.t('translation_loading_preview'), // '이미지 미리보기'
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: primaryBlue,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                AppLanguage.t('translation_loading_check'), // '번역하고자 하는 이미지를 확인해주세요.'
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: lightGray,
                ),
              ),
              const SizedBox(height: 40),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: double.infinity,
                    height: 280,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(
                        color: const Color(0xFFBDBDBD),
                        width: 1,
                      ),
                    ),
                    child: ClipRRect(
                      child: Image.file(
                        File(widget.imagePath),
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Icon(
                              Icons.image_outlined,
                              size: 56,
                              color: darkGray,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  Positioned(
                    top: -14,
                    right: -14,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: primaryBlue,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        onPressed: _retryPickImage,
                        icon: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 56),
              Text(
                AppLanguage.t('translation_loading_recognizing'), // '이미지를 인식중입니다...'
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: primaryBlue,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}