// 번역 보관함 상세 화면
// 원본 이미지와 번역 이미지를 S3 URL을 통해 표시
import 'package:flutter/material.dart';
import '../app_language.dart';
import '../services/translation_service.dart';

class TranslationDetailScreen extends StatelessWidget {
  final TranslationArchiveItem item;

  const TranslationDetailScreen({
    super.key,
    required this.item,
  });

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
          AppLanguage.t('archive_menu_translation'), // '의료 번역 보관함'
          style: const TextStyle(
            color: Color(0xFF2260FF),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLanguage.t('archive_original_image'), // '원본 이미지'
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2260FF),
              ),
            ),
            const SizedBox(height: 12),
            _NetworkImageBox(imageUrl: item.originalImageUrl),

            const SizedBox(height: 16),
            const Divider(color: Color(0xFFE0E0E0), thickness: 1),
            const SizedBox(height: 16),

            Text(
              AppLanguage.t('archive_translated_image'), // '번역 이미지'
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2260FF),
              ),
            ),
            const SizedBox(height: 12),
            _NetworkImageBox(imageUrl: item.translatedImageUrl),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// S3 URL 이미지 박스 (자동 비율 조정)
class _NetworkImageBox extends StatelessWidget {
  final String imageUrl;

  const _NetworkImageBox({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width - 40;

    if (imageUrl.isEmpty) {
      return _placeholder(width);
    }

    return Container(
      width: width,
      constraints: BoxConstraints(minHeight: width * (3 / 4)),
      decoration: BoxDecoration(
        color: const Color(0xFFEEEEEE),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFDDDDDD)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(
          imageUrl,
          fit: BoxFit.contain,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return SizedBox(
              height: width * (3 / 4),
              child: const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF2260FF),
                  strokeWidth: 2,
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) => _placeholder(width),
        ),
      ),
    );
  }

  Widget _placeholder(double width) {
    return Container(
      width: width,
      height: width * (3 / 4),
      decoration: BoxDecoration(
        color: const Color(0xFFEEEEEE),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFDDDDDD)),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image_outlined, color: Color(0xFFBBBBBB), size: 48),
          SizedBox(height: 8),
          Text(
            '이미지를 불러올 수 없습니다',
            style: TextStyle(color: Color(0xFFBBBBBB), fontSize: 13),
          ),
        ],
      ),
    );
  }
}