// 커뮤니티 게시글 상세 화면
// 게시글 상세 조회 API를 통해 제목, 작성자, 작성일, 본문, 이미지, 좋아요, 북마크, 댓글을 표시하는 화면
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app_language.dart';
import '../dialogs/report_dialog.dart';
import '../dialogs/delete_confirm_dialog.dart';
import '../dialogs/comment_delete_dialog.dart';
import 'community_write.dart';
import 'services/community_service.dart';

class CommunityDetailScreen extends StatefulWidget {
  final int postId;

  const CommunityDetailScreen({
    super.key,
    required this.postId,
  });

  @override
  State<CommunityDetailScreen> createState() => _CommunityDetailScreenState();
}

class _CommunityDetailScreenState extends State<CommunityDetailScreen> {
  static const Color mainBlue = Color(0xFF2260FF);
  static const Color lightBlue = Color(0xFFEFF2FF);
  static const Color commentBg = Color(0xFFE2E9FF);

  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocusNode = FocusNode();

  bool _isLoading = false;
  bool _isLikeProcessing = false;
  bool _isBookmarkProcessing = false;
  bool _isDeleteProcessing = false;
  bool _isReportProcessing = false;
  bool _isCommentSubmitting = false;

  int? _deletingCommentId;

  // 답글 작성 대상 댓글
  CommunityComment? _replyTargetComment;

  // 수정/좋아요/북마크/댓글 변경 후 상세 화면에서 메인으로 돌아갈 때 목록 새로고침을 알려주기 위한 값
  bool _hasChanged = false;

  String? _errorMessage;
  CommunityPostDetail? _post;
  int? _myUserId;

  @override
  void initState() {
    super.initState();
    _loadMyUserId();
    _loadPostDetail();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _commentFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadMyUserId() async {
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;

    setState(() {
      _myUserId = prefs.getInt('userId');
    });
  }

  Future<void> _loadPostDetail() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final result = await CommunityService().getPostDetail(
        postId: widget.postId,
      );

      if (!mounted) return;

      setState(() {
        _post = result;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  CommunityPostDetail _copyPost(
      CommunityPostDetail post, {
        int? likeCount,
        bool? myLikeExists,
        bool? myBookmarkExists,
      }) {
    return CommunityPostDetail(
      postId: post.postId,
      authorId: post.authorId,
      authorNickname: post.authorNickname,
      title: post.title,
      content: post.content,
      likeCount: likeCount ?? post.likeCount,
      viewCount: post.viewCount,
      createdAt: post.createdAt,
      updatedAt: post.updatedAt,
      imageUrls: post.imageUrls,
      myLikeExists: myLikeExists ?? post.myLikeExists,
      myBookmarkExists: myBookmarkExists ?? post.myBookmarkExists,
      comments: post.comments,
      blinded: post.blinded,
    );
  }

  Future<void> _toggleLike() async {
    final post = _post;

    if (post == null || _isLikeProcessing) return;

    try {
      setState(() {
        _isLikeProcessing = true;
      });

      final result = await CommunityService().toggleLike(
        postId: post.postId,
      );

      if (!mounted) return;

      setState(() {
        _post = _copyPost(
          post,
          likeCount: result.likeCount,
          myLikeExists: result.liked,
        );
        _hasChanged = true;
      });
    } catch (e) {
      if (!mounted) return;

      _showSnackBar(
        e.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLikeProcessing = false;
        });
      }
    }
  }

  Future<void> _toggleBookmark() async {
    final post = _post;

    if (post == null || _isBookmarkProcessing) return;

    try {
      setState(() {
        _isBookmarkProcessing = true;
      });

      final result = await CommunityService().toggleBookmark(
        postId: post.postId,
      );

      if (!mounted) return;

      setState(() {
        _post = _copyPost(
          post,
          myBookmarkExists: result.bookmarked,
        );
        _hasChanged = true;
      });

      _showSnackBar(
        result.bookmarked ? '북마크에 저장되었습니다.' : '북마크가 해제되었습니다.',
      );
    } catch (e) {
      if (!mounted) return;

      _showSnackBar(
        e.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isBookmarkProcessing = false;
        });
      }
    }
  }

  Future<void> _confirmReportPost() async {
    final post = _post;

    if (post == null || _isMyPost || _isReportProcessing) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: mainBlue.withOpacity(0.5),
      builder: (_) => const ReportDialog(),
    );

    if (confirmed != true || !mounted) {
      return;
    }

    try {
      setState(() {
        _isReportProcessing = true;
      });

      await CommunityService().reportContent(
        targetType: 'POST',
        targetId: post.postId,
        reason: '부적절한 콘텐츠',
      );

      if (!mounted) return;

      _showSnackBar('신고가 접수되었습니다.');
    } catch (e) {
      if (!mounted) return;

      _showSnackBar(
        e.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isReportProcessing = false;
        });
      }
    }
  }

  Future<void> _confirmDeletePost() async {
    final post = _post;

    if (post == null || !_isMyPost || _isDeleteProcessing) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: mainBlue.withOpacity(0.5),
      builder: (_) => const DeleteConfirmDialog(),
    );

    if (confirmed != true || !mounted) {
      return;
    }

    try {
      setState(() {
        _isDeleteProcessing = true;
      });

      await CommunityService().deletePost(
        postId: post.postId,
      );

      if (!mounted) return;

      _showSnackBar('게시글이 삭제되었습니다.');

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      _showSnackBar(
        e.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isDeleteProcessing = false;
        });
      }
    }
  }

  Future<void> _submitComment() async {
    final post = _post;
    final content = _commentController.text.trim();
    final replyTarget = _replyTargetComment;

    if (post == null || _isCommentSubmitting) return;

    if (content.isEmpty) {
      _showSnackBar(
        replyTarget == null ? '댓글을 입력해주세요.' : '답글을 입력해주세요.',
      );
      return;
    }

    try {
      setState(() {
        _isCommentSubmitting = true;
      });

      if (replyTarget == null) {
        await CommunityService().createComment(
          postId: post.postId,
          content: content,
        );
      } else {
        await CommunityService().createComment(
          postId: post.postId,
          content: content,
          parentCommentId: replyTarget.depth > 0
              ? replyTarget.parentCommentId ?? replyTarget.commentId
              : replyTarget.commentId,
          mentionUserId: replyTarget.authorId,
        );
      }

      if (!mounted) return;

      _commentController.clear();
      FocusScope.of(context).unfocus();

      setState(() {
        _replyTargetComment = null;
        _hasChanged = true;
      });

      await _loadPostDetail();

      if (!mounted) return;

      _showSnackBar(
        replyTarget == null ? '댓글이 등록되었습니다.' : '답글이 등록되었습니다.',
      );
    } catch (e) {
      if (!mounted) return;

      _showSnackBar(
        e.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isCommentSubmitting = false;
        });
      }
    }
  }

  Future<void> _confirmDeleteComment(CommunityComment comment) async {
    if (_deletingCommentId != null || comment.deleted) {
      return;
    }

    final isMyComment = _myUserId != null && comment.authorId == _myUserId;

    if (!isMyComment) {
      _showSnackBar('내가 작성한 댓글만 삭제할 수 있습니다.');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: mainBlue.withOpacity(0.5),
      builder: (_) => const CommentDeleteDialog(),
    );

    if (confirmed != true || !mounted) {
      return;
    }

    try {
      setState(() {
        _deletingCommentId = comment.commentId;
      });

      await CommunityService().deleteComment(
        commentId: comment.commentId,
      );

      if (!mounted) return;

      setState(() {
        _hasChanged = true;

        if (_replyTargetComment?.commentId == comment.commentId) {
          _replyTargetComment = null;
        }
      });

      await _loadPostDetail();

      if (!mounted) return;

      _showSnackBar('댓글이 삭제되었습니다.');
    } catch (e) {
      if (!mounted) return;

      _showSnackBar(
        e.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) {
        setState(() {
          _deletingCommentId = null;
        });
      }
    }
  }

  Future<void> _goToEditPost() async {
    final post = _post;

    if (post == null || !_isMyPost) {
      return;
    }

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CommunityWriteScreen(
          postId: post.postId,
          initialTitle: post.title,
          initialContent: post.content,
          initialImageUrls: post.imageUrls,
        ),
      ),
    );

    if (result == true) {
      _hasChanged = true;
      await _loadPostDetail();
    }
  }

  bool get _isMyPost {
    final post = _post;

    if (post == null || _myUserId == null) {
      return false;
    }

    return post.authorId == _myUserId;
  }

  bool get _isMenuProcessing {
    return _isDeleteProcessing || _isReportProcessing;
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

  String? _findNicknameByUserId(int? userId) {
    if (userId == null || _post == null) {
      return null;
    }

    for (final comment in _post!.comments) {
      final nickname = _findNicknameInCommentTree(comment, userId);

      if (nickname != null && nickname.isNotEmpty) {
        return nickname;
      }
    }

    return null;
  }

  String? _findNicknameInCommentTree(
      CommunityComment comment,
      int userId,
      ) {
    if (comment.authorId == userId && comment.authorNickname.isNotEmpty) {
      return comment.authorNickname;
    }

    for (final reply in comment.replies) {
      final nickname = _findNicknameInCommentTree(reply, userId);

      if (nickname != null && nickname.isNotEmpty) {
        return nickname;
      }
    }

    return null;
  }

  void _showSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _goBack() {
    Navigator.pop(context, _hasChanged ? true : null);
  }

  void _handleMenuSelected(String value) {
    if (value == 'report') {
      _confirmReportPost();
    } else if (value == 'delete') {
      _confirmDeletePost();
    } else if (value == 'edit') {
      _goToEditPost();
    } else if (value == 'view') {
      _showSnackBar('원문보기 기능은 추후 연결 예정입니다.');
    }
  }

  void _handleReplyTap(CommunityComment comment) {
    if (comment.deleted) {
      _showSnackBar('삭제된 댓글에는 답글을 작성할 수 없습니다.');
      return;
    }

    setState(() {
      _replyTargetComment = comment;
    });

    _commentFocusNode.requestFocus();

    _showSnackBar(
      '${comment.authorNickname.isEmpty ? '익명' : comment.authorNickname}님에게 답글 작성 중입니다.',
    );
  }

  void _cancelReply() {
    setState(() {
      _replyTargetComment = null;
    });
  }

  Widget _buildHeader() {
    return Column(
      children: [
        const SizedBox(height: 18),
        Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 18),
                child: IconButton(
                  onPressed: _goBack,
                  icon: const Icon(
                    Icons.arrow_back_ios_new,
                    color: mainBlue,
                    size: 22,
                  ),
                ),
              ),
            ),
            Text(
              AppLanguage.t('community'),
              style: const TextStyle(
                color: mainBlue,
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 26),
      ],
    );
  }

  Widget _buildLoading() {
    return const Expanded(
      child: Center(
        child: CircularProgressIndicator(
          color: mainBlue,
        ),
      ),
    );
  }

  Widget _buildError() {
    return Expanded(
      child: Center(
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
                _errorMessage ?? '게시글을 불러오지 못했습니다.',
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
                  onPressed: _loadPostDetail,
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
      ),
    );
  }

  Widget _buildImageList(List<String> imageUrls) {
    if (imageUrls.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        const SizedBox(height: 24),
        SizedBox(
          height: 180,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: imageUrls.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final imageUrl = imageUrls[index];

              return ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  imageUrl,
                  width: 180,
                  height: 180,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) {
                      return child;
                    }

                    return Container(
                      width: 180,
                      height: 180,
                      color: lightBlue,
                      alignment: Alignment.center,
                      child: const CircularProgressIndicator(
                        color: mainBlue,
                        strokeWidth: 2,
                      ),
                    );
                  },
                  errorBuilder: (_, error, ___) {
                    debugPrint('[Community] image load error: $error');
                    debugPrint('[Community] image url: $imageUrl');

                    return Container(
                      width: 180,
                      height: 180,
                      color: lightBlue,
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.broken_image_outlined,
                        color: mainBlue,
                        size: 34,
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildReplyTargetBanner() {
    final replyTarget = _replyTargetComment;

    if (replyTarget == null) {
      return const SizedBox.shrink();
    }

    final nickname =
    replyTarget.authorNickname.isEmpty ? '익명' : replyTarget.authorNickname;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: lightBlue,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.reply,
            color: mainBlue,
            size: 18,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              '$nickname님에게 답글 작성 중',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: mainBlue,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          GestureDetector(
            onTap: _isCommentSubmitting ? null : _cancelReply,
            child: const Icon(
              Icons.close,
              color: mainBlue,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentInput() {
    final isReplyMode = _replyTargetComment != null;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 6,
            offset: const Offset(1, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildReplyTargetBanner(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  focusNode: _commentFocusNode,
                  enabled: !_isCommentSubmitting,
                  minLines: 1,
                  maxLines: 4,
                  keyboardType: TextInputType.multiline,
                  decoration: InputDecoration(
                    hintText: isReplyMode ? '답글을 입력해주세요.' : '댓글을 입력해주세요.',
                    hintStyle: const TextStyle(
                      color: Colors.black38,
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 36,
                child: ElevatedButton(
                  onPressed: _isCommentSubmitting ? null : _submitComment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: mainBlue,
                    disabledBackgroundColor: Colors.grey.shade300,
                    foregroundColor: Colors.white,
                    disabledForegroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: _isCommentSubmitting
                      ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                      : Text(
                    isReplyMode ? '답글' : '등록',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCommentCard(CommunityComment comment, {bool isReply = false}) {
    final isMyComment = _myUserId != null && comment.authorId == _myUserId;
    final isDeleting = _deletingCommentId == comment.commentId;
    final mentionNickname =
    isReply ? _findNicknameByUserId(comment.mentionUserId) : null;

    return _CommentCard(
      nickname: comment.authorNickname.isEmpty ? '익명' : comment.authorNickname,
      mentionNickname: mentionNickname,
      content: comment.deleted ? '삭제된 댓글입니다.' : comment.content,
      date: _formatDate(comment.createdAt),
      isMyComment: isMyComment && !comment.deleted,
      isDeleted: comment.deleted,
      isDeleting: isDeleting,
      isReply: isReply || comment.depth > 0,
      onDelete: () => _confirmDeleteComment(comment),
      onReply: () => _handleReplyTap(comment),
      replies: comment.replies
          .map(
            (reply) => _buildCommentCard(
          reply,
          isReply: true,
        ),
      )
          .toList(),
    );
  }

  Widget _buildCommentSection(CommunityPostDetail post) {
    final comments = post.comments;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: commentBg,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCommentInput(),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 14),
            child: Text(
              AppLanguage.t('community_comment_count').replaceAll(
                '{count}',
                post.totalCommentCount.toString(),
              ),
              style: const TextStyle(
                color: mainBlue,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          if (comments.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  '아직 댓글이 없습니다.',
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            )
          else
            ...comments.map((comment) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _buildCommentCard(comment),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildReactionButtons(CommunityPostDetail post) {
    return Padding(
      padding: const EdgeInsets.only(right: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          GestureDetector(
            onTap: _isLikeProcessing ? null : _toggleLike,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: lightBlue,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  if (_isLikeProcessing)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.red,
                      ),
                    )
                  else
                    Icon(
                      post.myLikeExists
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: Colors.red,
                      size: 16,
                    ),
                  const SizedBox(width: 4),
                  Text(post.likeCount.toString()),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _isBookmarkProcessing ? null : _toggleBookmark,
            child: Container(
              padding: const EdgeInsets.all(4),
              color: Colors.transparent,
              child: _isBookmarkProcessing
                  ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: mainBlue,
                ),
              )
                  : Icon(
                post.myBookmarkExists
                    ? Icons.bookmark
                    : Icons.bookmark_border,
                color: mainBlue,
                size: 28,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostContent() {
    final post = _post;

    if (post == null) {
      return _buildError();
    }

    final dateText = _formatDate(post.createdAt);

    return Expanded(
      child: RefreshIndicator(
        color: mainBlue,
        onRefresh: _loadPostDetail,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            post.title.isEmpty ? '제목 없음' : post.title,
                            style: const TextStyle(
                              color: mainBlue,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        PopupMenuButton<String>(
                          color: Colors.white,
                          icon: _isMenuProcessing
                              ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: mainBlue,
                            ),
                          )
                              : const Icon(
                            Icons.more_vert,
                            color: mainBlue,
                          ),
                          onSelected:
                          _isMenuProcessing ? null : _handleMenuSelected,
                          itemBuilder: (context) {
                            if (_isMyPost) {
                              return [
                                PopupMenuItem(
                                  value: 'edit',
                                  child: Text(
                                    AppLanguage.t('community_menu_edit'),
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Text(
                                    AppLanguage.t('community_menu_delete'),
                                  ),
                                ),
                              ];
                            } else {
                              return [
                                PopupMenuItem(
                                  value: 'report',
                                  child: Text(
                                    AppLanguage.t('community_menu_report'),
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'view',
                                  child: Text(
                                    AppLanguage.t('community_menu_original'),
                                  ),
                                ),
                              ];
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          post.authorNickname.isEmpty
                              ? '익명'
                              : post.authorNickname,
                          style: const TextStyle(
                            color: mainBlue,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          dateText,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(height: 1, color: mainBlue),
                  ],
                ),
              ),
              const SizedBox(height: 34),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    post.blinded
                        ? '신고 누적으로 가려진 게시글입니다.'
                        : post.content,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 16,
                      height: 1.55,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ),
              _buildImageList(post.imageUrls),
              const SizedBox(height: 34),
              _buildReactionButtons(post),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(height: 1, color: mainBlue),
              ),
              const SizedBox(height: 20),
              _buildCommentSection(post),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _goBack();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              if (_isLoading)
                _buildLoading()
              else if (_errorMessage != null)
                _buildError()
              else
                _buildPostContent(),
            ],
          ),
        ),
      ),
    );
  }
}

class _CommentCard extends StatelessWidget {
  final String nickname;
  final String? mentionNickname;
  final String content;
  final String date;
  final bool isMyComment;
  final bool isDeleted;
  final bool isDeleting;
  final bool isReply;
  final VoidCallback onDelete;
  final VoidCallback onReply;
  final List<Widget> replies;

  const _CommentCard({
    required this.nickname,
    required this.mentionNickname,
    required this.content,
    required this.date,
    required this.isMyComment,
    required this.isDeleted,
    required this.isDeleting,
    required this.isReply,
    required this.onDelete,
    required this.onReply,
    required this.replies,
  });

  static const Color mainBlue = Color(0xFF2260FF);
  static const Color softBg = Color(0xFFECF1FF);

  Widget _buildContentText() {
    final bool shouldShowMention = isReply &&
        !isDeleted &&
        mentionNickname != null &&
        mentionNickname!.isNotEmpty;

    final double fontSize = isReply ? 13 : 14;

    if (!shouldShowMention) {
      return Text(
        content,
        style: TextStyle(
          fontSize: fontSize,
          height: 1.45,
          color: isDeleted ? Colors.black45 : Colors.black87,
        ),
      );
    }

    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontSize: fontSize,
          height: 1.45,
          color: Colors.black87,
        ),
        children: [
          TextSpan(
            text: '@$mentionNickname ',
            style: const TextStyle(
              color: mainBlue,
              fontWeight: FontWeight.w800,
            ),
          ),
          TextSpan(
            text: content,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color cardColor = isReply ? softBg : Colors.white;
    final Color deleteButtonColor = isReply ? Colors.white : softBg;

    return Opacity(
      opacity: isDeleted ? 0.75 : 1,
      child: Container(
        padding: EdgeInsets.all(isReply ? 14 : 16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isReply
              ? []
              : [
            BoxShadow(
              color: Colors.black.withOpacity(0.10),
              blurRadius: 5,
              offset: const Offset(1, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isReply) ...[
              Row(
                children: [
                  const Icon(
                    Icons.alternate_email,
                    color: mainBlue,
                    size: 14,
                  ),
                  const SizedBox(width: 3),
                  Expanded(
                    child: Text(
                      nickname,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: mainBlue,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  if (isMyComment)
                    _DeleteChip(
                      isDeleting: isDeleting,
                      backgroundColor: deleteButtonColor,
                      onDelete: onDelete,
                    ),
                ],
              ),
              const SizedBox(height: 5),
            ] else
              Row(
                children: [
                  Expanded(
                    child: Text(
                      nickname,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: mainBlue,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  if (isMyComment)
                    _DeleteChip(
                      isDeleting: isDeleting,
                      backgroundColor: deleteButtonColor,
                      onDelete: onDelete,
                    ),
                ],
              ),
            _buildContentText(),
            const SizedBox(height: 10),
            Row(
              children: [
                Text(
                  date,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black45,
                  ),
                ),
                const Spacer(),
                if (!isDeleted)
                  GestureDetector(
                    onTap: onReply,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isReply ? 10 : 12,
                        vertical: isReply ? 5 : 6,
                      ),
                      decoration: BoxDecoration(
                        color: mainBlue,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        AppLanguage.t('community_reply_write'),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isReply ? 12 : 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            if (replies.isNotEmpty) ...[
              const SizedBox(height: 14),
              Column(
                children: replies
                    .map(
                      (replyWidget) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: replyWidget,
                  ),
                )
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DeleteChip extends StatelessWidget {
  final bool isDeleting;
  final Color backgroundColor;
  final VoidCallback onDelete;

  const _DeleteChip({
    required this.isDeleting,
    required this.backgroundColor,
    required this.onDelete,
  });

  static const Color mainBlue = Color(0xFF2260FF);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isDeleting ? null : onDelete,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 4,
        ),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: isDeleting
            ? const SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: mainBlue,
          ),
        )
            : Text(
          AppLanguage.t('community_delete'),
          style: const TextStyle(
            color: mainBlue,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}