// 커뮤니티 게시글 상세 화면
// 게시글 상세 조회 API를 통해 제목, 작성자, 작성일, 본문, 이미지, 좋아요, 북마크, 댓글을 표시하는 화면
// 게시글 원문보기 기능:
// - 선택 언어 기준으로 게시글 제목/본문 번역 API 호출
// - 원문보기 클릭 시 게시글 제목/본문과 댓글/대댓글을 모두 원문으로 전환
// - 기본 상태에서는 다른 사람이 작성한 댓글/대댓글을 선택 언어 기준으로 번역 표시
// - 내가 작성한 댓글/대댓글은 원문 그대로 표시
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app_language.dart';
import '../dialogs/report_dialog.dart';
import '../dialogs/delete_confirm_dialog.dart';
import '../dialogs/comment_delete_dialog.dart';
import 'community_write.dart';
import 'services/community_service.dart';

enum _CommunityToastType {
  success,
  warning,
  error,
}

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

  OverlayEntry? _toastEntry;
  Timer? _toastTimer;

  bool _isLoading = false;
  bool _isLikeProcessing = false;
  bool _isBookmarkProcessing = false;
  bool _isDeleteProcessing = false;
  bool _isReportProcessing = false;
  bool _isCommentSubmitting = false;
  bool _isTranslationProcessing = false;

  int? _deletingCommentId;
  int? _reportingCommentId;

  // 답글 작성 대상 댓글
  CommunityComment? _replyTargetComment;

  // 수정 중인 댓글
  CommunityComment? _editingComment;

  // 원문보기 상태
  bool _isOriginalMode = false;

  // 선택 언어 기준 게시글 번역 데이터
  CommunityPostTranslation? _postTranslation;

  // 선택 언어 기준 댓글/대댓글 번역 데이터
  final Map<int, CommunityCommentTranslation> _commentTranslations = {};

  // 현재 선택된 언어 코드
  String _selectedLanguageCode = 'ko';

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
    _removeCustomToast();
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

  String _normalizeLanguageCode(String? value) {
    final code = value?.trim().toLowerCase();

    if (code == null || code.isEmpty) {
      return 'ko';
    }

    const supportedCodes = {
      'ko',
      'en',
      'zh',
      'vi',
      'th',
      'ja',
    };

    if (supportedCodes.contains(code)) {
      return code;
    }

    return 'ko';
  }

  Future<String> _loadSelectedLanguageCode() async {
    final prefs = await SharedPreferences.getInstance();

    // AppLanguage.setLang()에서 실제로 저장하는 key
    final savedLanguage = prefs.getString('language_pref');

    if (savedLanguage != null && savedLanguage.trim().isNotEmpty) {
      final normalized = _normalizeLanguageCode(savedLanguage);

      debugPrint('[Community] selected language from language_pref: $normalized');

      return normalized;
    }

    // 혹시 AppLanguage.currentLang가 이미 갱신되어 있는 경우 대비
    final currentLang = AppLanguage.currentLang.value;

    if (currentLang.trim().isNotEmpty) {
      final normalized = _normalizeLanguageCode(currentLang);

      debugPrint('[Community] selected language from AppLanguage: $normalized');

      return normalized;
    }

    // 예비 호환용 key
    final candidates = [
      prefs.getString('preferredLanguage'),
      prefs.getString('languageCode'),
      prefs.getString('selectedLanguageCode'),
      prefs.getString('selectedLanguage'),
      prefs.getString('appLanguage'),
      prefs.getString('lang'),
    ];

    for (final candidate in candidates) {
      if (candidate != null && candidate.trim().isNotEmpty) {
        final normalized = _normalizeLanguageCode(candidate);

        debugPrint('[Community] selected language from fallback: $normalized');

        return normalized;
      }
    }

    debugPrint('[Community] selected language fallback to ko');

    return 'ko';
  }


  String _localizedCommunityErrorMessage(Object error) {
    final message = error.toString().replaceFirst('Exception: ', '').trim();
    final lowerMessage = message.toLowerCase();

    if (lowerMessage.contains('community guidelines') ||
        lowerMessage.contains('violates community') ||
        lowerMessage.contains('content violates') ||
        lowerMessage.contains('cleanbot') ||
        message.contains('(422)')) {
      return AppLanguage.t('community_cleanbot_blocked');
    }

    return message;
  }

  Future<CommunityPostTranslation?> _fetchPostTranslation({
    required int postId,
    required String lang,
    bool showError = false,
  }) async {
    try {
      final translation = await CommunityService().getPostTranslation(
        postId: postId,
        lang: lang,
        acceptLanguage: lang,
      );

      return translation;
    } catch (e) {
      debugPrint('[Community] getPostTranslation error: $e');

      if (showError && mounted) {
        _showSnackBar(
          _localizedCommunityErrorMessage(e),
          type: _CommunityToastType.error,
        );
      }

      return null;
    }
  }

  List<CommunityComment> _flattenComments(List<CommunityComment> comments) {
    final result = <CommunityComment>[];

    void collect(CommunityComment comment) {
      result.add(comment);

      for (final reply in comment.replies) {
        collect(reply);
      }
    }

    for (final comment in comments) {
      collect(comment);
    }

    return result;
  }

  Future<Map<int, CommunityCommentTranslation>> _fetchCommentTranslations({
    required List<CommunityComment> comments,
    required String lang,
    required int? currentUserId,
  }) async {
    final translations = <int, CommunityCommentTranslation>{};
    final allComments = _flattenComments(comments);

    final targets = allComments.where((comment) {
      if (comment.deleted) {
        return false;
      }

      if (currentUserId != null && comment.authorId == currentUserId) {
        return false;
      }

      return true;
    }).toList();

    if (targets.isEmpty) {
      return translations;
    }

    await Future.wait(
      targets.map((comment) async {
        try {
          final translation = await CommunityService().getCommentTranslation(
            commentId: comment.commentId,
            lang: lang,
            acceptLanguage: lang,
          );

          translations[comment.commentId] = translation;
        } catch (e) {
          debugPrint(
            '[Community] getCommentTranslation failed commentId=${comment.commentId}: $e',
          );
        }
      }),
    );

    return translations;
  }

  String _displayCommentContent(CommunityComment comment) {
    if (comment.deleted) {
      return AppLanguage.t('community_deleted_comment');
    }

    if (_isOriginalMode) {
      return comment.content;
    }

    final isMyComment = _myUserId != null && comment.authorId == _myUserId;

    if (isMyComment) {
      return comment.content;
    }

    final translation = _commentTranslations[comment.commentId];
    final translatedContent = translation?.translatedContent.trim() ?? '';

    if (translatedContent.isNotEmpty) {
      return translatedContent;
    }

    return comment.content;
  }

  Future<void> _loadPostDetail() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
        _isOriginalMode = false;
        _postTranslation = null;
        _commentTranslations.clear();
      });

      final prefs = await SharedPreferences.getInstance();
      final currentUserId = prefs.getInt('userId');
      final selectedLanguageCode = await _loadSelectedLanguageCode();

      final result = await CommunityService().getPostDetail(
        postId: widget.postId,
      );

      final isMyPost = currentUserId != null && result.authorId == currentUserId;

      CommunityPostTranslation? translation;
      Map<int, CommunityCommentTranslation> commentTranslations = {};

      // 내가 작성한 게시글은 이미 이해할 수 있으므로 원문 그대로 표시한다.
      // 다른 사람이 작성한 게시글만 선택 언어 기준으로 번역한다.
      if (!isMyPost) {
        translation = await _fetchPostTranslation(
          postId: result.postId,
          lang: selectedLanguageCode,
        );
      }

      commentTranslations = await _fetchCommentTranslations(
        comments: result.comments,
        lang: selectedLanguageCode,
        currentUserId: currentUserId,
      );

      if (!mounted) return;

      setState(() {
        _myUserId = currentUserId;
        _post = result;
        _postTranslation = translation;
        _commentTranslations
          ..clear()
          ..addAll(commentTranslations);
        _selectedLanguageCode = selectedLanguageCode;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = _localizedCommunityErrorMessage(e);
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
        _localizedCommunityErrorMessage(e),
        type: _CommunityToastType.error,
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
        result.bookmarked
            ? AppLanguage.t('community_bookmark_saved')
            : AppLanguage.t('community_bookmark_removed'),
      );
    } catch (e) {
      if (!mounted) return;

      _showSnackBar(
        _localizedCommunityErrorMessage(e),
        type: _CommunityToastType.error,
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

      _showSnackBar(AppLanguage.t('community_report_success'));
    } catch (e) {
      if (!mounted) return;

      _showSnackBar(
        _localizedCommunityErrorMessage(e),
        type: _CommunityToastType.error,
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

      _showSnackBar(AppLanguage.t('community_post_deleted'));

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      _showSnackBar(
        _localizedCommunityErrorMessage(e),
        type: _CommunityToastType.error,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isDeleteProcessing = false;
        });
      }
    }
  }

  Future<void> _toggleOriginalMode() async {
    final post = _post;

    if (post == null || _isMyPost || _isTranslationProcessing) {
      return;
    }

    if (_postTranslation == null) {
      try {
        setState(() {
          _isTranslationProcessing = true;
        });

        final translation = await _fetchPostTranslation(
          postId: post.postId,
          lang: _selectedLanguageCode,
          showError: true,
        );

        if (!mounted) return;

        if (translation == null) {
          _showSnackBar(
            AppLanguage.t('community_original_load_failed'),
            type: _CommunityToastType.warning,
          );
          return;
        }

        setState(() {
          _postTranslation = translation;
          _isOriginalMode = true;
        });

        _showSnackBar(AppLanguage.t('community_original_switched'));
      } finally {
        if (mounted) {
          setState(() {
            _isTranslationProcessing = false;
          });
        }
      }

      return;
    }

    setState(() {
      _isOriginalMode = !_isOriginalMode;
    });

    _showSnackBar(
      _isOriginalMode
          ? AppLanguage.t('community_original_switched')
          : AppLanguage.t('community_translated_switched'),
    );
  }

  Future<void> _submitComment() async {
    final post = _post;
    final content = _commentController.text.trim();
    final editingComment = _editingComment;
    final replyTarget = _replyTargetComment;

    if (post == null || _isCommentSubmitting) return;

    if (content.isEmpty) {
      if (editingComment != null) {
        _showSnackBar(
          AppLanguage.t('community_comment_edit_empty'),
          type: _CommunityToastType.warning,
        );
      } else {
        _showSnackBar(
          replyTarget == null
              ? AppLanguage.t('community_comment_empty')
              : AppLanguage.t('community_reply_empty'),
          type: _CommunityToastType.warning,
        );
      }
      return;
    }

    try {
      setState(() {
        _isCommentSubmitting = true;
      });

      if (editingComment != null) {
        await CommunityService().updateComment(
          commentId: editingComment.commentId,
          content: content,
        );
      } else if (replyTarget == null) {
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
        _editingComment = null;
        _replyTargetComment = null;
        _hasChanged = true;
      });

      await _loadPostDetail();

      if (!mounted) return;

      _showSnackBar(
        editingComment != null
            ? AppLanguage.t('community_comment_updated')
            : replyTarget == null
            ? AppLanguage.t('community_comment_created')
            : AppLanguage.t('community_reply_created'),
      );
    } catch (e) {
      if (!mounted) return;

      _showSnackBar(
        _localizedCommunityErrorMessage(e),
        type: _CommunityToastType.error,
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
      _showSnackBar(
        AppLanguage.t('community_my_comment_only'),
        type: _CommunityToastType.warning,
      );
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

        if (_editingComment?.commentId == comment.commentId) {
          _editingComment = null;
          _commentController.clear();
        }
      });

      await _loadPostDetail();

      if (!mounted) return;

      _showSnackBar(AppLanguage.t('community_comment_deleted'));
    } catch (e) {
      if (!mounted) return;

      _showSnackBar(
        _localizedCommunityErrorMessage(e),
        type: _CommunityToastType.error,
      );
    } finally {
      if (mounted) {
        setState(() {
          _deletingCommentId = null;
        });
      }
    }
  }

  Future<void> _confirmReportComment(CommunityComment comment) async {
    if (comment.deleted || _reportingCommentId != null) {
      return;
    }

    final isMyComment = _myUserId != null && comment.authorId == _myUserId;

    if (isMyComment) {
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
        _reportingCommentId = comment.commentId;
      });

      await CommunityService().reportContent(
        targetType: 'COMMENT',
        targetId: comment.commentId,
        reason: '부적절한 콘텐츠',
      );

      if (!mounted) return;

      _showSnackBar(AppLanguage.t('community_comment_reported'));
    } catch (e) {
      if (!mounted) return;

      _showSnackBar(
        _localizedCommunityErrorMessage(e),
        type: _CommunityToastType.error,
      );
    } finally {
      if (mounted) {
        setState(() {
          _reportingCommentId = null;
        });
      }
    }
  }

  void _handleEditCommentTap(CommunityComment comment) {
    if (comment.deleted) {
      return;
    }

    final isMyComment = _myUserId != null && comment.authorId == _myUserId;

    if (!isMyComment) {
      return;
    }

    setState(() {
      _editingComment = comment;
      _replyTargetComment = null;
      _commentController.text = comment.content;
      _commentController.selection = TextSelection.fromPosition(
        TextPosition(offset: _commentController.text.length),
      );
    });

    _commentFocusNode.requestFocus();
  }

  void _cancelEditComment() {
    setState(() {
      _editingComment = null;
      _commentController.clear();
    });
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
          initialTitle: _postTranslation?.originalTitle.isNotEmpty == true
              ? _postTranslation!.originalTitle
              : post.title,
          initialContent: _postTranslation?.originalContent.isNotEmpty == true
              ? _postTranslation!.originalContent
              : post.content,
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
    return _isDeleteProcessing || _isReportProcessing || _isTranslationProcessing;
  }

  String get _displayTitle {
    final post = _post;

    if (post == null) {
      return '';
    }

    if (_isOriginalMode &&
        _postTranslation != null &&
        _postTranslation!.originalTitle.trim().isNotEmpty) {
      return _postTranslation!.originalTitle;
    }

    if (!_isOriginalMode &&
        _postTranslation != null &&
        _postTranslation!.translatedTitle.trim().isNotEmpty) {
      return _postTranslation!.translatedTitle;
    }

    return post.title;
  }

  String get _displayContent {
    final post = _post;

    if (post == null) {
      return '';
    }

    if (post.blinded) {
      return AppLanguage.t('community_blinded_post');
    }

    if (_isOriginalMode &&
        _postTranslation != null &&
        _postTranslation!.originalContent.trim().isNotEmpty) {
      return _postTranslation!.originalContent;
    }

    if (!_isOriginalMode &&
        _postTranslation != null &&
        _postTranslation!.translatedContent.trim().isNotEmpty) {
      return _postTranslation!.translatedContent;
    }

    return post.content;
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

  void _removeCustomToast() {
    _toastTimer?.cancel();
    _toastTimer = null;
    _toastEntry?.remove();
    _toastEntry = null;
  }

  void _showSnackBar(
      String message, {
        _CommunityToastType type = _CommunityToastType.success,
      }) {
    if (!mounted || message.trim().isEmpty) return;

    _removeCustomToast();

    final overlay = Overlay.maybeOf(context);

    if (overlay == null) {
      return;
    }

    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final bool isSuccess = type == _CommunityToastType.success;

    final IconData iconData =
    isSuccess ? Icons.check_rounded : Icons.priority_high_rounded;
    final Color iconColor = isSuccess ? mainBlue : const Color(0xFFFF8A00);
    final Color iconBg = isSuccess ? lightBlue : const Color(0xFFFFF3E0);
    final Color borderColor =
    isSuccess ? const Color(0xFFD8E4FF) : const Color(0xFFFFD6A6);
    final Color textColor = isSuccess ? mainBlue : const Color(0xFFE06B00);

    _toastEntry = OverlayEntry(
      builder: (context) {
        return Positioned(
          left: 20,
          right: 20,
          bottom: bottomPadding + 26,
          child: IgnorePointer(
            ignoring: true,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 16 * (1 - value)),
                    child: child,
                  ),
                );
              },
              child: Material(
                color: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 13,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: borderColor,
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 14,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: iconBg,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          iconData,
                          color: iconColor,
                          size: 17,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          message,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 14,
                            height: 1.35,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    overlay.insert(_toastEntry!);

    _toastTimer = Timer(const Duration(milliseconds: 2200), () {
      _removeCustomToast();
    });
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
      _toggleOriginalMode();
    }
  }

  void _handleReplyTap(CommunityComment comment) {
    if (comment.deleted) {
      _showSnackBar(
        AppLanguage.t('community_deleted_reply_blocked'),
        type: _CommunityToastType.warning,
      );
      return;
    }

    setState(() {
      if (_editingComment != null) {
        _commentController.clear();
      }

      _editingComment = null;
      _replyTargetComment = comment;
    });

    _commentFocusNode.requestFocus();
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
                _errorMessage ?? AppLanguage.t('community_post_load_failed'),
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
                  child: Text(
                    AppLanguage.t('community_retry'),
                    style: const TextStyle(
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
    replyTarget.authorNickname.isEmpty
        ? AppLanguage.t('community_anonymous')
        : replyTarget.authorNickname;

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
              AppLanguage.t('community_replying_to_banner').replaceAll(
                '{nickname}',
                nickname,
              ),
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

  Widget _buildEditTargetBanner() {
    final editingComment = _editingComment;

    if (editingComment == null) {
      return const SizedBox.shrink();
    }

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
            Icons.edit_outlined,
            color: mainBlue,
            size: 18,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              AppLanguage.t('community_comment_editing'),
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
            onTap: _isCommentSubmitting ? null : _cancelEditComment,
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
    final isEditMode = _editingComment != null;
    final isReplyMode = !isEditMode && _replyTargetComment != null;

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
          if (isEditMode) _buildEditTargetBanner() else _buildReplyTargetBanner(),
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
                    hintText: isReplyMode
                        ? AppLanguage.t('community_reply_hint')
                        : AppLanguage.t('community_comment_hint'),
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
                    isEditMode
                        ? AppLanguage.t('community_comment_update_submit')
                        : isReplyMode
                        ? AppLanguage.t('community_reply_submit')
                        : AppLanguage.t('community_comment_submit'),
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
    final isReporting = _reportingCommentId == comment.commentId;
    final mentionNickname =
    isReply ? _findNicknameByUserId(comment.mentionUserId) : null;

    return _CommentCard(
      nickname: comment.authorNickname.isEmpty
          ? AppLanguage.t('community_anonymous')
          : comment.authorNickname,
      mentionNickname: mentionNickname,
      content: _displayCommentContent(comment),
      date: _formatDate(comment.createdAt),
      isMyComment: isMyComment && !comment.deleted,
      isDeleted: comment.deleted,
      isDeleting: isDeleting,
      isReporting: isReporting,
      isReply: isReply || comment.depth > 0,
      onEdit: () => _handleEditCommentTap(comment),
      onDelete: () => _confirmDeleteComment(comment),
      onReport: () => _confirmReportComment(comment),
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
            Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  AppLanguage.t('community_no_comments'),
                  style: const TextStyle(
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

  Widget _buildTranslationBadge() {
    if (_postTranslation == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: lightBlue,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _isOriginalMode
            ? AppLanguage.t('community_original_badge')
            : AppLanguage.t('community_translated_badge').replaceAll(
          '{lang}',
          _selectedLanguageCode,
        ),
        style: const TextStyle(
          color: mainBlue,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildPostContent() {
    final post = _post;

    if (post == null) {
      return _buildError();
    }

    final dateText = _formatDate(post.createdAt);
    final displayTitle = _displayTitle.trim().isEmpty
        ? AppLanguage.t('community_no_title')
        : _displayTitle;
    final displayContent = _displayContent;

    return Expanded(
      child: RefreshIndicator(
        color: mainBlue,
        onRefresh: _loadPostDetail,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
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
                                displayTitle,
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
                                        _isOriginalMode
                                            ? AppLanguage.t('community_view_translated')
                                            : AppLanguage.t(
                                          'community_menu_original',
                                        ),
                                      ),
                                    ),
                                  ];
                                }
                              },
                            ),
                          ],
                        ),
                        _buildTranslationBadge(),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Text(
                              post.authorNickname.isEmpty
                                  ? AppLanguage.t('community_anonymous')
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
                        displayContent,
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
                ],
              ),
            ),
            SliverFillRemaining(
              hasScrollBody: false,
              child: _buildCommentSection(post),
            ),
          ],
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
  final bool isReporting;
  final bool isReply;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onReport;
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
    required this.isReporting,
    required this.isReply,
    required this.onEdit,
    required this.onDelete,
    required this.onReport,
    required this.onReply,
    required this.replies,
  });

  static const Color mainBlue = Color(0xFF2260FF);
  static const Color softBg = Color(0xFFECF1FF);

  Widget _buildHeaderActions(Color backgroundColor) {
    if (isDeleted) {
      return const SizedBox.shrink();
    }

    if (isMyComment) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _CommentActionChip(
            text: AppLanguage.t('community_comment_edit'),
            isLoading: false,
            backgroundColor: backgroundColor,
            onTap: onEdit,
          ),
          const SizedBox(width: 6),
          _CommentActionChip(
            text: AppLanguage.t('community_delete'),
            isLoading: isDeleting,
            backgroundColor: backgroundColor,
            onTap: onDelete,
          ),
        ],
      );
    }

    return _CommentActionChip(
      text: AppLanguage.t('community_comment_report'),
      isLoading: isReporting,
      backgroundColor: backgroundColor,
      onTap: onReport,
    );
  }

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
    final Color actionButtonColor = isReply ? Colors.white : softBg;

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
                  _buildHeaderActions(actionButtonColor),
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
                  _buildHeaderActions(actionButtonColor),
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

class _CommentActionChip extends StatelessWidget {
  final String text;
  final bool isLoading;
  final Color backgroundColor;
  final VoidCallback onTap;

  const _CommentActionChip({
    required this.text,
    required this.isLoading,
    required this.backgroundColor,
    required this.onTap,
  });

  static const Color mainBlue = Color(0xFF2260FF);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 4,
        ),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: isLoading
            ? const SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: mainBlue,
          ),
        )
            : Text(
          text,
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
