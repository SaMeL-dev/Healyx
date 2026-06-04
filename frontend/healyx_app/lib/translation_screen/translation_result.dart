// 번역 결과 화면
// 원본 이미지(로컬)와 번역된 이미지를 보여주는 화면
// 로그인 사용자: S3 URL(Image.network), 게스트: Base64(Image.memory)
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import '../app_language.dart';
import '../dialogs/login_required_dialog.dart';
import '../common/common_toast.dart';

class TranslationResultScreen extends StatelessWidget {
  final String originalImagePath;
  final String translatedImageUrl;       // 로그인 사용자: S3 URL
  final String translatedImageBase64;    // 게스트: Base64 인코딩 이미지
  final bool isSaved;

  const TranslationResultScreen({
    super.key,
    required this.originalImagePath,
    required this.translatedImageUrl,
    required this.translatedImageBase64,
    required this.isSaved,
  });

  void _handleSave(BuildContext context) {
    if (isSaved) {
      // 로그인 사용자: 백엔드에서 이미 보관함에 저장됨
      CommonToast.show(
        context,
        message: AppLanguage.t('translation_saved'), // '보관함에 저장되었습니다.'
      );
    } else {
      // 비로그인(게스트): 로그인 유도 다이얼로그
      showDialog(
        context: context,
        barrierColor: const Color(0x802260FF),
        builder: (context) => const LoginRequiredDialog(),
      );
    }
  }

  // 번역 이미지 위젯 빌드
  // 우선순위: S3 URL → Base64 → 플레이스홀더 텍스트
  // fitWidth: 이미지 원본 비율(가로/세로)에 맞게 높이 자동 조정
  Widget _buildTranslatedImage(Color grayText) {
    if (translatedImageUrl.isNotEmpty) {
      return Image.network(
        translatedImageUrl,
        width: double.infinity,
        fit: BoxFit.fitWidth,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return const SizedBox(
            height: 200,
            child: Center(
              child: CircularProgressIndicator(
                color: Color(0xFF2260FF),
                strokeWidth: 2,
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) =>
            _buildPlaceholder(grayText),
      );
    }

    if (translatedImageBase64.isNotEmpty) {
      try {
        final bytes = base64Decode(translatedImageBase64);
        return Image.memory(
          bytes,
          width: double.infinity,
          fit: BoxFit.fitWidth,
          errorBuilder: (context, error, stackTrace) =>
              _buildPlaceholder(grayText),
        );
      } catch (_) {
        // Base64 디코딩 실패 시 플레이스홀더
      }
    }

    return _buildPlaceholder(grayText);
  }

  Widget _buildPlaceholder(Color grayText) {
    return Center(
      child: Text(
        AppLanguage.t('translation_result_placeholder'), // '번역 이미지가 표시될 영역'
        style: TextStyle(
          fontSize: 16,
          color: grayText,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF2260FF);
    const Color bgColor = Color(0xFFFFFFFF);
    const Color cardColor = Color(0xFFECEFFF);
    const Color titleColor = Color(0xFF667AB6);
    const Color grayText = Color(0xFF605E5E);
    const Color buttonBlue = Color(0xFF2260FF);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: SingleChildScrollView(
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
                    Text(
                      AppLanguage.t('translation_title'), // '의료번역'
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: primaryBlue,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 122,
                      height: 172,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: const Color(0xFFBDBDBD)),
                      ),
                      child: ClipRRect(
                        child: Image.file(
                          File(originalImagePath),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
                              child: Icon(
                                Icons.image_outlined,
                                size: 40,
                                color: Color(0xFF767676),
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                    const SizedBox(width: 28),

                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppLanguage.t('archive_original_image'), // '원본 이미지'
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF757D95),
                              ),
                            ),
                            const SizedBox(height: 16),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF8C9AF0),
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      AppLanguage.t('translation_done_badge'), // '번역 완료'
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(
                                      Icons.check,
                                      color: Color(0xFF304476),
                                      size: 20,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x22000000),
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        AppLanguage.t('archive_translated_image'), // '번역 이미지'
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: titleColor,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // 번역된 이미지 (S3 URL 또는 Base64)
                      // 고정 높이 없이 이미지 원본 비율(가로/세로)로 표시
                      Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(minHeight: 200),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: const Color(0xFFBDBDBD)),
                        ),
                        child: ClipRRect(
                          child: _buildTranslatedImage(grayText),
                        ),
                      ),

                      const SizedBox(height: 24),

                      SizedBox(
                        width: 150,
                        height: 45,
                        child: ElevatedButton(
                          onPressed: () => _handleSave(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: buttonBlue,
                            foregroundColor: Colors.white,
                            elevation: 6,
                            shadowColor: const Color(0x33000000),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(31),
                            ),
                          ),
                          child: Text(
                            AppLanguage.t('translation_save'), // '저장하기'
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

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
