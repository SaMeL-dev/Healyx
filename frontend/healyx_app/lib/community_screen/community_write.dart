// 커뮤니티 글쓰기 화면
// 제목 입력, 내용 입력, 사진 첨부 기능이 있는 화면
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../dialogs/image_attach_dialog.dart';
import '../dialogs/delete_confirm_dialog.dart';
import 'community_detail.dart';

class CommunityWriteScreen extends StatefulWidget {
  const CommunityWriteScreen({super.key});

  @override
  State<CommunityWriteScreen> createState() => _CommunityWriteScreenState();
}

class _CommunityWriteScreenState extends State<CommunityWriteScreen> {
  static const Color mainBlue = Color(0xFF2260FF);
  static const Color lightBlue = Color(0xFFEFF2FF);

  final TextEditingController titleController = TextEditingController();
  final TextEditingController contentController = TextEditingController();

  final ImagePicker picker = ImagePicker();
  final List<XFile> selectedImages = [];

  bool _titleError = false;

  @override
  void dispose() {
    titleController.dispose();
    contentController.dispose();
    super.dispose();
  }

  void _showAttachDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black45,
      builder: (_) => ImageAttachDialog(
        onSelect: (source) async {
          if (source == ImageSource.camera) {
            final XFile? image = await picker.pickImage(
              source: ImageSource.camera,
              imageQuality: 85,
            );
            if (image == null || !mounted) return;
            setState(() => selectedImages.add(image));
          } else {
            final List<XFile> images = await picker.pickMultiImage(
              imageQuality: 85,
              limit: 30,
            );
            if (images.isEmpty || !mounted) return;
            final int remain = 30 - selectedImages.length;
            setState(() => selectedImages.addAll(images.take(remain)));
          }
        },
      ),
    );
  }

  void _removeImage(int index) {
    setState(() => selectedImages.removeAt(index));
  }

  void _submitPost() {
    if (titleController.text.trim().isEmpty) {
      setState(() => _titleError = true);
      return;
    }
    // TODO: 커뮤니티 글 등록 API 연결
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CommunityDetailScreen(isMyPost: true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_ios,
                          color: mainBlue, size: 20),
                    ),
                  ),
                ),
                const Text(
                  '커뮤니티',
                  style: TextStyle(
                    color: mainBlue,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // 스크롤 영역
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 제목 라벨
                    const Text(
                      '제목',
                      style: TextStyle(
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
                        style: const TextStyle(fontSize: 15),
                        onChanged: (_) {
                          if (_titleError) setState(() => _titleError = false);
                        },
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: '제목을 입력하세요',
                          hintStyle:
                              TextStyle(color: Colors.black38, fontSize: 15),
                        ),
                      ),
                    ),

                    // 에러 메시지
                    if (_titleError) ...[
                      const SizedBox(height: 6),
                      const Row(
                        children: [
                          Icon(Icons.error, color: Colors.red, size: 15),
                          SizedBox(width: 4),
                          Text(
                            '제목을 입력해주세요.',
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 20),
                    Container(width: double.infinity, height: 1, color: mainBlue),
                    const SizedBox(height: 20),

                    // 내용 라벨
                    const Text(
                      '내용을 작성해주세요',
                      style: TextStyle(
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
                      ),
                      child: TextField(
                        controller: contentController,
                        maxLines: null,
                        expands: true,
                        keyboardType: TextInputType.multiline,
                        textAlignVertical: TextAlignVertical.top,
                        style: const TextStyle(fontSize: 15),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.all(16),
                          hintText: '내용을 입력하세요',
                          hintStyle:
                              TextStyle(color: Colors.black38, fontSize: 15),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                    Container(width: double.infinity, height: 1, color: mainBlue),
                    const SizedBox(height: 20),

                    // 사진 첨부 라벨
                    Row(
                      children: [
                        const Text(
                          '사진 첨부',
                          style: TextStyle(
                            color: mainBlue,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${selectedImages.length}/30',
                          style: const TextStyle(
                            color: Colors.black45,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // 이미지 가로 스크롤
                    SizedBox(
                      height: 160,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          if (selectedImages.length < 30)
                            GestureDetector(
                              onTap: _showAttachDialog,
                              child: Container(
                                width: 112,
                                height: 160,
                                margin: const EdgeInsets.only(right: 10),
                                decoration: BoxDecoration(
                                  color: lightBlue,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Center(
                                  child: Icon(Icons.add,
                                      color: mainBlue, size: 34),
                                ),
                              ),
                            ),

                          ...List.generate(selectedImages.length, (index) {
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
                                          File(selectedImages[index].path)),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 6,
                                  right: 18,
                                  child: GestureDetector(
                                    onTap: () => _removeImage(index),
                                    child: Container(
                                      width: 24,
                                      height: 24,
                                      decoration: const BoxDecoration(
                                        color: mainBlue,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.close,
                                          color: Colors.white, size: 16),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }),
                        ],
                      ),
                    ),

                    const SizedBox(height: 36),

                    // 등록 / 취소 버튼
                    Row(
                      children: [
                        Expanded(
                          child: _ActionButton(
                            text: '등록',
                            onTap: _submitPost,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _ActionButton(
                            text: '취소',
                            onTap: () => Navigator.pop(context),
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
  final VoidCallback onTap;

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
          foregroundColor: Colors.white,
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