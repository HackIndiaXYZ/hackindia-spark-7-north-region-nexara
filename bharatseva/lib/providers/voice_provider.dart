import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';

class VoiceProvider with ChangeNotifier {
  final SpeechToText _speechToText = SpeechToText();
  bool _isListening = false;
  String _spokenText = '';
  bool _speechEnabled = false;

  VoiceProvider() {
    _initSpeech();
  }

  bool get isListening => _isListening;
  String get spokenText => _spokenText;

  void _initSpeech() async {
    _speechEnabled = await _speechToText.initialize(
      onError: (error) {
        _spokenText = 'Error recognizing speech: ${error.errorMsg}';
        _isListening = false;
        notifyListeners();
      },
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          _isListening = false;
          if (_spokenText == 'Listening to your request...') {
            _spokenText = 'Tap the mic to discover government schemes';
          }
          notifyListeners();
        }
      },
    );
    notifyListeners();
  }

  void toggleListening() {
    if (!_speechEnabled) {
      _initSpeech();
      _spokenText =
          'Speech recognition not available or permission denied. Please try again.';
      notifyListeners();
      return;
    }

    if (_isListening) {
      _stopListening();
    } else {
      _startListening();
    }
  }

  void _startListening() async {
    _spokenText = 'Listening to your request...';
    _isListening = true;
    notifyListeners();

    try {
      await _speechToText.listen(
        onResult: (result) {
          if (result.recognizedWords.isNotEmpty) {
            _spokenText = result.recognizedWords;
          }
          notifyListeners();
        },
        localeId: 'en_IN',
      );
    } catch (e) {
      _isListening = false;
      _spokenText = 'Error: $e';
      notifyListeners();
    }
  }

  void _stopListening() async {
    await _speechToText.stop();
    _isListening = false;
    if (_spokenText == 'Listening to your request...') {
      _spokenText = 'Tap the mic to discover government schemes';
    }
    notifyListeners();
  }

  void setSpokenText(String text) {
    _spokenText = text;
    notifyListeners();
  }
}
