//게시물 삭제 확인 팝업
//정말로 삭제하시겠습니까? 예/아니오 버튼
import 'package:flutter/material.dart';
import 'package:healyx_app/app_language.dart'; 

class ArchiveDeleteDialog extends StatelessWidget {
  const ArchiveDeleteDialog({super.key});

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
            Text(
              AppLanguage.t('dialog_delete_confirm'), // '정말로 삭제하시겠습니까?' 
              textAlign: TextAlign.center,
              style: const TextStyle(
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
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    child: Text(
                      AppLanguage.t('yes'), // '예' 
                      style: const TextStyle(color: Colors.white),
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
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    child: Text(AppLanguage.t('no')), // '아니요' 
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