// 게시물 북마크 보관함 화면
// GET  /api/community/bookmarks          — 북마크 목록 조회
// DELETE /api/community/bookmarks/{postId} — 북마크 삭제
import 'package:flutter/material.dart';
import 'package:healyx_app/community_screen/community_detail.dart';
import 'package:healyx_app/dialogs/archive_delete_dialog.dart';
import '../app_language.dart';
import '../services/community_service.dart';

class BookmarkScreen extends StatefulWidget {
  const BookmarkScreen({super.key});

  @override
  State<BookmarkScreen> createState() => _BookmarkScreenState();
}

class _BookmarkScreenState extends State<BookmarkScreen> {
  List<BookmarkData> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBookmarks();
  }

  // 북마크 목록 API 호출
  Future<void> _loadBookmarks() async {
    setState(() => _isLoading = true);
    final items = await CommunityService.getBookmarks();
    if (!mounted) return;
    setState(() {
      _items = items;
      _isLoading = false;
    });
  }

  // 북마크 삭제 — 다이얼로그 확인 후 API 호출
  Future<void> _deleteItem(BookmarkData item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: const Color(0xFF2260FF).withValues(alpha: 0.4),
      builder: (ctx) => const ArchiveDeleteDialog(),
    );

    if (confirmed != true || !mounted) return;

    final success = await CommunityService.deleteBookmark(item.postId);
    if (!mounted) return;

    if (success) {
      setState(() => _items.removeWhere((e) => e.postId == item.postId));
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
          AppLanguage.t('archive_menu_bookmark'), // '커뮤니티 북마크'
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
            const Icon(Icons.bookmark_border, size: 56, color: Color(0xFFBBBBBB)),
            const SizedBox(height: 16),
            Text(
              AppLanguage.t('archive_empty_bookmark'), // '저장된 북마크가 없습니다.'
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
        return _BookmarkCard(
          item: item,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const CommunityDetailScreen(isMyPost: false),
              ),
            );
          },
          onDelete: () => _deleteItem(item),
        );
      },
    );
  }
}

class _BookmarkCard extends StatelessWidget {
  final BookmarkData item;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _BookmarkCard({
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
                    item.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2260FF),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.authorNickname,
                    style: const TextStyle(fontSize: 12, color: Colors.black45),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.contentPreview,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.favorite_border,
                          size: 14, color: Color(0xFF2260FF)),
                      const SizedBox(width: 3),
                      Text(
                        item.likeCount == 0 ? 'N' : '${item.likeCount}',
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF2260FF)),
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