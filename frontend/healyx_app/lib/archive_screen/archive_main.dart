// 보관함 메인 화면
// - 의료 번역 보관함, 커뮤니티 북마크, 내 게시글/댓글, 내 리뷰로 이동할 수 있는 메뉴 리스트 형태의 화면 
import 'package:flutter/material.dart';
import 'translation_list.dart';
import 'bookmark.dart';
import 'my_posts_comments.dart';
import 'my_reviews.dart';

class ArchiveMainScreen extends StatelessWidget {
  const ArchiveMainScreen({super.key});

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
          '보관함',
          style: TextStyle(
            color: Color(0xFF2260FF),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Column(
          children: [
            _ArchiveTile(
              label: '의료 번역 보관함',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const TranslationListScreen(),
                  ),
                );
              },
            ),
            const Divider(height: 1, thickness: 1, color: Color(0xFFF2F2F2)),
            _ArchiveTile(
              label: '커뮤니티 북마크',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const BookmarkScreen(),
                  ),
                );
              },
            ),
            const Divider(height: 1, thickness: 1, color: Color(0xFFF2F2F2)),
            _ArchiveTile(
              label: '내 게시글 / 댓글',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const MyPostsCommentsScreen(),
                  ),
                );
              },
            ),
            const Divider(height: 1, thickness: 1, color: Color(0xFFF2F2F2)),
            _ArchiveTile(
              label: '내 리뷰',
              isLast: true,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const MyReviewsScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ArchiveTile extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isLast;

  const _ArchiveTile({
    required this.label,
    required this.onTap,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Row(
          children: [
            const Icon(
              Icons.inventory_2_outlined,
              color: Color(0xFF2260FF),
              size: 22,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: Color(0xFFBBBBBB),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}