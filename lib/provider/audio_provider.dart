

// Controls global mute state
import 'package:hooks_riverpod/hooks_riverpod.dart';

class AudioState {
  final bool isMuted;

  AudioState({required this.isMuted});

  AudioState copyWith({bool? isMuted}) {
    return AudioState(isMuted: isMuted ?? this.isMuted);
  }
}

class AudioNotifier extends StateNotifier<AudioState> {
  AudioNotifier() : super(AudioState(isMuted: true));

  void toggleMute() {
    state = state.copyWith(isMuted: !state.isMuted);
  }

  void setMuted(bool muted) {
    state = state.copyWith(isMuted: muted);
  }
}

final audioProvider = StateNotifierProvider<AudioNotifier, AudioState>((ref) {
  return AudioNotifier();
});