// 게시물 북마크 보관함 화면 
// 게시물 북마크 리스트 형태로 보여주는 화면
import 'package:flutter/material.dart';
import 'package:healyx_app/community_screen/community_detail.dart';
import 'package:healyx_app/dialogs/archive_delete_dialog.dart';
import '../app_language.dart'; 

class BookmarkItem {
  final String id;
  final String title;
  final String category;
  final String preview;
  final int likeCount;

  const BookmarkItem({
    required this.id,
    required this.title,
    required this.category,
    required this.preview,
    required this.likeCount,
  });
}

class BookmarkScreen extends StatefulWidget {
  const BookmarkScreen({super.key});

  @override
  State<BookmarkScreen> createState() => _BookmarkScreenState();
}

class _BookmarkScreenState extends State<BookmarkScreen> {
  final List<BookmarkItem> _items = [
    const BookmarkItem(id: '1', title: '아산 병원 추천[42]', category: '병원추천인', preview: '제가 직접 다녀온 아산병원들 추천합니다 먼저..', likeCount: 5),
    const BookmarkItem(id: '2', title: '건강보험 자동 가입[2]', category: '닉네임123', preview: '건강보험 자동 가입 되는거 아셨나요 저는 몰라..', likeCount: 1),
    const BookmarkItem(id: '3', title: '제목[댓글수]', category: '작성자 닉네임', preview: '내용 미리보기', likeCount: 0),
    const BookmarkItem(id: '4', title: '제목[댓글수]', category: '작성자 닉네임', preview: '내용 미리보기', likeCount: 0),
    const BookmarkItem(id: '5', title: '제목[댓글수]', category: '작성자 닉네임', preview: '내용 미리보기', likeCount: 0),
    const BookmarkItem(id: '6', title: '제목[댓글수]', category: '작성자 닉네임', preview: '내용 미리보기', likeCount: 0),
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
        title: Text(
          AppLanguage.t('archive_menu_bookmark'), // '커뮤니티 북마크'
          style: const TextStyle(
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
          return _BookmarkCard(
            item: item,
            // 북마크 카드 탭 → community_screen/community_detail.dart (남의 글 isMyPost: false)
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CommunityDetailScreen(isMyPost: false),
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

class _BookmarkCard extends StatelessWidget {
  final BookmarkItem item;
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
                  Text(item.category,
                      style: const TextStyle(fontSize: 12, color: Colors.black45)),
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
                      const Icon(Icons.favorite_border, size: 14, color: Color(0xFF2260FF)),
                      const SizedBox(width: 3),
                      Text(
                        item.likeCount == 0 ? 'N' : '${item.likeCount}',
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
