import 'package:flutter/material.dart';
import 'package:healyx_app/app_language.dart';

import 'pain_score_slide.dart';

class FindHospitalText extends StatefulWidget {
  const FindHospitalText({super.key});

  @override
  State<FindHospitalText> createState() => _FindHospitalTextState();
}

class _FindHospitalTextState extends State<FindHospitalText> {
  final TextEditingController _symptomController = TextEditingController();

  @override
  void initState() {
    super.initState();

    _symptomController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _symptomController.dispose();
    super.dispose();
  }

  void _goToPainScoreSlide() {
    final symptom = _symptomController.text.trim();

    if (symptom.isEmpty) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PainScoreSlide(
          symptom: symptom,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isConfirmEnabled = _symptomController.text.trim().isNotEmpty;
    final double keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final bool isKeyboardOpen = keyboardInset > 0;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFFF3F4F8),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.only(
                bottom: isKeyboardOpen ? keyboardInset + 24 : 0,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
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

                    SizedBox(height: isKeyboardOpen ? 45 : 90),

                    Text(
                      AppLanguage.t('symptom_text_prompt'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2260FF),
                      ),
                    ),

                    const SizedBox(height: 18),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 30),
                      child: Container(
                        width: double.infinity,
                        height: isKeyboardOpen ? 280 : 365,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8ECF8),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: TextField(
                          controller: _symptomController,
                          maxLines: null,
                          expands: true,
                          textAlignVertical: TextAlignVertical.top,
                          decoration: InputDecoration(
                            hintText: AppLanguage.t('symptom_text_hint'),
                            hintStyle: const TextStyle(
                              color: Colors.black38,
                              fontSize: 16,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.all(20),
                          ),
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black87,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: isKeyboardOpen ? 34 : 72),

                    Padding(
                      padding: EdgeInsets.only(
                        bottom: isKeyboardOpen ? 12 : 80,
                      ),
                      child: SizedBox(
                        width: 118,
                        height: 48,
                        child: ElevatedButton(
                          onPressed:
                          isConfirmEnabled ? _goToPainScoreSlide : null,
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
                          child: Text(
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
          },
        ),
      ),
    );
  }
}