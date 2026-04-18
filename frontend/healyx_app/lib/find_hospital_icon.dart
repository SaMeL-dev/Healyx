import 'package:flutter/material.dart';
import 'pain_score_slide.dart';

class FindHospitalIcon extends StatelessWidget {
  const FindHospitalIcon({super.key});

  void _goToPainScore(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PainScoreSlide(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<String> symptomIconPaths = [
      'assets/images/find_hospital/headache.png',
      'assets/images/find_hospital/stomachache.png',
      'assets/images/find_hospital/toothache.png',
      'assets/images/find_hospital/droplet.png',
      'assets/images/find_hospital/broken-bone.png',
      'assets/images/find_hospital/ear.png',
      'assets/images/find_hospital/skin.png',
      'assets/images/find_hospital/head-side-cough.png',
      'assets/images/find_hospital/visible.png',
      'assets/images/find_hospital/nose.png',
      'assets/images/find_hospital/cold.png',
      'assets/images/find_hospital/disk.png',
    ];

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
                  const Expanded(
                    child: Center(
                      child: Text(
                        '병원 찾기',
                        style: TextStyle(
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
            const Text(
              '귀하의 증상과 가까운 아이콘을 선택하세요',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2260FF),
              ),
            ),
            const SizedBox(height: 42),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: symptomIconPaths.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 20,
                    crossAxisSpacing: 20,
                    childAspectRatio: 1,
                  ),
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () => _goToPainScore(context),
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8ECF8),
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Image.asset(
                            symptomIconPaths[index],
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}