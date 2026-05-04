//댓글 삭제 확인 팝업
// 댓글을 정말로 삭제하시겠습니까? 삭제 후에는 복구할 수 없습니다. 예/아니오 버튼
import 'package:flutter/material.dart';

class CommentDeleteDialog extends StatelessWidget {
  const CommentDeleteDialog({super.key});

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF2260FF);
    const Color white = Color(0xFFFFFFFF);
    const Color lightPurple = Color(0xFFCAD6FF);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 34, 24, 28),
        decoration: BoxDecoration(
          color: white,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '댓글을 삭제할까요?\n삭제 후에는 복구할 수 없습니다.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: primaryBlue,
              ),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBlue,
                      foregroundColor: Colors.white, // 👈 추가
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    child: const Text(
                      '예',
                      style: TextStyle(color: Colors.white), // 👈 추가
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: lightPurple,
                      foregroundColor: primaryBlue,
                    ),
                    child: const Text('아니오'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}