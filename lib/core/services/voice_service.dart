// ignore_for_file: deprecated_member_use

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Manages voice I/O: STT via speech_to_text, TTS via flutter_tts.
class VoiceService {
  VoiceService._();
  static final VoiceService instance = VoiceService._();

  final SpeechToText _stt = SpeechToText();
  final FlutterTts _tts = FlutterTts();

  bool _sttAvailable = false;
  bool _isListening = false;
  String _transcript = '';

  bool get isListening => _isListening;
  String get transcript => _transcript;

  /// Called when listening auto-stops (e.g., silence timeout or max duration).
  VoidCallback? _onAutoStop;

  /// Returns true only when microphone permission was granted and STT is
  /// ready. On failure, returns false and logs the reason.
  Future<bool> initialize() async {
    try {
      _sttAvailable = await _stt.initialize(
        onError: (e) {
          debugPrint('[VoiceService] STT error: ${e.errorMsg}');
          _isListening = false;
        },
        onStatus: (s) {
          debugPrint('[VoiceService] STT status: $s');
          if (s == 'done' || s == 'notListening') {
            _isListening = false;
            _onAutoStop?.call();
          }
        },
      );
    } catch (e) {
      debugPrint('[VoiceService] STT init failed: $e');
      _sttAvailable = false;
    }
    try {
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.5);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
      await _tts.awaitSpeakCompletion(true);
    } catch (e) {
      debugPrint('[VoiceService] TTS init failed: $e');
    }
    debugPrint('[VoiceService] available=$_sttAvailable');
    return _sttAvailable;
  }

  /// Attempts to start listening. [onAutoStop] fires when listening ends
  /// automatically (silence timeout or max duration reached).
  /// Returns true on success, false if unavailable or already listening.
  bool startListening(
    void Function(String transcript) onResult, {
    VoidCallback? onAutoStop,
  }) {
    if (!_sttAvailable || _isListening) return false;
    _transcript = '';
    _isListening = true;
    _onAutoStop = onAutoStop;
    _stt.listen(
      onResult: (SpeechRecognitionResult r) {
        _transcript = r.recognizedWords;
        onResult(_transcript);
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 4),
      localeId: 'en_US',
    );
    return true;
  }

  Future<void> stopListening() async {
    if (!_isListening) return;
    try {
      await _stt.stop();
    } catch (_) {}
    _isListening = false;
    _onAutoStop = null;
  }

  Future<void> speak(String text) async {
    await _tts.stop();
    await _tts.speak(text);
  }

  Future<void> stopSpeaking() async => _tts.stop();
}
