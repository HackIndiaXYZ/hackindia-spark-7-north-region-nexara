import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../models/scheme.dart';

enum VoiceFormState {
  notStarted,
  gender,
  age,
  maritalStatus,
  state,
  residence,
  category,
  disability,
  disabilityPercentage,
  minority,
  student,
  bpl,
  hardship,
  income,
  completed,
}

class VoiceProvider with ChangeNotifier {
  final SpeechToText _speechToText = SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  bool _isListening = false;
  String _spokenText = '';
  bool _speechEnabled = false;
  bool _isProcessing = false;
  bool _isSpeaking = false;

  VoiceFormState _formState = VoiceFormState.notStarted;
  Map<String, String> userProfile = {};
  int _retryCount = 0;

  List<Scheme> _allSchemes = [];
  List<Scheme> _suggestedSchemes = [];

  VoiceProvider() {
    _loadSchemes();
    _initSpeech();
    _initTts();
  }

  bool get isListening => _isListening;
  String get spokenText => _spokenText;
  List<Scheme> get suggestedSchemes => _suggestedSchemes;
  VoiceFormState get formState => _formState;

  void _loadSchemes() async {
    try {
      final String response = await rootBundle.loadString(
        'lib/assets/schemes.json',
      );
      final List<dynamic> data = json.decode(response);
      _allSchemes = data.map((e) => Scheme.fromJson(e)).toList();
    } catch (e) {
      print('Error loading schemes: $e');
    }
  }

  void _initTts() async {
    await _flutterTts.setLanguage("hi-IN");
    // Removed awaitSpeakCompletion(true) completely because it blocks forever on this device!

    _flutterTts.setStartHandler(() {
      _isSpeaking = true;
      notifyListeners();
    });

    _flutterTts.setCompletionHandler(() {
      _isSpeaking = false;
      notifyListeners();
    });

    _flutterTts.setErrorHandler((msg) {
      _isSpeaking = false;
      notifyListeners();
    });
  }

  void _safeStartListening() async {
    // First, give the TTS engine up to 2 seconds to officially report that it HAS STARTED speaking
    for (int i = 0; i < 10; i++) {
      if (_isSpeaking) break;
      await Future.delayed(const Duration(milliseconds: 200));
    }

    // Now, bulletproof loop to wait until the TTS actually FINISHES speaking
    for (int i = 0; i < 40; i++) { // Wait up to 20 seconds max for very long questions
      if (!_isSpeaking) break;
      await Future.delayed(const Duration(milliseconds: 500));
    }
    
    // Wait an extra half-second for speaker echo to dissipate completely
    await Future.delayed(const Duration(milliseconds: 500));
    if (!_isListening && !_speechToText.isListening) {
      _startListening();
    }
  }

  Future<void> startOnboarding() async {
    if (_formState != VoiceFormState.notStarted) return;
    _formState = VoiceFormState.gender;
    _spokenText = 'Waiting for voice...';
    _retryCount = 0;
    userProfile['Debug Log'] = ''; // Initialize log
    notifyListeners();

    await _flutterTts.speak(
      "Main aapki sahayata karna chahti hun. Sabse pehle, aapka ling kya hai? Purush, Mahila, ya anya?",
    );
    _safeStartListening();
  }

  void _initSpeech() async {
    _speechEnabled = await _speechToText.initialize(
      onError: (error) {
        // If it's just a timeout or no match, don't spam the user with repeats
        if (error.errorMsg == 'error_speech_timeout' ||
            error.errorMsg == 'error_no_match') {
          _spokenText = 'Listening to your request...'; // Keep it pending
          _isListening = false;
          notifyListeners();
          // Silently restart the mic once to give them more time
          Future.delayed(const Duration(milliseconds: 500), () {
            _startListening();
          });
          return;
        }

        _spokenText = 'Error recognizing speech: ${error.errorMsg}';
        _isListening = false;
        notifyListeners();
        if (!_isProcessing) {
          _processVoiceInput();
        }
      },
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          if (_isListening) {
            _isListening = false;
            if (!_isProcessing) {
              _processVoiceInput();
            }
          }
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

    if (_speechToText.isListening || _isListening) {
      _flutterTts.stop(); // ONLY stop TTS when user manually toggles
      _stopListening();
    } else {
      _startListening();
    }
  }

  void _startListening() async {
    if (_speechToText.isListening) return;

    // REMOVED await _flutterTts.stop(); so we never cut off TTS prematurely!

    _spokenText = 'Listening to your request...';
    _isListening = true;
    _suggestedSchemes = [];
    notifyListeners();

    try {
      await _speechToText.listen(
        onResult: (result) {
          if (result.recognizedWords.isNotEmpty) {
            _spokenText = result.recognizedWords;
            userProfile['Debug Log'] =
                '${userProfile['Debug Log'] ?? ''} [Hear: ${result.recognizedWords}]';
          }
          notifyListeners();
        },
        localeId: 'hi_IN',
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(
          seconds: 10,
        ), // Wait up to 10 seconds of silence!
      );
    } catch (e) {
      _isListening = false;
      _spokenText = 'Error: $e';
      notifyListeners();
      if (!_isProcessing) {
        _processVoiceInput();
      }
    }
  }

  void _stopListening() async {
    if (_speechToText.isListening) {
      await _speechToText.stop();
    }
    if (_isListening) {
      _isListening = false;
      if (!_isProcessing) {
        _processVoiceInput();
      }
    }
  }

  void _processVoiceInput() async {
    if (_isProcessing) return;
    _isProcessing = true;

    if (_formState == VoiceFormState.notStarted ||
        _formState == VoiceFormState.completed) {
      _isProcessing = false;
      return;
    }

    if (_spokenText == 'Listening to your request...' ||
        _spokenText.trim().isEmpty ||
        _spokenText.startsWith('Error')) {
      _retryCount++;
      if (_retryCount >= 3) {
        // Increased to 3 tries
        _spokenText = 'Not Provided';
      } else {
        _isProcessing = false;
        _repeatCurrentQuestion();
        return;
      }
    }

    String answer = _spokenText.toLowerCase();

    switch (_formState) {
      case VoiceFormState.gender:
        userProfile['Gender'] = answer;
        _formState = VoiceFormState.age;
        _askQuestion("Aapki umar kya hai?");
        break;
      case VoiceFormState.age:
        userProfile['Age'] = answer;

        bool isFemale =
            userProfile['Gender']?.contains('mahila') == true ||
            userProfile['Gender']?.contains('female') == true ||
            userProfile['Gender']?.contains('aurat') == true ||
            userProfile['Gender']?.contains('girl') == true;
        int age = int.tryParse(answer.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

        if (isFemale && age >= 18) {
          _formState = VoiceFormState.maritalStatus;
          _askQuestion(
            "Aapki vaivahik sthiti kya hai? Vivahit, avivahit, vidhwa, ya talakshuda?",
          );
        } else {
          _formState = VoiceFormState.state;
          _askQuestion("Aap kis rajya ke nivasi hain?");
        }
        break;
      case VoiceFormState.maritalStatus:
        userProfile['Marital Status'] = answer;
        _formState = VoiceFormState.state;
        _askQuestion("Aap kis rajya ke nivasi hain?");
        break;
      case VoiceFormState.state:
        userProfile['State'] = answer;
        _formState = VoiceFormState.residence;
        _askQuestion("Aap kis shetra mein rehte hain? Shahri ya Gramin?");
        break;
      case VoiceFormState.residence:
        userProfile['Area of Residence'] = answer;
        _formState = VoiceFormState.category;
        _askQuestion("Aap kis varg se hain? General, OBC, SC, ST, ya anya?");
        break;
      case VoiceFormState.category:
        userProfile['Category'] = answer;
        _formState = VoiceFormState.disability;
        _askQuestion("Kya aap divyang hain? Haan ya Naa?");
        break;
      case VoiceFormState.disability:
        userProfile['Person with Disability'] = answer;
        if (answer.contains('haan') ||
            answer.contains('yes') ||
            answer.contains('ha') ||
            answer.contains('ji')) {
          _formState = VoiceFormState.disabilityPercentage;
          _askQuestion(
            "Aapki divyangta ka pratishat kya hai? Zero se sau ke beech mein bataiye.",
          );
        } else {
          _formState = VoiceFormState.minority;
          _askQuestion("Kya aap alpasankhyak varg se hain? Haan ya Naa?");
        }
        break;
      case VoiceFormState.disabilityPercentage:
        userProfile['Disability Percentage'] = answer;
        _formState = VoiceFormState.student;
        _askQuestion("Kya aap abhi vidyarthi hain? Haan ya Naa?");
        break;
      case VoiceFormState.minority:
        userProfile['Minority'] = answer;
        _formState = VoiceFormState.student;
        _askQuestion("Kya aap abhi vidyarthi hain? Haan ya Naa?");
        break;
      case VoiceFormState.student:
        userProfile['Student'] = answer;
        _formState = VoiceFormState.bpl;
        _askQuestion("Kya aap BPL shreni mein aate hain? Haan ya Naa?");
        break;
      case VoiceFormState.bpl:
        userProfile['BPL Category'] = answer;
        if (answer.contains('haan') ||
            answer.contains('yes') ||
            answer.contains('ha') ||
            answer.contains('ji')) {
          _formState = VoiceFormState.hardship;
          _askQuestion(
            "Kya aap kisi aarthik sankat jaise niraashrit ya behad garibi ka saamna kar rahe hain? Haan ya Naa?",
          );
        } else {
          _formState = VoiceFormState.income;
          _askQuestion("Aapke parivar ki vaarshik aay kitni hai?");
        }
        break;
      case VoiceFormState.hardship:
        userProfile['Extreme Hardship'] = answer;
        _finishForm();
        break;
      case VoiceFormState.income:
        userProfile['Annual Family Income'] = answer;
        _finishForm();
        break;
      default:
        break;
    }

    _isProcessing = false;
  }

  void _askQuestion(String questionText, {bool isRetry = false}) async {
    if (!isRetry) {
      _retryCount = 0; // Reset retry count for new questions
    }
    _spokenText = 'Waiting for voice...';
    notifyListeners();
    await _flutterTts.speak(questionText);
    _safeStartListening();
  }

  void _repeatCurrentQuestion() {
    switch (_formState) {
      case VoiceFormState.gender:
        _askQuestion(
          "Kripya bataiye, aapka ling kya hai? Purush, Mahila, ya anya?",
          isRetry: true,
        );
        break;
      case VoiceFormState.age:
        _askQuestion("Kripya apni umar bataiye.", isRetry: true);
        break;
      case VoiceFormState.maritalStatus:
        _askQuestion("Kripya apni vaivahik sthiti bataiye.", isRetry: true);
        break;
      case VoiceFormState.state:
        _askQuestion("Kripya apne rajya ka naam bataiye.", isRetry: true);
        break;
      case VoiceFormState.residence:
        _askQuestion(
          "Kripya bataiye aap kis shetra mein rehte hain? Shahri ya Gramin?",
          isRetry: true,
        );
        break;
      case VoiceFormState.category:
        _askQuestion(
          "Kripya apna varg bataiye. General, OBC, SC, ST, ya anya?",
          isRetry: true,
        );
        break;
      case VoiceFormState.disability:
        _askQuestion(
          "Kripya bataiye, kya aap divyang hain? Haan ya Naa?",
          isRetry: true,
        );
        break;
      case VoiceFormState.disabilityPercentage:
        _askQuestion(
          "Kripya apni divyangta ka pratishat bataiye.",
          isRetry: true,
        );
        break;
      case VoiceFormState.minority:
        _askQuestion(
          "Kripya bataiye, kya aap alpasankhyak varg se hain? Haan ya Naa?",
          isRetry: true,
        );
        break;
      case VoiceFormState.student:
        _askQuestion(
          "Kripya bataiye, kya aap abhi vidyarthi hain? Haan ya Naa?",
          isRetry: true,
        );
        break;
      case VoiceFormState.bpl:
        _askQuestion(
          "Kripya bataiye, kya aap BPL shreni mein aate hain? Haan ya Naa?",
          isRetry: true,
        );
        break;
      case VoiceFormState.hardship:
        _askQuestion(
          "Kripya bataiye, kya aap aarthik sankat ka saamna kar rahe hain? Haan ya Naa?",
          isRetry: true,
        );
        break;
      case VoiceFormState.income:
        _askQuestion(
          "Kripya apne parivar ki vaarshik aay bataiye.",
          isRetry: true,
        );
        break;
      default:
        break;
    }
  }

  void _finishForm() async {
    _formState = VoiceFormState.completed;
    _spokenText =
        "Dhanyavad. Humne aapki jankari darj kar li hai. Yahan aapka profile hai.";
    notifyListeners();
    await _flutterTts.speak(_spokenText);

    _suggestedSchemes = _pickRandomSchemes(3);
    notifyListeners();
  }

  List<Scheme> _pickRandomSchemes(int count) {
    if (_allSchemes.isEmpty) return [];
    final random = Random();
    List<Scheme> shuffled = List.from(_allSchemes)..shuffle(random);
    return shuffled.take(count).toList();
  }

  void setSpokenText(String text) {
    _spokenText = text;
    notifyListeners();
  }

  void clearSuggestedSchemes() {
    _suggestedSchemes = [];
  }
}
