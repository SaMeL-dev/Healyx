// 리뷰 이미지 슬라이더 위젯
// 리뷰 작성 화면에서 리뷰에 첨부된 이미지들을 가로로 스크롤 가능한 슬라이더 형태로 보여주는 위젯
// 이미지가 없는 경우 기본 이미지 아이콘을 보여주도록 구성
import 'package:flutter/material.dart';

class ReviewImageSlider extends StatefulWidget {
  final int imageCount;

  const ReviewImageSlider({
    super.key,
    required this.imageCount,
  });

  @override
  State<ReviewImageSlider> createState() => _ReviewImageSliderState();
}

class _ReviewImageSliderState extends State<ReviewImageSlider> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color mainBlue = Color(0xFF2260FF);
    const Color softBg = Color(0xFFECF1FF);
    const Color gray = Color(0xFF7E7E7E);

    return Scrollbar(
      controller: _scrollController,
      thumbVisibility: true,
      radius: const Radius.circular(20),
      thickness: 4,
      child: SingleChildScrollView(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: List.generate(
            widget.imageCount,
            (index) => Container(
              width: 140,
              height: 95,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: softBg,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Center(
                child: Icon(
                  Icons.image_outlined,
                  size: 26,
                  color: gray,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}