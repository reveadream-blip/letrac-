import 'package:flutter_tts/flutter_tts.dart';

class VoiceService {
  VoiceService._internal();

  static final VoiceService instance = VoiceService._internal();
  final FlutterTts _tts = FlutterTts();
  bool _isReady = false;

  Future<void> init() async {
    if (_isReady) return;
    await _tts.setLanguage('fr-FR');
    await _tts.setSpeechRate(0.45);
    await _tts.setPitch(1.1);
    _isReady = true;
  }

  Future<void> speak(String text) async {
    await init();
    await _tts.stop();
    await _tts.speak(text);
  }

  Future<void> stop() async {
    await _tts.stop();
  }
}
