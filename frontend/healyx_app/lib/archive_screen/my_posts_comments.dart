// 내 게시글 / 댓글 보관함 화면
// 내가 작성한 게시글과 댓글을 리스트 형태로 보여주는 화면
import 'package:flutter/material.dart';
import 'package:healyx_app/community_screen/community_detail.dart';
import 'package:healyx_app/dialogs/archive_delete_dialog.dart';

class PostItem {
  final String id;
  final String title;
  final String category;
  final String preview;
  final int likeCount;

  const PostItem({
    required this.id,
    required this.title,
    required this.category,
    required this.preview,
    required this.likeCount,
  });
}

class CommentItem {
  final String id;
  final String postTitle;
  final String postCategory;
  final String commentPreview;

  const CommentItem({
    required this.id,
    required this.postTitle,
    required this.postCategory,
    required this.commentPreview,
  });
}

class MyPostsCommentsScreen extends StatefulWidget {
  const MyPostsCommentsScreen({super.key});

  @override
  State<MyPostsCommentsScreen> createState() => _MyPostsCommentsScreenState();
}

class _MyPostsCommentsScreenState extends State<MyPostsCommentsScreen> {
  bool _isPostTab = true;

  final List<PostItem> _posts = [
    const PostItem(id: '1', title: '서울에 있는 피부과 추천[0]', category: '', preview: '해주세요', likeCount: 0),
    const PostItem(id: '2', title: '서울에 OO병원 진짜[2]', category: '', preview: '좋아요. 의사 선생님이 진짜 친절하시고 데스크..', likeCount: 1),
    const PostItem(id: '3', title: '제목[댓글수]', category: '작성자 닉네임', preview: '내용 미리보기', likeCount: 0),
    const PostItem(id: '4', title: '제목[댓글수]', category: '작성자 닉네임', preview: '내용 미리보기', likeCount: 0),
    const PostItem(id: '5', title: '제목[댓글수]', category: '작성자 닉네임', preview: '내용 미리보기', likeCount: 0),
  ];

  final List<CommentItem> _comments = [
    const CommentItem(id: '1', postTitle: '아산 병원 추천[42]', postCategory: '병원추천인', commentPreview: '꿀팁 감사해요!'),
    const CommentItem(id: '2', postTitle: '건강 보험 자동 가입[2]', postCategory: '닉네임123', commentPreview: '저 진짜 몰랐는데 알려주셔서 감사합니다 덕분..'),
    const CommentItem(id: '3', postTitle: '제목[댓글수]', postCategory: '작성자 닉네임', commentPreview: '댓글 내용 미리보기'),
    const CommentItem(id: '4', postTitle: '제목[댓글수]', postCategory: '작성자 닉네임', commentPreview: '댓글 내용 미리보기'),
    const CommentItem(id: '5', postTitle: '제목[댓글수]', postCategory: '작성자 닉네임', commentPreview: '댓글 내용 미리보기'),
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
          '내 게시글 / 댓글',
          style: TextStyle(
            color: Color(0xFF2260FF),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _TabToggle(
              isPostTab: _isPostTab,
              onChanged: (val) => setState(() => _isPostTab = val),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _isPostTab ? _buildPostList() : _buildCommentList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPostList() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _posts.length,
      separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF2F2F2)),
      itemBuilder: (context, index) {
        final post = _posts[index];
        return _PostCard(
          item: post,
          // 게시글 카드 탭 → community_screen/community_detail.dart (내 글 isMyPost: true)
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const CommunityDetailScreen(isMyPost: true),
              ),
            );
          },
          onDelete: () {
            // showDialog(
            //   context: context,
            //   barrierColor: const Color(0xFF2260FF).withOpacity(0.4),
            //   builder: (_) => const DeleteConfirmDialog(),
            // );
          },
        );
      },
    );
  }

  Widget _buildCommentList() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _comments.length,
      separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF2F2F2)),
      itemBuilder: (context, index) {
        final comment = _comments[index];
        return _CommentCard(
          item: comment,
          // 댓글 카드 탭 → community_screen/community_detail.dart (남의 글 isMyPost: false)
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
               builder: (_) => const  ArchiveDeleteDialog(),
            );
          },
        );
      },
    );
  }
}

class _TabToggle extends StatelessWidget {
  final bool isPostTab;
  final ValueChanged<bool> onChanged;

  const _TabToggle({required this.isPostTab, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFFE2EAFF),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          Expanded(child: _TabButton(label: '게시글', isSelected: isPostTab, onTap: () => onChanged(true))),
          Expanded(child: _TabButton(label: '댓글', isSelected: !isPostTab, onTap: () => onChanged(false))),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabButton({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2260FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(26),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF2260FF),
          ),
        ),
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  final PostItem item;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _PostCard({
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
                  Text(item.title,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF2260FF))),
                  if (item.category.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(item.category, style: const TextStyle(fontSize: 12, color: Colors.black45)),
                  ],
                  const SizedBox(height: 4),
                  Text(item.preview, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, color: Colors.black54)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.favorite_border, size: 14, color: Color(0xFF2260FF)),
                      const SizedBox(width: 3),
                      Text(item.likeCount == 0 ? 'N' : '${item.likeCount}',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF2260FF))),
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

class _CommentCard extends StatelessWidget {
  final CommentItem item;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _CommentCard({
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
                  Text(item.postTitle,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF2260FF))),
                  const SizedBox(height: 3),
                  Text(item.postCategory, style: const TextStyle(fontSize: 12, color: Colors.black45)),
                  const SizedBox(height: 4),
                  Text(item.commentPreview, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, color: Colors.black54)),
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