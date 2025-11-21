import 'dart:async';
import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';

class BreathingService {
  static final BreathingService _instance = BreathingService._internal();
  factory BreathingService() => _instance;

  final AudioPlayer _audioPlayer = AudioPlayer();
  Timer? _breathingTimer;
  Timer? _countdownTimer;
  int _remainingSeconds = 300; // 5 minutes default
  bool _isPlaying = false;

  // Breathing pattern for panic attack: 4-7-8 technique
  final Map<String, int> _breathingPattern = {
    'inhale': 4, // Inhale for 4 seconds
    'hold': 7, // Hold for 7 seconds
    'exhale': 8, // Exhale for 8 seconds
  };

  final StreamController<String> _instructionCtrl =
      StreamController<String>.broadcast();
  final StreamController<int> _countdownCtrl =
      StreamController<int>.broadcast();
  final StreamController<bool> _playingStateCtrl =
      StreamController<bool>.broadcast();

  Stream<String> get instructionStream => _instructionCtrl.stream;
  Stream<int> get countdownStream => _countdownCtrl.stream;
  Stream<bool> get playingStateStream => _playingStateCtrl.stream;

  BreathingService._internal() {
    _initializeAudio();
  }

  Future<void> _initializeAudio() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.speech());

    await _audioPlayer.setAsset('/assets/beep.mp3');
  }

  bool get isPlaying => _isPlaying;
  int get remainingSeconds => _remainingSeconds;

  Future<void> startBreathing({int durationMinutes = 5}) async {
    if (_isPlaying) return;

    _isPlaying = true;
    _remainingSeconds = durationMinutes * 60;
    _playingStateCtrl.add(true);

    // Start the main breathing cycle
    _startBreathingCycle();
    // Start countdown timer
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _remainingSeconds--;
      _countdownCtrl.add(_remainingSeconds);

      if (_remainingSeconds <= 0) {
        stopBreathing();
      }
    });
  }

  void _startBreathingCycle() {
    _breathingTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      final cycleTime =
          timer.tick % (_breathingPattern.values.reduce((a, b) => a + b));
      var accumulatedTime = 0;

      for (var phase in _breathingPattern.entries) {
        if (cycleTime < accumulatedTime + phase.value) {
          final phaseProgress = cycleTime - accumulatedTime + 1;
          _instructionCtrl.add('${phase.key}|$phaseProgress|${phase.value}');
          // Play beep on phase start
          if (phaseProgress == 1) {
            await _playBeep();
          }
          break;
        }
        accumulatedTime += phase.value;
      }
    });
  }

  Future<void> _playBeep() async {
    try {
      await _audioPlayer.seek(Duration.zero);
      await _audioPlayer.play();
    } catch (e) {
      print('Error playing beep: $e');
    }
  }

  Future<void> stopBreathing() async {
    _breathingTimer?.cancel();
    _countdownTimer?.cancel();
    _isPlaying = false;

    _instructionCtrl.add('stopped');
    _playingStateCtrl.add(false);

    await _audioPlayer.stop();
  }

  Future<void> dispose() async {
    await stopBreathing();
    await _audioPlayer.dispose();
    _instructionCtrl.close();
    _countdownCtrl.close();
    _playingStateCtrl.close();
  }
}
