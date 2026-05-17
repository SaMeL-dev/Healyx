// 내 게시글 / 댓글 보관함 화면
// GET    /api/community/my/posts                — 내가 쓴 게시글 목록
// DELETE /api/community/my/posts/{postId}       — 내 게시글 삭제
// GET    /api/community/my/comments             — 내가 쓴 댓글 목록
// DELETE /api/community/my/comments/{commentId} — 내 댓글 삭제

import 'package:flutter/material.dart';
import 'package:healyx_app/community_screen/community_detail.dart';
import 'package:healyx_app/dialogs/archive_delete_dialog.dart';

import '../app_language.dart';
import '../services/community_service.dart';

class MyPostsCommentsScreen extends StatefulWidget {
  const MyPostsCommentsScreen({super.key});

  @override
  State<MyPostsCommentsScreen> createState() => _MyPostsCommentsScreenState();
}

class _MyPostsCommentsScreenState extends State<MyPostsCommentsScreen> {
  bool _isPostTab = true;
  bool _isLoading = true;
  String? _errorMessage;

  List<MyPostData> _posts = [];
  List<MyCommentData> _comments = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // 게시글·댓글 목록 동시 로드
  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final results = await Future.wait([
        CommunityService.getMyPosts(),
        CommunityService.getMyComments(),
      ]);

      if (!mounted) return;

      setState(() {
        _posts = results[0] as List<MyPostData>;
        _comments = results[1] as List<MyCommentData>;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  // 게시글 삭제 — 다이얼로그 확인 후 API 호출
  Future<void> _deletePost(MyPostData post) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: const Color(0xFF2260FF).withOpacity(0.4),
      builder: (_) => const ArchiveDeleteDialog(),
    );

    if (confirmed != true || !mounted) return;

    final success = await CommunityService.deleteMyPost(post.postId);

    if (!mounted) return;

    if (success) {
      setState(() {
        _posts.removeWhere((e) => e.postId == post.postId);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLanguage.t('error_retry'))),
      );
    }
  }

  // 댓글 삭제 — 다이얼로그 확인 후 API 호출
  Future<void> _deleteComment(MyCommentData comment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: const Color(0xFF2260FF).withOpacity(0.4),
      builder: (_) => const ArchiveDeleteDialog(),
    );

    if (confirmed != true || !mounted) return;

    final success = await CommunityService.deleteMyComment(comment.commentId);

    if (!mounted) return;

    if (success) {
      setState(() {
        _comments.removeWhere((e) => e.commentId == comment.commentId);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLanguage.t('error_retry'))),
      );
    }
  }

  void _goToPostDetail(int postId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CommunityDetailScreen(
          postId: postId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.chevron_left,
            color: Colors.black,
            size: 28,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          AppLanguage.t('archive_menu_posts'), // '내 게시글 / 댓글'
          style: const TextStyle(
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
              onChanged: (val) {
                setState(() {
                  _isPostTab = val;
                });
              },
            ),
          ),

          const SizedBox(height: 8),

          Expanded(
            child: _buildBody(),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF2260FF),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Color(0xFF2260FF),
                size: 42,
              ),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 42,
                child: ElevatedButton(
                  onPressed: _loadData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2260FF),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(21),
                    ),
                  ),
                  child: const Text(
                    '다시 시도',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return _isPostTab ? _buildPostList() : _buildCommentList();
  }

  Widget _buildPostList() {
    if (_posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.article_outlined,
              size: 56,
              color: Color(0xFFBBBBBB),
            ),
            const SizedBox(height: 16),
            Text(
              AppLanguage.t('archive_empty_posts'), // '작성한 게시글이 없습니다.'
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF9E9E9E),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: const Color(0xFF2260FF),
      onRefresh: _loadData,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _posts.length,
        separatorBuilder: (_, __) => const Divider(
          height: 1,
          color: Color(0xFFF2F2F2),
        ),
        itemBuilder: (context, index) {
          final post = _posts[index];

          return _PostCard(
            item: post,
            onTap: () => _goToPostDetail(post.postId),
            onDelete: () => _deletePost(post),
          );
        },
      ),
    );
  }

  Widget _buildCommentList() {
    if (_comments.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.chat_bubble_outline,
              size: 56,
              color: Color(0xFFBBBBBB),
            ),
            const SizedBox(height: 16),
            Text(
              AppLanguage.t('archive_empty_comments'), // '작성한 댓글이 없습니다.'
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF9E9E9E),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: const Color(0xFF2260FF),
      onRefresh: _loadData,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _comments.length,
        separatorBuilder: (_, __) => const Divider(
          height: 1,
          color: Color(0xFFF2F2F2),
        ),
        itemBuilder: (context, index) {
          final comment = _comments[index];

          return _CommentCard(
            item: comment,
            onTap: () => _goToPostDetail(comment.postId),
            onDelete: () => _deleteComment(comment),
          );
        },
      ),
    );
  }
}

// ─── 탭 토글 ───────────────────────────────────────────────────
class _TabToggle extends StatelessWidget {
  final bool isPostTab;
  final ValueChanged<bool> onChanged;

  const _TabToggle({
    required this.isPostTab,
    required this.onChanged,
  });

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
          Expanded(
            child: _TabButton(
              label: AppLanguage.t('archive_tab_posts'), // '게시글'
              isSelected: isPostTab,
              onTap: () => onChanged(true),
            ),
          ),
          Expanded(
            child: _TabButton(
              label: AppLanguage.t('archive_tab_comments'), // '댓글'
              isSelected: !isPostTab,
              onTap: () => onChanged(false),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

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

// ─── 게시글 카드 ────────────────────────────────────────────────
class _PostCard extends StatelessWidget {
  final MyPostData item;
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
                  Text(
                    item.title,
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
                      fontSize: 13,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.favorite_border,
                        size: 14,
                        color: Color(0xFF2260FF),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        item.likeCount == 0 ? '0' : '${item.likeCount}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF2260FF),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(
                Icons.close,
                color: Colors.black38,
                size: 18,
              ),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── 댓글 카드 ─────────────────────────────────────────────────
class _CommentCard extends StatelessWidget {
  final MyCommentData item;
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
                  Text(
                    item.postTitle,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2260FF),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.commentPreview,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(
                Icons.close,
                color: Colors.black38,
                size: 18,
              ),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}