import 'dart:async';
import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';

class BreathingService {
  static final BreathingService _instance = BreathingService._internal();
  factory BreathingService() => _instance;

  final AudioPlayer _audioPlayer = AudioPlayer();
  Timer? _sessionTimer;

  int _sessionDurationSeconds = 300;
  int _remainingSeconds = 300;
  bool _isPlaying = false;

  int _phaseIndex = 0;
  int _secondsInCurrentPhase = 0;
  // Breathing pattern for panic attack: 4-7-8 technique
  final List<Map<String, dynamic>> _phase = [
    {'name': 'inhale', 'duration': 4},
    {'name': 'hold', 'duration': 7},
    {'name': 'exhale', 'duration': 8},
  ];

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
    await _audioPlayer.setVolume(1.0);
  }

  bool get isPlaying => _isPlaying;
  int get remainingSeconds => _remainingSeconds;

  void setDuration(int minutes) {
    if (_isPlaying) return; // Jangan ubah jika sedang jalan

    _sessionDurationSeconds = minutes * 60;
    _remainingSeconds = _sessionDurationSeconds;

    // Update UI segera agar angka timer berubah
    _countdownCtrl.add(_remainingSeconds);
  }

  Future<void> startBreathing() async {
    if (_isPlaying) return;

    _isPlaying = true;
    _playingStateCtrl.add(true);

    // Reset state siklus napas
    _phaseIndex = 0; // Mulai dari inhale
    _secondsInCurrentPhase = 0;

    // Jika sisa waktu 0 (misal habis stop), reset ke durasi yang dipilih
    if (_remainingSeconds <= 0) {
      _remainingSeconds = _sessionDurationSeconds;
    }

    // Play suara pertama segera
    _processTick();

    // Mulai Timer 1 detik
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds <= 0) {
        stopBreathing();
      } else {
        _processTick();
      }
    });
  }

  // Logika inti yang dijalankan setiap detik
  void _processTick() {
    _remainingSeconds--;
    _countdownCtrl.add(_remainingSeconds);

    // 1. Ambil data fase saat ini
    final currentPhaseData = _phase[_phaseIndex];
    final String phaseName = currentPhaseData['name'];
    final int phaseDuration = currentPhaseData['duration'];

    // 2. Increment detik dalam fase ini (1, 2, 3...)
    _secondsInCurrentPhase++;

    // 3. Kirim instruksi ke UI: "nama|detik_sekarang|total_detik"
    // Contoh: "inhale|1|4", "inhale|2|4"
    _instructionCtrl.add('$phaseName|$_secondsInCurrentPhase|$phaseDuration');

    // 4. Mainkan suara Metronom (Setiap detik)
    _playBeep();

    // 5. Cek apakah fase sudah selesai?
    if (_secondsInCurrentPhase >= phaseDuration) {
      // Pindah ke fase berikutnya
      _phaseIndex = (_phaseIndex + 1) % _phase.length; // Loop 0 -> 1 -> 2 -> 0
      _secondsInCurrentPhase = 0; // Reset hitungan detik fase
    }
  }

  Future<void> _playBeep() async {
    try {
      // Seek ke awal agar bisa diputar ulang cepat (metronom style)
      await _audioPlayer.seek(Duration.zero);
      await _audioPlayer.play();
    } catch (e) {
      print('Error playing beep: $e');
    }
  }

  Future<void> stopBreathing() async {
    _sessionTimer?.cancel();
    _isPlaying = false;

    _instructionCtrl.add('stopped|0|0');
    _playingStateCtrl.add(false);

    // Reset timer display ke durasi awal agar rapi
    _remainingSeconds = _sessionDurationSeconds;
    _countdownCtrl.add(_remainingSeconds);

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
