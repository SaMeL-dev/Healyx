// 커뮤니티 글쓰기/수정 화면
// 제목 입력, 내용 입력, 사진 첨부 기능이 있는 화면
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../app_language.dart';
import '../dialogs/image_attach_dialog.dart';
import 'services/community_service.dart';

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

  // 새로 선택한 이미지
  final List<XFile> selectedImages = [];

  // 수정 모드에서 기존 이미지 URL 표시용
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
    titleController.dispose();
    contentController.dispose();
    super.dispose();
  }

  String _tWithCount(String key, int count) {
    return AppLanguage.t(key).replaceAll('{count}', count.toString());
  }

  void _showSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showAttachDialog() {
    if (_totalImageCount >= maxImageCount) {
      _showSnackBar(
        _tWithCount('community_image_max_limit', maxImageCount),
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

      if (_isEditMode) {
        await CommunityService().updatePost(
          postId: widget.postId!,
          title: title,
          content: content,
          images: selectedImages,
        );

        if (!mounted) return;

        _showSnackBar(AppLanguage.t('community_post_updated'));
      } else {
        await CommunityService().createPost(
          title: title,
          content: content,
          images: selectedImages,
        );

        if (!mounted) return;

        _showSnackBar(AppLanguage.t('community_post_created'));
      }

      // true를 넘겨주면 이전 화면에서 새로고침 가능
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      _showSnackBar(
        e.toString().replaceFirst('Exception: ', ''),
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