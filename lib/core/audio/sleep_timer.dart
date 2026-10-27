import 'dart:async';

import 'audio_player_handler.dart';

/// Manages a countdown that fades out and pauses playback when it elapses.
/// Exposes [remaining] as a broadcast stream for UI countdown display.
class SleepTimer {
  final AudioPlayerHandler _handler;

  Timer? _ticker;
  Duration _remaining = Duration.zero;
  final _remainingController = StreamController<Duration?>.broadcast();

  SleepTimer(this._handler);

  Stream<Duration?> get remainingStream => _remainingController.stream;

  bool get isActive => _ticker != null;

  void start(Duration duration) {
    cancel();
    _remaining = duration;
    _remainingController.add(_remaining);
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void extend(Duration extra) {
    if (!isActive) return;
    _remaining += extra;
    _remainingController.add(_remaining);
  }

  void cancel() {
    _ticker?.cancel();
    _ticker = null;
    _remainingController.add(null);
  }

  Future<void> _tick() async {
    _remaining -= const Duration(seconds: 1);

    if (_remaining <= const Duration(seconds: 30) && _remaining > Duration.zero) {
      final fadeProgress = _remaining.inSeconds / 30;
      await _handler.player.setVolume(fadeProgress.clamp(0.05, 1.0));
    }

    if (_remaining <= Duration.zero) {
      cancel();
      await _handler.pause();
      await _handler.player.setVolume(1.0);
      return;
    }

    _remainingController.add(_remaining);
  }

  void dispose() {
    cancel();
    _remainingController.close();
  }
}
