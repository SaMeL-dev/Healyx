import 'dart:io';
import 'package:flutter/material.dart';
import '../../../dialogs/login_required_dialog.dart';
import '../common/common_toast.dart';

class TranslationResultScreen extends StatelessWidget {
  final String originalImagePath;
  final String translatedImagePath;

  const TranslationResultScreen({
    super.key,
    required this.originalImagePath,
    required this.translatedImagePath,
  });

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF2260FF);
    const Color bgColor = Color(0xFFFFFFFF);
    const Color cardColor = Color(0xFFECEFFF);
    const Color titleColor = Color(0xFF667AB6);
    const Color grayText = Color(0xFF605E5E);
    const Color buttonBlue = Color(0xFF2260FF);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 16),

                Stack(
                  alignment: Alignment.center,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        onPressed: () {
                          if (Navigator.canPop(context)) {
                            Navigator.pop(context);
                          }
                        },
                        icon: const Icon(
                          Icons.arrow_back_ios_new,
                          color: primaryBlue,
                          size: 24,
                        ),
                      ),
                    ),
                    const Text(
                      '의료번역',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: primaryBlue,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 122,
                      height: 172,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: const Color(0xFFBDBDBD)),
                      ),
                      child: ClipRRect(
                        child: Image.file(
                          File(originalImagePath),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
                              child: Icon(
                                Icons.image_outlined,
                                size: 40,
                                color: Color(0xFF767676),
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                    const SizedBox(width: 28),

                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '원본 이미지',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF757D95),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF8C9AF0),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '번역 완료',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Icon(
                                    Icons.check,
                                    color: Color(0xFF304476),
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x22000000),
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        '번역 이미지',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: titleColor,
                        ),
                      ),
                      const SizedBox(height: 24),

                      Container(
                        width: double.infinity,
                        height: 320,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: const Color(0xFFBDBDBD)),
                        ),
                        child: ClipRRect(
                          child: Image.file(
                            File(translatedImagePath),
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                alignment: Alignment.center,
                                color: Colors.white,
                                child: const Text(
                                  '번역 이미지가 표시될 영역',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: grayText,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      SizedBox(
                        width: 150,
                        height: 45,
                        child: ElevatedButton(
                          onPressed: () {
                            bool isLoggedIn = true; // 퍼블리싱 단계용 임시값

                            if (isLoggedIn) {
                              CommonToast.show(
                                context,
                                message: '보관함에 저장되었습니다.',
                              );
                            } else {
                              showDialog(
                                context: context,
                                barrierColor: const Color(0x802260FF),
                                builder: (context) =>
                                    const LoginRequiredDialog(),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: buttonBlue,
                            foregroundColor: Colors.white,
                            elevation: 6,
                            shadowColor: const Color(0x33000000),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(31),
                            ),
                          ),
                          child: const Text(
                            '저장하기',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
