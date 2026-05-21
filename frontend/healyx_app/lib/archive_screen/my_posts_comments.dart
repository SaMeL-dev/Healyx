// 내 게시글 / 댓글 보관함 화면
// GET    /api/community/my/posts                — 내가 쓴 게시글 목록
// GET    /api/community/my/comments             — 내가 쓴 댓글 목록
// DELETE /api/community/posts/{postId}          — 내 게시글 삭제
// DELETE /api/community/my/comments/{commentId} — 내 댓글 삭제

import 'package:flutter/material.dart';
import 'package:healyx_app/community_screen/community_detail.dart';
import 'package:healyx_app/dialogs/archive_delete_dialog.dart';

import '../app_language.dart';
import '../community_screen/services/community_service.dart';

class MyPostsCommentsScreen extends StatefulWidget {
  const MyPostsCommentsScreen({super.key});

  @override
  State<MyPostsCommentsScreen> createState() => _MyPostsCommentsScreenState();
}

class _MyPostsCommentsScreenState extends State<MyPostsCommentsScreen> {
  static const Color mainBlue = Color(0xFF2260FF);

  bool _isPostTab = true;
  bool _isLoading = true;

  String? _errorMessage;

  int? _deletingPostId;
  int? _deletingCommentId;

  List<MyCommunityPost> _posts = [];
  List<MyCommunityComment> _comments = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  String _formatDate(String value) {
    final dateTime = DateTime.tryParse(value);

    if (dateTime == null) {
      return '';
    }

    final local = dateTime.toLocal();

    final year = local.year.toString();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');

    return '$year. $month. $day';
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final service = CommunityService();

      final results = await Future.wait([
        service.getMyPosts(),
        service.getMyComments(),
      ]);

      if (!mounted) return;

      setState(() {
        _posts = results[0] as List<MyCommunityPost>;
        _comments = results[1] as List<MyCommunityComment>;
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

  Future<void> _deletePost(MyCommunityPost post) async {
    if (_deletingPostId != null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: mainBlue.withOpacity(0.4),
      builder: (_) => const ArchiveDeleteDialog(),
    );

    if (confirmed != true || !mounted) return;

    try {
      setState(() {
        _deletingPostId = post.postId;
      });

      await CommunityService().deletePost(
        postId: post.postId,
      );

      if (!mounted) return;

      setState(() {
        _posts.removeWhere((item) => item.postId == post.postId);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('게시글이 삭제되었습니다.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _deletingPostId = null;
        });
      }
    }
  }

  Future<void> _deleteComment(MyCommunityComment comment) async {
    if (_deletingCommentId != null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: mainBlue.withOpacity(0.4),
      builder: (_) => const ArchiveDeleteDialog(),
    );

    if (confirmed != true || !mounted) return;

    try {
      setState(() {
        _deletingCommentId = comment.commentId;
      });

      await CommunityService().deleteMyComment(
        commentId: comment.commentId,
      );

      if (!mounted) return;

      setState(() {
        _comments.removeWhere(
              (item) => item.commentId == comment.commentId,
        );
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('댓글이 삭제되었습니다.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _deletingCommentId = null;
        });
      }
    }
  }

  Future<void> _goToPostDetail(int postId) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CommunityDetailScreen(
          postId: postId,
        ),
      ),
    );

    if (result == true) {
      await _loadData();
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
          icon: const Icon(
            Icons.chevron_left,
            color: Colors.black,
            size: 28,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          AppLanguage.t('archive_menu_posts'),
          style: const TextStyle(
            color: mainBlue,
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
              onChanged: (value) {
                setState(() {
                  _isPostTab = value;
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
          color: mainBlue,
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
                color: mainBlue,
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
                    backgroundColor: mainBlue,
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
      return RefreshIndicator(
        color: mainBlue,
        onRefresh: _loadData,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.55,
              child: Center(
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
                      AppLanguage.t('archive_empty_posts'),
                      style: const TextStyle(
                        fontSize: 15,
                        color: Color(0xFF9E9E9E),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: mainBlue,
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
            dateText: _formatDate(post.createdAt),
            isDeleting: _deletingPostId == post.postId,
            onTap: () => _goToPostDetail(post.postId),
            onDelete: () => _deletePost(post),
          );
        },
      ),
    );
  }

  Widget _buildCommentList() {
    if (_comments.isEmpty) {
      return RefreshIndicator(
        color: mainBlue,
        onRefresh: _loadData,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.55,
              child: Center(
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
                      AppLanguage.t('archive_empty_comments'),
                      style: const TextStyle(
                        fontSize: 15,
                        color: Color(0xFF9E9E9E),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: mainBlue,
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
            dateText: _formatDate(comment.createdAt),
            isDeleting: _deletingCommentId == comment.commentId,
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
              label: AppLanguage.t('archive_tab_posts'),
              isSelected: isPostTab,
              onTap: () => onChanged(true),
            ),
          ),
          Expanded(
            child: _TabButton(
              label: AppLanguage.t('archive_tab_comments'),
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
  final MyCommunityPost item;
  final String dateText;
  final bool isDeleting;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _PostCard({
    required this.item,
    required this.dateText,
    required this.isDeleting,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final title = item.title.isEmpty ? '제목 없음' : item.title;
    final preview = item.contentPreview.isEmpty ? '내용 없음' : item.contentPreview;

    return GestureDetector(
      onTap: isDeleting ? null : onTap,
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
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2260FF),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    preview,
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
                        item.likeCount.toString(),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF2260FF),
                        ),
                      ),
                      if (dateText.isNotEmpty) ...[
                        const SizedBox(width: 10),
                        Text(
                          dateText,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black38,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: isDeleting
                  ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF2260FF),
                ),
              )
                  : const Icon(
                Icons.close,
                color: Colors.black38,
                size: 18,
              ),
              onPressed: isDeleting ? null : onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── 댓글 카드 ─────────────────────────────────────────────────
class _CommentCard extends StatelessWidget {
  final MyCommunityComment item;
  final String dateText;
  final bool isDeleting;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _CommentCard({
    required this.item,
    required this.dateText,
    required this.isDeleting,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final postTitle = item.postTitle.isEmpty ? '제목 없음' : item.postTitle;
    final content = item.content.isEmpty ? '내용 없음' : item.content;

    return GestureDetector(
      onTap: isDeleting ? null : onTap,
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
                    postTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2260FF),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    content,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black54,
                    ),
                  ),
                  if (dateText.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      dateText,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black38,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              icon: isDeleting
                  ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF2260FF),
                ),
              )
                  : const Icon(
                Icons.close,
                color: Colors.black38,
                size: 18,
              ),
              onPressed: isDeleting ? null : onDelete,
            ),
          ],
        ),
      ),
    );
  }
}