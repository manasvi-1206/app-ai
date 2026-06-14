import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

class SpeechService {
  final SpeechToText _speechToText = SpeechToText();

  bool _isInitialized = false;

  bool get isListening => _speechToText.isListening;

  Future<bool> initialize() async {
    if (_isInitialized) {
      return true;
    }

    _isInitialized = await _speechToText.initialize();
    return _isInitialized;
  }

  Future<bool> startListening({
    required ValueChanged<String> onTextChanged,
  }) async {
    final available = await initialize();
    if (!available) {
      return false;
    }

    await _speechToText.listen(
      onResult: (SpeechRecognitionResult result) {
        onTextChanged(result.recognizedWords);
      },
    );

    return true;
  }

  Future<void> stopListening() async {
    if (_speechToText.isListening) {
      await _speechToText.stop();
    }
  }

  Future<void> cancelListening() async {
    if (_speechToText.isListening) {
      await _speechToText.cancel();
    }
  }
}
