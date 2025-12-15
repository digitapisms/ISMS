import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

enum TtsState { playing, stopped, paused, continued }

class AccessibilityService {
  final FlutterTts _tts = FlutterTts();
  final stt.SpeechToText _speech = stt.SpeechToText();
  
  TtsState _ttsState = TtsState.stopped;
  bool _isListening = false;
  
  AccessibilityService() {
    _initTts();
  }
  
  Future<void> _initTts() async {
    await _tts.setSharedInstance(true);
    await _tts.setIosAudioCategory(
      IosTextToSpeechAudioCategory.playback,
      [
        IosTextToSpeechAudioCategoryOptions.allowBluetooth,
        IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
        IosTextToSpeechAudioCategoryOptions.mixWithOthers,
      ],
    );
    
    _tts.setStartHandler(() {
      _ttsState = TtsState.playing;
    });
    
    _tts.setCompletionHandler(() {
      _ttsState = TtsState.stopped;
    });
    
    _tts.setCancelHandler(() {
      _ttsState = TtsState.stopped;
    });
    
    _tts.setErrorHandler((msg) {
      _ttsState = TtsState.stopped;
    });
  }
  
  Future<void> speak(String text, {double volume = 0.5, double rate = 0.5, double pitch = 1.0}) async {
    if (text.isNotEmpty) {
      await _tts.setVolume(volume);
      await _tts.setSpeechRate(rate);
      await _tts.setPitch(pitch);
      await _tts.speak(text);
    }
  }
  
  Future<void> stopSpeaking() async {
    await _tts.stop();
    _ttsState = TtsState.stopped;
  }
  
  Future<bool> initializeSpeech() async {
    return await _speech.initialize(
      onStatus: (status) {
        _isListening = status == stt.SpeechToText.listeningStatus;
      },
      onError: (error) {
        _isListening = false;
      },
    );
  }
  
  Future<void> startListening({
    required Function(String) onResult,
    Function()? onError,
  }) async {
    if (await initializeSpeech()) {
      await _speech.listen(
        onResult: (result) {
          if (result.finalResult) {
            onResult(result.recognizedWords);
          }
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        localeId: 'en_US',
        cancelOnError: true,
        listenMode: stt.ListenMode.confirmation,
        onSoundLevelChange: (level) {},
        onDevice: !kIsWeb,
      );
    } else if (onError != null) {
      onError();
    }
  }
  
  Future<void> stopListening() async {
    await _speech.stop();
    _isListening = false;
  }
  
  bool get isSpeaking => _ttsState == TtsState.playing;
  bool get isListening => _isListening;
  TtsState get ttsState => _ttsState;
}