import 'package:flutter/material.dart';
import 'package:healyx_app/find_hospital_screen/find_hospital_detail.dart';
import 'package:healyx_app/dialogs/archive_delete_dialog.dart';

class ReviewItem {
  final String id;
  final String hospitalName;
  final String preview;
  final int starCount;

  const ReviewItem({
    required this.id,
    required this.hospitalName,
    required this.preview,
    required this.starCount,
  });
}

class MyReviewsScreen extends StatefulWidget {
  const MyReviewsScreen({super.key});

  @override
  State<MyReviewsScreen> createState() => _MyReviewsScreenState();
}

class _MyReviewsScreenState extends State<MyReviewsScreen> {
  final List<ReviewItem> _items = [
    const ReviewItem(id: '1', hospitalName: 'OO병원', preview: '의사 선생님 진짜 친절하세요', starCount: 5),
    const ReviewItem(id: '2', hospitalName: '&&병원', preview: '데스크 직원이 불친절하고 바닥에 벌레가 있었..', starCount: 2),
    const ReviewItem(id: '3', hospitalName: '병원 이름', preview: '리뷰 내용 미리보기', starCount: 0),
    const ReviewItem(id: '4', hospitalName: '병원 이름', preview: '리뷰 내용 미리보기', starCount: 0),
    const ReviewItem(id: '5', hospitalName: '병원 이름', preview: '리뷰 내용 미리보기', starCount: 0),
    const ReviewItem(id: '6', hospitalName: '병원', preview: '리뷰 내용 미리보기', starCount: 0),
  ];

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
          '내 리뷰',
          style: TextStyle(
            color: Color(0xFF2260FF),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _items.length,
        separatorBuilder: (_, __) =>
            const Divider(height: 1, color: Color(0xFFF2F2F2)),
        itemBuilder: (context, index) {
          final item = _items[index];
          return _ReviewCard(
            item: item,
            // 리뷰 카드 탭 → find_hospital_screen/find_hospital_detail.dart (해당 병원 상세 화면)
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FindHospitalDetailScreen(
                    hospitalName: item.hospitalName,
                    address: '',       // TODO: API 연동 시 실제 주소로 교체
                    rating: item.starCount.toDouble(),
                    hasReview: true,   // TODO: API 연동 시 실제 리뷰 여부로 교체
                    hasBadge: false,   // TODO: API 연동 시 실제 배지 여부로 교체
                    isLoggedIn: true,  // TODO: 토큰 기반 로그인 상태값으로 교체
                  ),
                ),
              );
            },
            onDelete: () {
              showDialog(
                context: context,
                barrierColor: const Color(0xFF2260FF).withOpacity(0.4),
                builder: (_) => const ArchiveDeleteDialog(),
              );
            },
          );
        },
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final ReviewItem item;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ReviewCard({
    required this.item,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.hospitalName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2260FF),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.preview,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.star_border, size: 14, color: Color(0xFF2260FF)),
                      const SizedBox(width: 3),
                      Text(
                        item.starCount == 0 ? 'N' : '${item.starCount}',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF2260FF)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.black38, size: 18),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}