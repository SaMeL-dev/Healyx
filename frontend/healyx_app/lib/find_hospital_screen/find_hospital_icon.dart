import 'package:flutter/material.dart';
import 'package:healyx_app/app_language.dart';

import 'pain_score_slide.dart';
import 'service/body_icon_keyword_service.dart';

class FindHospitalIcon extends StatefulWidget {
  const FindHospitalIcon({super.key});

  @override
  State<FindHospitalIcon> createState() => _FindHospitalIconState();
}

class _FindHospitalIconState extends State<FindHospitalIcon> {
  final Set<String> _selectedIconIds = {};
  bool _isLoading = false;

  final List<_SymptomIconItem> _symptomIcons = const [
    _SymptomIconItem(
      iconId: 'headache',
      imagePath: 'assets/images/find_hospital/headache.png',
    ),
    _SymptomIconItem(
      iconId: 'stomachache',
      imagePath: 'assets/images/find_hospital/stomachache.png',
    ),
    _SymptomIconItem(
      iconId: 'toothache',
      imagePath: 'assets/images/find_hospital/toothache.png',
    ),
    _SymptomIconItem(
      iconId: 'droplet',
      imagePath: 'assets/images/find_hospital/droplet.png',
    ),
    _SymptomIconItem(
      iconId: 'broken-bone',
      imagePath: 'assets/images/find_hospital/broken-bone.png',
    ),
    _SymptomIconItem(
      iconId: 'ear',
      imagePath: 'assets/images/find_hospital/ear.png',
    ),
    _SymptomIconItem(
      iconId: 'skin',
      imagePath: 'assets/images/find_hospital/skin.png',
    ),
    _SymptomIconItem(
      iconId: 'head-side-cough',
      imagePath: 'assets/images/find_hospital/head-side-cough.png',
    ),
    _SymptomIconItem(
      iconId: 'visible',
      imagePath: 'assets/images/find_hospital/visible.png',
    ),
    _SymptomIconItem(
      iconId: 'nose',
      imagePath: 'assets/images/find_hospital/nose.png',
    ),
    _SymptomIconItem(
      iconId: 'cold',
      imagePath: 'assets/images/find_hospital/cold.png',
    ),
    _SymptomIconItem(
      iconId: 'disk',
      imagePath: 'assets/images/find_hospital/disk.png',
    ),
  ];

  void _toggleIcon(String iconId) {
    if (_isLoading) return;

    setState(() {
      if (_selectedIconIds.contains(iconId)) {
        _selectedIconIds.remove(iconId);
      } else {
        _selectedIconIds.add(iconId);
      }
    });
  }

  Future<void> _goToPainScore() async {
    if (_selectedIconIds.isEmpty || _isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final selectedIconIds = _symptomIcons
          .where((item) => _selectedIconIds.contains(item.iconId))
          .map((item) => item.iconId)
          .toList();

      final symptom = await BodyIconKeywordService.fetchMultipleKeywords(
        iconIds: selectedIconIds,
      );

      if (!mounted) return;

      if (symptom.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_localizedNoKeywordMessage()),
          ),
        );
        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PainScoreSlide(
            symptom: symptom,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _buildSelectedIconGuideText() {
    final int count = _selectedIconIds.length;
    final String langCode = AppLanguage.currentLang.value;

    if (count == 0) {
      switch (langCode) {
        case 'en':
          return 'Please select at least one icon close to your symptom.';
        case 'zh':
          return '请选择至少一个与症状相近的图标。';
        case 'ja':
          return '症状に近いアイコンを1つ以上選択してください。';
        case 'vi':
          return 'Vui lòng chọn ít nhất một biểu tượng gần với triệu chứng của bạn.';
        case 'th':
          return 'โปรดเลือกไอคอนที่ใกล้เคียงกับอาการอย่างน้อย 1 รายการ';
        case 'ko':
        default:
          return '증상과 가까운 아이콘을 하나 이상 선택해주세요.';
      }
    }

    switch (langCode) {
      case 'en':
        return count == 1 ? '1 icon selected.' : '$count icons selected.';
      case 'zh':
        return '已选择 $count 个图标。';
      case 'ja':
        return '$count個のアイコンが選択されました。';
      case 'vi':
        return 'Đã chọn $count biểu tượng.';
      case 'th':
        return 'เลือกไอคอนแล้ว $count รายการ';
      case 'ko':
      default:
        return '$count개의 아이콘이 선택되었습니다.';
    }
  }

  String _localizedNoKeywordMessage() {
    switch (AppLanguage.currentLang.value) {
      case 'en':
        return 'No symptom keywords were found for the selected icons.';
      case 'zh':
        return '未找到所选图标对应的症状关键词。';
      case 'ja':
        return '選択したアイコンに対応する症状キーワードが見つかりません。';
      case 'vi':
        return 'Không tìm thấy từ khóa triệu chứng cho các biểu tượng đã chọn.';
      case 'th':
        return 'ไม่พบคำสำคัญของอาการสำหรับไอคอนที่เลือก';
      case 'ko':
      default:
        return '선택한 아이콘에 해당하는 증상 키워드가 없습니다.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isConfirmEnabled = _selectedIconIds.isNotEmpty && !_isLoading;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F8),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: const Icon(
                      Icons.arrow_back_ios_new,
                      color: Color(0xFF2260FF),
                      size: 22,
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        AppLanguage.t('find_hospital'),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF2260FF),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            const SizedBox(height: 70),

            Text(
              AppLanguage.t('symptom_icon_prompt'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2260FF),
              ),
            ),

            const SizedBox(height: 10),

            Text(
              _buildSelectedIconGuideText(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.black54,
              ),
            ),

            const SizedBox(height: 30),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: GridView.builder(
                  itemCount: _symptomIcons.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 18,
                    crossAxisSpacing: 18,
                    childAspectRatio: 1,
                  ),
                  itemBuilder: (context, index) {
                    final item = _symptomIcons[index];
                    final bool isSelected =
                    _selectedIconIds.contains(item.iconId);

                    return GestureDetector(
                      onTap: () => _toggleIcon(item.iconId),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        curve: Curves.easeOut,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8ECF8),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF2260FF)
                                : Colors.transparent,
                            width: 2.2,
                          ),
                          boxShadow: isSelected
                              ? [
                            BoxShadow(
                              color:
                              const Color(0xFF2260FF).withAlpha(38),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ]
                              : [],
                        ),
                        child: Stack(
                          children: [
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.all(18),
                                child: Image.asset(
                                  item.imagePath,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                            if (isSelected)
                              Positioned(
                                right: 7,
                                top: 7,
                                child: Container(
                                  width: 22,
                                  height: 22,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF2260FF),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 15,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 34),
              child: SizedBox(
                width: 118,
                height: 48,
                child: ElevatedButton(
                  onPressed: isConfirmEnabled ? _goToPainScore : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2260FF),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFFBFCBEE),
                    disabledForegroundColor: Colors.white70,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: Colors.white,
                    ),
                  )
                      : Text(
                    AppLanguage.t('confirm'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SymptomIconItem {
  final String iconId;
  final String imagePath;

  const _SymptomIconItem({
    required this.iconId,
    required this.imagePath,
  });
}