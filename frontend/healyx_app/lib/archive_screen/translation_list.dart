import 'package:flutter/material.dart';
import 'package:healyx_app/dialogs/archive_delete_dialog.dart';
import 'translation_detail.dart';

class TranslationItem {
  final String id;
  final String date;
  final String language;
  final bool isHorizontal;

  const TranslationItem({
    required this.id,
    required this.date,
    required this.language,
    this.isHorizontal = false,
  });
}

class TranslationListScreen extends StatefulWidget {
  const TranslationListScreen({super.key});

  @override
  State<TranslationListScreen> createState() => _TranslationListScreenState();
}

class _TranslationListScreenState extends State<TranslationListScreen> {
  final List<TranslationItem> _items = [
    TranslationItem(id: '1', date: '2026-04-01', language: '중국어', isHorizontal: false),
    TranslationItem(id: '2', date: '2026-03-31', language: '중국어', isHorizontal: true),
    TranslationItem(id: '3', date: '2026-03-30', language: '중국어', isHorizontal: false),
    TranslationItem(id: '4', date: '2026-03-24', language: '중국어', isHorizontal: false),
    TranslationItem(id: '5', date: '2026-03-20', language: '중국어', isHorizontal: true),
    TranslationItem(id: '6', date: '2026-03-11', language: '중국어', isHorizontal: false),
    TranslationItem(id: '7', date: '2026-03-02', language: '중국어', isHorizontal: false),
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
          '의료 번역 보관함',
          style: TextStyle(
            color: Color(0xFF2260FF),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: _items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
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

class _TranslationCard extends StatelessWidget {
  final TranslationItem item;
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
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 90,
              height: 80,
              decoration: const BoxDecoration(
                color: Color(0xFFEEEEEE),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
              child: const Icon(Icons.image_outlined, color: Color(0xFFBBBBBB), size: 32),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.date,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2260FF),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.language,
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