// 커뮤니티 글쓰기/수정 화면
// 제목 입력, 내용 입력, 사진 첨부 기능이 있는 화면
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../app_language.dart';
import '../dialogs/image_attach_dialog.dart';
import 'services/community_service.dart';

enum _CommunityToastType {
  success,
  warning,
  error,
}

class CommunityWriteScreen extends StatefulWidget {
  final int? postId;
  final String? initialTitle;
  final String? initialContent;
  final List<String> initialImageUrls;

  const CommunityWriteScreen({
    super.key,
    this.postId,
    this.initialTitle,
    this.initialContent,
    this.initialImageUrls = const [],
  });

  @override
  State<CommunityWriteScreen> createState() => _CommunityWriteScreenState();
}

class _CommunityWriteScreenState extends State<CommunityWriteScreen> {
  static const Color mainBlue = Color(0xFF2260FF);
  static const Color lightBlue = Color(0xFFEFF2FF);

  // Swagger 기준 게시글 이미지 최대 5장
  static const int maxImageCount = 5;

  final TextEditingController titleController = TextEditingController();
  final TextEditingController contentController = TextEditingController();

  final ImagePicker picker = ImagePicker();

  OverlayEntry? _toastEntry;
  Timer? _toastTimer;

  // 새로 선택한 이미지
  final List<XFile> selectedImages = [];

  // 수정 모드에서 기존 이미지 URL 표시 및 유지 목록 전송용
  late List<String> existingImageUrls;

  bool _titleError = false;
  bool _contentError = false;
  bool _isSubmitting = false;

  bool get _isEditMode => widget.postId != null;

  int get _totalImageCount => existingImageUrls.length + selectedImages.length;

  @override
  void initState() {
    super.initState();

    titleController.text = widget.initialTitle ?? '';
    contentController.text = widget.initialContent ?? '';
    existingImageUrls = List<String>.from(widget.initialImageUrls);
  }

  @override
  void dispose() {
    _removeCustomToast();
    titleController.dispose();
    contentController.dispose();
    super.dispose();
  }

  String _tWithCount(String key, int count) {
    return AppLanguage.t(key).replaceAll('{count}', count.toString());
  }

  List<String> _normalizeKeepImageUrls(List<String> urls) {
    return urls
        .map((url) => url.split('?').first.trim())
        .where((url) => url.isNotEmpty)
        .toList();
  }

  String _localizedCommunityErrorMessage(Object error) {
    final message = error.toString().replaceFirst('Exception: ', '').trim();
    final lowerMessage = message.toLowerCase();

    // 클린봇 422 에러 다국어 처리
    if (lowerMessage.contains('community guidelines') ||
        lowerMessage.contains('violates community') ||
        lowerMessage.contains('content violates') ||
        lowerMessage.contains('cleanbot') ||
        message.contains('(422)')) {
      return AppLanguage.t('community_cleanbot_blocked');
    }

    // 서버 500 에러 다국어 처리
    if (message.contains('(500)') ||
        lowerMessage.contains('internal server error') ||
        lowerMessage.contains('server error') ||
        message.contains('서버 내부 오류')) {
      return AppLanguage.t('community_server_error');
    }

    return message;
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

  void _showAttachDialog() {
    if (_totalImageCount >= maxImageCount) {
      _showSnackBar(
        _tWithCount('community_image_max_limit', maxImageCount),
        type: _CommunityToastType.warning,
      );
      return;
    }

    showDialog(
      context: context,
      barrierColor: Colors.black45,
      builder: (_) => ImageAttachDialog(
        onSelect: (source) async {
          final int remain = maxImageCount - _totalImageCount;

          if (remain <= 0) {
            _showSnackBar(
              _tWithCount('community_image_max_limit', maxImageCount),
              type: _CommunityToastType.warning,
            );
            return;
          }

          if (source == ImageSource.camera) {
            final XFile? image = await picker.pickImage(
              source: ImageSource.camera,
              imageQuality: 85,
            );

            if (image == null || !mounted) return;

            setState(() {
              selectedImages.add(image);
            });
          } else {
            final List<XFile> images = await picker.pickMultiImage(
              imageQuality: 85,
              limit: remain,
            );

            if (images.isEmpty || !mounted) return;

            setState(() {
              selectedImages.addAll(images.take(remain));
            });
          }
        },
      ),
    );
  }

  void _removeExistingImage(int index) {
    setState(() {
      existingImageUrls.removeAt(index);
    });
  }

  void _removeSelectedImage(int index) {
    setState(() {
      selectedImages.removeAt(index);
    });
  }

  Future<void> _submitPost() async {
    final String title = titleController.text.trim();
    final String content = contentController.text.trim();

    setState(() {
      _titleError = title.isEmpty;
      _contentError = content.isEmpty;
    });

    if (title.isEmpty || content.isEmpty) {
      return;
    }

    try {
      setState(() {
        _isSubmitting = true;
      });

      String successMessage;

      if (_isEditMode) {
        await CommunityService().updatePost(
          postId: widget.postId!,
          title: title,
          content: content,
          keepImageUrls: _normalizeKeepImageUrls(existingImageUrls),
          newImages: selectedImages,
        );

        if (!mounted) return;

        successMessage = AppLanguage.t('community_post_updated');
      } else {
        await CommunityService().createPost(
          title: title,
          content: content,
          images: selectedImages,
        );

        if (!mounted) return;

        successMessage = AppLanguage.t('community_post_created');
      }

      _showSnackBar(successMessage);

      // 커스텀 알림이 보일 시간을 조금 준 뒤 이전 화면 새로고침
      await Future.delayed(const Duration(milliseconds: 700));

      if (!mounted) return;

      // true를 넘겨주면 이전 화면에서 새로고침 가능
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
          _isSubmitting = false;
        });
      }
    }
  }

  Widget _buildAddImageCard() {
    if (_totalImageCount >= maxImageCount) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: _isSubmitting ? null : _showAttachDialog,
      child: Container(
        width: 112,
        height: 160,
        margin: const EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          color: lightBlue,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Center(
          child: Icon(
            Icons.add,
            color: mainBlue,
            size: 34,
          ),
        ),
      ),
    );
  }

  Widget _buildExistingImageCard(int index) {
    final imageUrl = existingImageUrls[index];

    return Stack(
      children: [
        Container(
          width: 112,
          height: 160,
          margin: const EdgeInsets.only(right: 10),
          decoration: BoxDecoration(
            color: lightBlue,
            borderRadius: BorderRadius.circular(14),
            image: DecorationImage(
              image: NetworkImage(imageUrl),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          top: 6,
          right: 18,
          child: GestureDetector(
            onTap: _isSubmitting ? null : () => _removeExistingImage(index),
            child: Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: mainBlue,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedImageCard(int index) {
    return Stack(
      children: [
        Container(
          width: 112,
          height: 160,
          margin: const EdgeInsets.only(right: 10),
          decoration: BoxDecoration(
            color: lightBlue,
            borderRadius: BorderRadius.circular(14),
            image: DecorationImage(
              image: FileImage(
                File(selectedImages[index].path),
              ),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          top: 6,
          right: 18,
          child: GestureDetector(
            onTap: _isSubmitting ? null : () => _removeSelectedImage(index),
            child: Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: mainBlue,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final String submitText = _isEditMode
        ? AppLanguage.t('community_write_edit_submit')
        : AppLanguage.t('community_write_submit');

    final String submittingText = _isEditMode
        ? AppLanguage.t('community_write_submitting_edit')
        : AppLanguage.t('community_write_submitting_create');

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),

            // 헤더
            Stack(
              alignment: Alignment.center,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: IconButton(
                      onPressed:
                      _isSubmitting ? null : () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.arrow_back_ios,
                        color: mainBlue,
                        size: 20,
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

            const SizedBox(height: 32),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 제목 라벨
                    Text(
                      AppLanguage.t('community_write_title_label'),
                      style: const TextStyle(
                        color: mainBlue,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // 제목 입력
                    Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: lightBlue,
                        borderRadius: BorderRadius.circular(14),
                        border: _titleError
                            ? Border.all(color: Colors.red, width: 1.5)
                            : null,
                      ),
                      child: TextField(
                        controller: titleController,
                        enabled: !_isSubmitting,
                        style: const TextStyle(fontSize: 15),
                        onChanged: (_) {
                          if (_titleError) {
                            setState(() {
                              _titleError = false;
                            });
                          }
                        },
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText:
                          AppLanguage.t('community_write_title_hint'),
                          hintStyle: const TextStyle(
                            color: Colors.black38,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),

                    if (_titleError) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.error,
                            color: Colors.red,
                            size: 15,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            AppLanguage.t('community_write_title_error'),
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      height: 1,
                      color: mainBlue,
                    ),
                    const SizedBox(height: 20),

                    // 내용 라벨
                    Text(
                      AppLanguage.t('community_write_content_label'),
                      style: const TextStyle(
                        color: mainBlue,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // 내용 입력
                    Container(
                      height: 220,
                      decoration: BoxDecoration(
                        color: lightBlue,
                        borderRadius: BorderRadius.circular(14),
                        border: _contentError
                            ? Border.all(color: Colors.red, width: 1.5)
                            : null,
                      ),
                      child: TextField(
                        controller: contentController,
                        enabled: !_isSubmitting,
                        maxLines: null,
                        expands: true,
                        keyboardType: TextInputType.multiline,
                        textAlignVertical: TextAlignVertical.top,
                        style: const TextStyle(fontSize: 15),
                        onChanged: (_) {
                          if (_contentError) {
                            setState(() {
                              _contentError = false;
                            });
                          }
                        },
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(16),
                          hintText:
                          AppLanguage.t('community_write_content_hint'),
                          hintStyle: const TextStyle(
                            color: Colors.black38,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),

                    if (_contentError) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.error,
                            color: Colors.red,
                            size: 15,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            AppLanguage.t('community_write_content_error'),
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      height: 1,
                      color: mainBlue,
                    ),
                    const SizedBox(height: 20),

                    // 사진 첨부 라벨
                    Row(
                      children: [
                        Text(
                          AppLanguage.t('community_write_photo_label'),
                          style: const TextStyle(
                            color: mainBlue,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$_totalImageCount/$maxImageCount',
                          style: const TextStyle(
                            color: Colors.black45,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),

                    if (_isEditMode) ...[
                      const SizedBox(height: 6),
                      Text(
                        AppLanguage.t('community_write_image_replace_notice'),
                        style: const TextStyle(
                          color: Colors.black45,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ],

                    const SizedBox(height: 10),

                    // 이미지 가로 스크롤
                    SizedBox(
                      height: 160,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _buildAddImageCard(),

                          ...List.generate(existingImageUrls.length, (index) {
                            return _buildExistingImageCard(index);
                          }),

                          ...List.generate(selectedImages.length, (index) {
                            return _buildSelectedImageCard(index);
                          }),
                        ],
                      ),
                    ),

                    const SizedBox(height: 36),

                    // 등록/수정 / 취소 버튼
                    Row(
                      children: [
                        Expanded(
                          child: _ActionButton(
                            text: _isSubmitting ? submittingText : submitText,
                            onTap: _isSubmitting ? null : _submitPost,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _ActionButton(
                            text: AppLanguage.t('community_cancel'),
                            onTap: _isSubmitting
                                ? null
                                : () => Navigator.pop(context),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;

  static const Color mainBlue = Color(0xFF2260FF);

  const _ActionButton({
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: mainBlue,
          disabledBackgroundColor: Colors.grey.shade300,
          foregroundColor: Colors.white,
          disabledForegroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}