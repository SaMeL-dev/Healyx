import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'translation_loading.dart';

class TranslationErrorScreen extends StatefulWidget {
  final bool isCameraError;

  const TranslationErrorScreen({
    super.key,
    required this.isCameraError,
  });

  @override
  State<TranslationErrorScreen> createState() => _TranslationErrorScreenState();
}

class _TranslationErrorScreenState extends State<TranslationErrorScreen> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _retryPickImage() async {
    final XFile? image = await _picker.pickImage(
      source: widget.isCameraError ? ImageSource.camera : ImageSource.gallery,
      imageQuality: 85,
    );

    if (!mounted) return;

    if (image == null) {
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => TranslationLoadingScreen(
          isFromCamera: widget.isCameraError,
          imagePath: image.path,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF2260FF);
    const Color bgColor = Color(0xFFFFFFFF);

    final String guideText = widget.isCameraError
        ? '사진이 흐리거나 일부만 촬영된 경우\n정확한 인식이 어려울 수 있어요.'
        : '사진이 흐리거나 전체가 아닌 일부의 이미지인 경우\n정확한 인식이 어려울 수 있어요.';

    final String buttonText = widget.isCameraError ? '다시 촬영하기' : '다시 선택하기';

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
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
                  const Text(
                    '의료번역',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: primaryBlue,
                    ),
                  ),
                ],
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      '인식에\n실패하였습니다.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        height: 1.5,
                        fontWeight: FontWeight.w700,
                        color: primaryBlue,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      guideText,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.5,
                        fontWeight: FontWeight.w600,
                        color: primaryBlue,
                      ),
                    ),
                    const SizedBox(height: 36),
                    SizedBox(
                      width: 200,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _retryPickImage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryBlue,
                          foregroundColor: Colors.white,
                          elevation: 6,
                          shadowColor: const Color(0x33000000),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(26),
                          ),
                        ),
                        child: Text(
                          buttonText,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}