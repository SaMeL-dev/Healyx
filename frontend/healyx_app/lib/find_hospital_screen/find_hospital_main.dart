import 'package:flutter/material.dart';
import 'package:healyx_app/app_language.dart'; 
import 'find_hospital_mic.dart';
import 'find_hospital_text.dart';
import 'find_hospital_icon.dart';

class FindHospitalMain extends StatelessWidget {
  const FindHospitalMain({super.key});

  void _showMicPermissionDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: const Color(0x804E7CFF),
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 36),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding( 
                  padding: const EdgeInsets.fromLTRB(24, 48, 24, 28),
                  child: Text(
                    AppLanguage.t('mic_permission_request'), // 'HEALYX에서 마이크에\n접근할 수 있도록\n허용하시겠습니까?'
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      height: 1.45,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2260FF),
                    ),
                  ),
                ),
                Container(
                  height: 1,
                  color: const Color(0xFF2260FF),
                ),
                SizedBox(
                  height: 84,
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(28),
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const FindHospitalMic(),
                              ),
                            );
                          },
                          child: Center( 
                            child: Text(
                              AppLanguage.t('allow'), // '허용'
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF2260FF),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Container(
                        width: 1,
                        color: const Color(0xFF2260FF),
                      ),
                      Expanded(
                        child: InkWell(
                          borderRadius: const BorderRadius.only(
                            bottomRight: Radius.circular(28),
                          ),
                          onTap: () {
                            Navigator.pop(context);
                          },
                          child: Center( 
                            child: Text(
                              AppLanguage.t('deny'), // '거부'
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF2260FF),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHospitalOptionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          height: 138,
          decoration: BoxDecoration(
            color: const Color(0xFFDCE4FF),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: [
              const SizedBox(width: 22),
              Container(
                width: 88,
                height: 88,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 48,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2260FF),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                        AppLanguage.t('find_hospital'), // '병원 찾기'
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
            const SizedBox(height: 80),
            _buildHospitalOptionCard(
              icon: Icons.mic,
              title: AppLanguage.t('symptom_input_by_voice'), // '음성으로 증상 입력하기'
              subtitle: AppLanguage.t('symptom_input_by_voice_desc'), // '자국어로 편하게 말씀하세요'
              onTap: () {
                _showMicPermissionDialog(context);
              },
            ),
            const SizedBox(height: 24),
            _buildHospitalOptionCard(
              icon: Icons.keyboard_alt_outlined,
              title: AppLanguage.t('symptom_input_by_text'), // '텍스트로 증상 입력하기'
              subtitle: AppLanguage.t('symptom_input_by_text_desc'), // '자국어로 편하게 쓰세요'
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const FindHospitalText(),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            _buildHospitalOptionCard(
              icon: Icons.check,
              title: AppLanguage.t('symptom_input_by_icon'), // '증상 아이콘 선택하기'
              subtitle: AppLanguage.t('symptom_input_by_icon_desc'), // '간편하게 아이콘을 선택하세요'
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const FindHospitalIcon(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
