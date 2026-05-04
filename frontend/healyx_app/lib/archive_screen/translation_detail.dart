// 번역 보관함 상세 화면 (가로/세로 버전 두 개)
// 원본 이미지와 번역 이미지가 각각 가로/세로 버전으로 보여짐
import 'package:flutter/material.dart';
import 'translation_list.dart'; // TranslationItem 모델이 여기 있음

class TranslationDetailScreen extends StatelessWidget {
  final TranslationItem item;

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
        title: const Text(
          '의료 번역 보관함',
          style: TextStyle(
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
            // ── 원본 이미지 ──
            const Text(
              '원본 이미지',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2260FF),
              ),
            ),
            const SizedBox(height: 12),
            _ImageBox(isHorizontal: item.isHorizontal),

            const SizedBox(height: 16),
            const Divider(color: Color(0xFFE0E0E0), thickness: 1),
            const SizedBox(height: 16),

            // ── 번역 이미지 ──
            const Text(
              '번역 이미지',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2260FF),
              ),
            ),
            const SizedBox(height: 12),
            _ImageBox(isHorizontal: item.isHorizontal),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

/// isHorizontal: true  → 가로 이미지 (4:3 비율)
/// isHorizontal: false → 세로 이미지 (3:4 비율)
class _ImageBox extends StatelessWidget {
  final bool isHorizontal;

  const _ImageBox({required this.isHorizontal});

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width - 40;
    final double height = isHorizontal ? width * (3 / 4) : width * (4 / 3);

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFEEEEEE),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFDDDDDD)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isHorizontal ? Icons.panorama : Icons.image_outlined,
            color: const Color(0xFFBBBBBB),
            size: 48,
          ),
          const SizedBox(height: 8),
          Text(
            isHorizontal ? '가로 이미지' : '세로 이미지',
            style: const TextStyle(color: Color(0xFFBBBBBB), fontSize: 13),
          ),
        ],
      ),
    );
  }
}