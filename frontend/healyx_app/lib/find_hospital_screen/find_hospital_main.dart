import 'package:flutter/material.dart';
import 'package:healyx_app/app_language.dart';

import 'find_hospital_mic.dart';
import 'find_hospital_text.dart';
import 'find_hospital_icon.dart';

class FindHospitalMain extends StatelessWidget {
  const FindHospitalMain({super.key});

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

            const SizedBox(height: 80),

            _buildHospitalOptionCard(
              icon: Icons.mic,
              title: AppLanguage.t('symptom_input_by_voice'),
              subtitle: AppLanguage.t('symptom_input_by_voice_desc'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const FindHospitalMic(),
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            _buildHospitalOptionCard(
              icon: Icons.keyboard_alt_outlined,
              title: AppLanguage.t('symptom_input_by_text'),
              subtitle: AppLanguage.t('symptom_input_by_text_desc'),
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
              title: AppLanguage.t('symptom_input_by_icon'),
              subtitle: AppLanguage.t('symptom_input_by_icon_desc'),
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