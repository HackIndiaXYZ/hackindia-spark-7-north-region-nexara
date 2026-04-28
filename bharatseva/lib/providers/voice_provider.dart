import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';

class VoiceProvider with ChangeNotifier {
  final SpeechToText _speechToText = SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  bool _isListening = false;
  String _spokenText = '';
  bool _speechEnabled = false;

  VoiceProvider() {
    _initSpeech();
    _initTts();
  }

  bool get isListening => _isListening;
  String get spokenText => _spokenText;

  void _initTts() async {
    await _flutterTts.setLanguage("hi-IN");
  }

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
            _spokenText = 'Aapne kuch nahi bola. Mujhe aapke baare me bataiye';
            _flutterTts.speak(_spokenText);
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

    if (_speechToText.isListening) {
      _stopListening();
    } else {
      _startListening();
    }
  }

  void _startListening() async {
    if (_speechToText.isListening) return;

    // Stop any ongoing speech before listening
    await _flutterTts.stop();

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
    if (_speechToText.isListening) {
      await _speechToText.stop();
    }
    _isListening = false;
    if (_spokenText == 'Listening to your request...') {
      _spokenText = 'Aapne kuch nahi bola. Mujhe aapke baare me bataiye';
      _flutterTts.speak(_spokenText);
    }
    notifyListeners();
  }

  void setSpokenText(String text) {
    _spokenText = text;
    notifyListeners();
  }
}
