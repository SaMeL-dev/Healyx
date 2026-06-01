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
  String? _selectedIconId;
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

  void _selectIcon(String iconId) {
    if (_isLoading) return;

    setState(() {
      // 같은 아이콘을 한 번 더 누르면 선택 해제
      if (_selectedIconId == iconId) {
        _selectedIconId = null;
      } else {
        // 다른 아이콘을 누르면 기존 선택을 새 선택으로 교체
        _selectedIconId = iconId;
      }
    });
  }

  Future<void> _goToPainScore() async {
    final selectedIconId = _selectedIconId;

    if (selectedIconId == null || _isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // 아이콘은 1개만 선택하므로 선택된 iconId 하나만 API에 전달
      final symptom = await BodyIconKeywordService.fetchMultipleKeywords(
        iconIds: [selectedIconId],
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
    final selectedIconId = _selectedIconId;

    if (selectedIconId == null) {
      return _localizedSelectIconGuide();
    }

    final label = _localizedIconLabel(selectedIconId);

    switch (AppLanguage.currentLang.value) {
      case 'en':
        return 'You selected the $label-related symptom icon.';
      case 'zh':
        return '您选择了与$label相关的症状图标。';
      case 'ja':
        return '$labelに関連する症状アイコンを選択しました。';
      case 'vi':
        return 'Bạn đã chọn biểu tượng triệu chứng liên quan đến $label.';
      case 'th':
        return 'คุณได้เลือกไอคอนอาการที่เกี่ยวข้องกับ$label';
      case 'ko':
      default:
        return '$label 관련 증상 아이콘을 선택하셨습니다.';
    }
  }

  String _localizedSelectIconGuide() {
    switch (AppLanguage.currentLang.value) {
      case 'en':
        return 'Please select one icon close to your symptom.';
      case 'zh':
        return '请选择一个与症状相近的图标。';
      case 'ja':
        return '症状に近いアイコンを1つ選択してください。';
      case 'vi':
        return 'Vui lòng chọn một biểu tượng gần với triệu chứng của bạn.';
      case 'th':
        return 'โปรดเลือกไอคอนที่ใกล้เคียงกับอาการของคุณ 1 รายการ';
      case 'ko':
      default:
        return '증상과 가까운 아이콘을 하나 선택해주세요.';
    }
  }

  String _localizedIconLabel(String iconId) {
    final langCode = AppLanguage.currentLang.value;

    final labels = <String, Map<String, String>>{
      'headache': {
        'ko': '머리',
        'en': 'head',
        'zh': '头部',
        'ja': '頭',
        'vi': 'đầu',
        'th': 'ศีรษะ',
      },
      'stomachache': {
        'ko': '복부',
        'en': 'stomach',
        'zh': '腹部',
        'ja': 'お腹',
        'vi': 'bụng',
        'th': 'ท้อง',
      },
      'toothache': {
        'ko': '치아',
        'en': 'tooth',
        'zh': '牙齿',
        'ja': '歯',
        'vi': 'răng',
        'th': 'ฟัน',
      },
      'droplet': {
        'ko': '출혈',
        'en': 'bleeding',
        'zh': '出血',
        'ja': '出血',
        'vi': 'chảy máu',
        'th': 'เลือดออก',
      },
      'broken-bone': {
        'ko': '뼈',
        'en': 'bone',
        'zh': '骨骼',
        'ja': '骨',
        'vi': 'xương',
        'th': 'กระดูก',
      },
      'ear': {
        'ko': '귀',
        'en': 'ear',
        'zh': '耳朵',
        'ja': '耳',
        'vi': 'tai',
        'th': 'หู',
      },
      'skin': {
        'ko': '피부',
        'en': 'skin',
        'zh': '皮肤',
        'ja': '皮膚',
        'vi': 'da',
        'th': 'ผิวหนัง',
      },
      'head-side-cough': {
        'ko': '기침',
        'en': 'cough',
        'zh': '咳嗽',
        'ja': '咳',
        'vi': 'ho',
        'th': 'ไอ',
      },
      'visible': {
        'ko': '눈',
        'en': 'eye',
        'zh': '眼部',
        'ja': '目',
        'vi': 'mắt',
        'th': 'ตา',
      },
      'nose': {
        'ko': '코',
        'en': 'nose',
        'zh': '鼻子',
        'ja': '鼻',
        'vi': 'mũi',
        'th': 'จมูก',
      },
      'cold': {
        'ko': '오한/몸살',
        'en': 'chills/body aches',
        'zh': '寒战/全身酸痛',
        'ja': '悪寒・体の痛み',
        'vi': 'ớn lạnh/đau nhức cơ thể',
        'th': 'หนาวสั่น/ปวดเมื่อยตัว',
      },
      'disk': {
        'ko': '허리',
        'en': 'back',
        'zh': '腰部',
        'ja': '腰',
        'vi': 'lưng',
        'th': 'หลัง',
      },
    };

    return labels[iconId]?[langCode] ??
        labels[iconId]?['ko'] ??
        iconId;
  }

  String _localizedNoKeywordMessage() {
    switch (AppLanguage.currentLang.value) {
      case 'en':
        return 'No symptom keyword was found for the selected icon.';
      case 'zh':
        return '未找到所选图标对应的症状关键词。';
      case 'ja':
        return '選択したアイコンに対応する症状キーワードが見つかりません。';
      case 'vi':
        return 'Không tìm thấy từ khóa triệu chứng cho biểu tượng đã chọn.';
      case 'th':
        return 'ไม่พบคำสำคัญของอาการสำหรับไอคอนที่เลือก';
      case 'ko':
      default:
        return '선택한 아이콘에 해당하는 증상 키워드가 없습니다.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isConfirmEnabled = _selectedIconId != null && !_isLoading;

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

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                _buildSelectedIconGuideText(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.black54,
                ),
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
                    final bool isSelected = _selectedIconId == item.iconId;

                    return GestureDetector(
                      onTap: () => _selectIcon(item.iconId),
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
                              color: const Color(0xFF2260FF)
                                  .withAlpha(38),
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