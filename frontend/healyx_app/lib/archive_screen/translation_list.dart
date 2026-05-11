// 번역 보관함 리스트 화면
// API에서 번역 보관함 목록을 불러와 카드 형태로 표시
// 각 항목은 탭 시 상세 화면으로 이동, 삭제 버튼으로 항목 삭제 가능

import 'package:flutter/material.dart';
import 'package:healyx_app/dialogs/archive_delete_dialog.dart';
import '../app_language.dart';
import '../services/translation_service.dart';
import 'translation_detail.dart';

class TranslationListScreen extends StatefulWidget {
  const TranslationListScreen({super.key});

  @override
  State<TranslationListScreen> createState() => _TranslationListScreenState();
}

class _TranslationListScreenState extends State<TranslationListScreen> {
  List<TranslationArchiveItem> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadArchive();
  }

  // 보관함 목록 API 호출
  Future<void> _loadArchive() async {
    setState(() => _isLoading = true);
    final items = await TranslationService.getArchive();
    if (!mounted) return;
    setState(() {
      _items = items;
      _isLoading = false;
    });
  }

  // 항목 삭제 — 다이얼로그 확인 후 API 호출
  Future<void> _deleteItem(TranslationArchiveItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: const Color(0xFF2260FF).withValues(alpha: 0.4),
      builder: (ctx) => const ArchiveDeleteDialog(),
    );

    if (confirmed != true || !mounted) return;

    final success = await TranslationService.deleteArchiveItem(item.id);
    if (!mounted) return;

    if (success) {
      setState(() => _items.removeWhere((e) => e.id == item.id));
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
          AppLanguage.t('archive_menu_translation'), // '의료 번역 보관함'
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
            const Icon(Icons.image_search, size: 56, color: Color(0xFFBBBBBB)),
            const SizedBox(height: 16),
            Text(
              AppLanguage.t('archive_empty_translation'), // '저장된 번역이 없습니다.'
              style: const TextStyle(fontSize: 15, color: Color(0xFF9E9E9E)),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: _items.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = _items[index];
        return _TranslationCard(
          item: item,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TranslationDetailScreen(item: item),
              ),
            );
          },
          onDelete: () => _deleteItem(item),
        );
      },
    );
  }
}

class _TranslationCard extends StatelessWidget {
  final TranslationArchiveItem item;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _TranslationCard({
    required this.item,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE8E8E8)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // 번역 이미지 썸네일
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
              child: SizedBox(
                width: 90,
                height: 80,
                child: item.translatedImageUrl.isNotEmpty
                    ? Image.network(
                        item.translatedImageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const _ThumbnailPlaceholder(),
                      )
                    : const _ThumbnailPlaceholder(),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.formattedDate,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2260FF),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.languageName,
                    style: const TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.black38, size: 20),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

class _ThumbnailPlaceholder extends StatelessWidget {
  const _ThumbnailPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFEEEEEE),
      child: const Icon(Icons.image_outlined, color: Color(0xFFBBBBBB), size: 32),
    );
  }
}