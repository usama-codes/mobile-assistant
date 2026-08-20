import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_assistant/core/services/voice_service.dart';

enum MicStatus { idle, listening, disabled }

class VoiceState {
  const VoiceState({
    this.status = MicStatus.idle,
    this.transcript = '',
    this.lastError,
  });

  final MicStatus status;
  final String transcript;
  final String? lastError;

  bool get isListening => status == MicStatus.listening;

  VoiceState copyWith({
    MicStatus? status,
    String? transcript,
    String? lastError,
  }) =>
      VoiceState(
        status: status ?? this.status,
        transcript: transcript ?? this.transcript,
        lastError: lastError,
      );
}

class VoiceNotifier extends Notifier<VoiceState> {
  @override
  VoiceState build() => const VoiceState();

  /// Attempts to start listening. Returns the status reason for
  /// callers that need to show feedback.
  Future<String> startListening() async {
    final started = VoiceService.instance.startListening(
      (t) => state = state.copyWith(transcript: t),
      onAutoStop: _handleAutoStop,
    );
    if (!started) {
      return 'Microphone not available — check that mic permission is granted.';
    }
    state = state.copyWith(
      status: MicStatus.listening,
      transcript: '',
      lastError: null,
    );
    return '';
  }

  Future<void> stopListening() async {
    await VoiceService.instance.stopListening();
    state = state.copyWith(status: MicStatus.idle);
  }

  void _handleAutoStop() {
    state = state.copyWith(status: MicStatus.idle);
  }

  /// Returns the final transcript and clears the buffer.
  String consumeTranscript() {
    final t = state.transcript;
    state = state.copyWith(transcript: '');
    return t;
  }
}

final voiceNotifierProvider =
    NotifierProvider<VoiceNotifier, VoiceState>(VoiceNotifier.new);
