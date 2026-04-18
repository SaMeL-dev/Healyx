import 'package:flutter/material.dart';
import 'pain_score_slide.dart';

class FindHospitalMic extends StatefulWidget {
  const FindHospitalMic({super.key});

  @override
  State<FindHospitalMic> createState() => _FindHospitalMicState();
}

class _FindHospitalMicState extends State<FindHospitalMic> {
  bool _isListening = false;
  String _recognizedText = '';

  void _toggleMic() {
    setState(() {
      if (!_isListening) {
        _isListening = true;
        _recognizedText = '';
      } else {
        _isListening = false;
        _recognizedText = '예시) 머리가 아프고 열이 나는 것 같아요.';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isConfirmEnabled = _recognizedText.trim().isNotEmpty;

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
            const SizedBox(height: 70),
            const Text(
              '귀하의 증상을 말씀해주세요',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2260FF),
              ),
            ),
            const SizedBox(height: 14),
            if (_isListening) ...[
              const Text(
                '음성을 듣고 있습니다',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                '입력을 마치려면 마이크를 다시 클릭하세요',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ] else ...[
              const Text(
                '마이크를 클릭하면 입력이 시작됩니다',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            const SizedBox(height: 26),
            GestureDetector(
              onTap: _toggleMic,
              child: Container(
                width: 134,
                height: 134,
                decoration: BoxDecoration(
                  color: const Color(0xFFDCE4FF),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.18),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  _isListening ? Icons.mic : Icons.mic_none,
                  size: 62,
                  color: Colors.grey,
                ),
              ),
            ),
            const SizedBox(height: 42),
            Container(
              width: 320,
              height: 210,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFE8ECF8),
                borderRadius: BorderRadius.circular(24),
              ),
              alignment: Alignment.topLeft,
              child: Text(
                _recognizedText,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 38),
            SizedBox(
              width: 118,
              height: 48,
              child: ElevatedButton(
                onPressed: isConfirmEnabled
                    ? () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PainScoreSlide(),
                    ),
                  );
                }
                    : null,
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
                child: const Text(
                  '확인',
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
    );
  }
}