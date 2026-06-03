// 내 리뷰 보관함 화면
// GET    /api/reviews/my             — 내가 작성한 리뷰 목록 조회
// DELETE /api/reviews/my/{reviewId} — 내 리뷰 삭제 (하드 삭제)
import 'package:flutter/material.dart';
import 'package:healyx_app/find_hospital_screen/find_hospital_detail.dart';
import 'package:healyx_app/dialogs/archive_delete_dialog.dart';
import '../app_language.dart';
import '../services/review_service.dart';

class MyReviewsScreen extends StatefulWidget {
  const MyReviewsScreen({super.key});

  @override
  State<MyReviewsScreen> createState() => _MyReviewsScreenState();
}

class _MyReviewsScreenState extends State<MyReviewsScreen> {
  List<MyReviewData> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  // 내 리뷰 목록 API 호출
  Future<void> _loadReviews() async {
    setState(() => _isLoading = true);
    final items = await ReviewService.getMyReviews();
    if (!mounted) return;
    setState(() {
      _items = items;
      _isLoading = false;
    });
  }

  // 리뷰 삭제 — 다이얼로그 확인 후 API 호출
  Future<void> _deleteItem(MyReviewData item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: const Color(0xFF2260FF).withValues(alpha: 0.4),
      builder: (_) => const ArchiveDeleteDialog(),
    );
    if (confirmed != true || !mounted) return;

    final success = await ReviewService.deleteMyReview(item.reviewId);
    if (!mounted) return;

    if (success) {
      setState(() => _items.removeWhere((e) => e.reviewId == item.reviewId));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLanguage.t('error_retry'))),
      );
    }
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
        title: Text(
          AppLanguage.t('archive_menu_reviews'), // '내 리뷰'
          style: const TextStyle(
            color: Color(0xFF2260FF),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF2260FF)),
      );
    }

    if (_items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.rate_review_outlined,
                size: 56, color: Color(0xFFBBBBBB)),
            const SizedBox(height: 16),
            Text(
              AppLanguage.t('archive_empty_reviews'), // '작성한 리뷰가 없습니다.'
              style: const TextStyle(fontSize: 15, color: Color(0xFF9E9E9E)),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _items.length,
      separatorBuilder: (_, __) =>
          const Divider(height: 1, color: Color(0xFFF2F2F2)),
      itemBuilder: (context, index) {
        final item = _items[index];
        return _ReviewCard(
          item: item,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => FindHospitalDetailScreen(
                  ykiho: item.ykiho,
                  hospitalName: item.hospitalName,
                  address: item.address,
                  rating: item.rating,
                  hasReview: true,
                  hasBadge: item.hasBadge,
                  isLoggedIn: true,
                ),
              ),
            );
          },
          onDelete: () => _deleteItem(item),
        );
      },
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final MyReviewData item;
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
                    item.contentPreview,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 13, color: Colors.black54),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.star,
                          size: 14, color: Color(0xFF2260FF)),
                      const SizedBox(width: 3),
                      Text(
                        item.rating == 0
                            ? 'N'
                            : item.rating.toStringAsFixed(
                                item.rating % 1 == 0 ? 0 : 1),
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF2260FF)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close,
                  color: Colors.black38, size: 18),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}