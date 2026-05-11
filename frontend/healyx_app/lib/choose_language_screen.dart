import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_language.dart';
import 'main_screen.dart';

class ChooseLanguageScreen extends StatefulWidget {
  const ChooseLanguageScreen({super.key});

  @override
  State<ChooseLanguageScreen> createState() => _ChooseLanguageScreenState();
}

class _ChooseLanguageScreenState extends State<ChooseLanguageScreen> {
  int selectedIndex = 0;

  final List<Map<String, String>> languages = [
    {'flag': '🇰🇷', 'title': '한국어', 'code': 'ko'},
    {'flag': '🇺🇸', 'title': 'English', 'code': 'en'},
    {'flag': '🇨🇳', 'title': '中文', 'code': 'zh'},
    {'flag': '🇯🇵', 'title': '日本語', 'code': 'ja'},
    {'flag': '🇻🇳', 'title': 'Tiếng Việt', 'code': 'vi'},
    {'flag': '🇹🇭', 'title': 'ไทย', 'code': 'th'},
  ];

  Future<void> onSelectLanguage() async {
    final code = languages[selectedIndex]['code'] ?? 'ko';

    // 선택한 언어 코드를 SharedPreferences에 저장
    // final prefs = await SharedPreferences.getInstance(); // → app_language.dart의 AppLanguage.setLang()에서 공통 처리
    // await prefs.setString('language_pref', code);       // → app_language.dart의 AppLanguage.setLang()에서 공통 처리
    
    // 언어 저장 + 전역 언어 상태 업데이트
    await AppLanguage.setLang(code); // 추가 

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const MainScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              width: 300,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF3FF),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    AppLanguage.t('language_select_title'), // '언어 선택'
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF7B8FD9),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Language',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF9AA8D6),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 22),

                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: languages.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 10,
                      childAspectRatio: 0.78, // 카드 높이를 더 확보
                    ),
                    itemBuilder: (context, index) {
                      final item = languages[index];
                      final isSelected = selectedIndex == index;

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedIndex = index;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFFDDE7FF)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF5D86FF)
                                  : Colors.transparent,
                              width: 1.6,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 5,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                item['flag'] ?? '',
                                style: const TextStyle(fontSize: 24),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                item['title'] ?? '',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                item['subtitle'] ?? '',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 9,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 22),

                  SizedBox(
                    width: 110,
                    height: 42,
                    child: ElevatedButton(
                      onPressed: onSelectLanguage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5D86FF),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22),
                        ),
                      ),
                      child: Text(
                        AppLanguage.t('language_select_btn'), // '선택'
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
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
  }
}