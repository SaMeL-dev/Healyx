import 'package:flutter/material.dart';
import 'package:healyx_app/app_language.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import 'pain_score_slide.dart';

class FindHospitalMic extends StatefulWidget {
  const FindHospitalMic({super.key});

  @override
  State<FindHospitalMic> createState() => _FindHospitalMicState();
}

class _FindHospitalMicState extends State<FindHospitalMic> {
  final stt.SpeechToText _speech = stt.SpeechToText();

  bool _speechAvailable = false;
  bool _isListening = false;
  bool _isInitializing = true;

  String _recognizedText = '';
  String _statusMessage = '';

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    try {
      final available = await _speech.initialize(
        onStatus: _onSpeechStatus,
        onError: _onSpeechError,
      );

      if (!mounted) return;

      setState(() {
        _speechAvailable = available;
        _isInitializing = false;
        _statusMessage = available
            ? AppLanguage.t('mic_click_to_start')
            : '음성 인식을 사용할 수 없습니다.';
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _speechAvailable = false;
        _isInitializing = false;
        _statusMessage = '음성 인식 초기화 중 오류가 발생했습니다.';
      });
    }
  }

  void _onSpeechStatus(String status) {
    if (!mounted) return;

    if (status == 'done' || status == 'notListening') {
      setState(() {
        _isListening = false;
        _statusMessage = AppLanguage.t('mic_click_to_start');
      });
    }
  }

  void _onSpeechError(SpeechRecognitionError error) {
    if (!mounted) return;

    setState(() {
      _isListening = false;
      _statusMessage = '음성 인식 중 오류가 발생했습니다.';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('음성 인식 오류: ${error.errorMsg}'),
      ),
    );
  }

  Future<void> _toggleMic() async {
    if (_isInitializing) return;

    if (!_speechAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('음성 인식을 사용할 수 없습니다. 마이크 권한을 확인해주세요.'),
        ),
      );
      return;
    }

    if (_isListening) {
      await _stopListening();
    } else {
      await _startListening();
    }
  }

  Future<void> _startListening() async {
    setState(() {
      _isListening = true;
      _recognizedText = '';
      _statusMessage = AppLanguage.t('mic_listening');
    });

    await _speech.listen(
      localeId: _getSpeechLocaleId(),
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 4),
      listenOptions: stt.SpeechListenOptions(
        partialResults: true,
        cancelOnError: true,
        listenMode: stt.ListenMode.confirmation,
      ),
      onResult: (result) {
        if (!mounted) return;

        setState(() {
          _recognizedText = result.recognizedWords.trim();
        });
      },
    );
  }

  Future<void> _stopListening() async {
    await _speech.stop();

    if (!mounted) return;

    setState(() {
      _isListening = false;
      _statusMessage = AppLanguage.t('mic_click_to_start');
    });
  }

  String _getSpeechLocaleId() {
    switch (AppLanguage.currentLang.value) {
      case 'en':
        return 'en_US';
      case 'ja':
        return 'ja_JP';
      case 'zh':
        return 'zh_CN';
      case 'vi':
        return 'vi_VN';
      case 'th':
        return 'th_TH';
      case 'ko':
      default:
        return 'ko_KR';
    }
  }

  void _goToPainScoreSlide() {
    final symptom = _recognizedText.trim();

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
  void dispose() {
    _speech.stop();
    super.dispose();
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
              AppLanguage.t('symptom_mic_prompt'),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2260FF),
              ),
            ),

            const SizedBox(height: 14),

            if (_isInitializing) ...[
              const Text(
                '음성 인식을 준비하고 있습니다.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ] else if (_isListening) ...[
              Text(
                AppLanguage.t('mic_listening'),
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                AppLanguage.t('mic_listening_hint'),
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ] else ...[
              Text(
                _statusMessage.isNotEmpty
                    ? _statusMessage
                    : AppLanguage.t('mic_click_to_start'),
                style: const TextStyle(
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
                  color: _isListening
                      ? const Color(0xFFCAD6FF)
                      : const Color(0xFFDCE4FF),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(46),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  _isListening ? Icons.mic : Icons.mic_none,
                  size: 62,
                  color: _isListening
                      ? const Color(0xFF2260FF)
                      : Colors.grey,
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
              child: SingleChildScrollView(
                child: Text(
                  _recognizedText.isNotEmpty
                      ? _recognizedText
                      : '인식된 음성이 여기에 표시됩니다.',
                  style: TextStyle(
                    fontSize: 16,
                    color: _recognizedText.isNotEmpty
                        ? Colors.black87
                        : Colors.black38,
                    height: 1.5,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 38),

            SizedBox(
              width: 118,
              height: 48,
              child: ElevatedButton(
                onPressed: isConfirmEnabled ? _goToPainScoreSlide : null,
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
          ],
        ),
      ),
    );
  }
}