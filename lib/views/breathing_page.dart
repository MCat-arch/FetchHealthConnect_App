// pages/breathing_guide_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../services/breathing_service.dart';

class BreathingGuidePage extends StatefulWidget {
  const BreathingGuidePage({Key? key}) : super(key: key);

  @override
  State<BreathingGuidePage> createState() => _BreathingGuidePageState();
}

class _BreathingGuidePageState extends State<BreathingGuidePage>
    with SingleTickerProviderStateMixin {
  final BreathingService _breathingService = BreathingService();

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  StreamSubscription<String>? _instructionSub;
  StreamSubscription<int>? _countdownSub;
  StreamSubscription<bool>? _playingStateSub;

  String _currentPhase = 'ready';
  int _selectedDuration = 5;
  int _remainingTime = 300;
  bool _isPlaying = false;

  final Map<String, String> _phaseTitles = {
    'inhale': 'Breathe In',
    'hold': 'Hold',
    'exhale': 'Breathe Out',
    'ready': 'Ready',
    'stopped': 'Completed',
  };

  final Map<String, Color> _phaseColors = {
    'inhale': Colors.blueAccent,
    'hold': Colors.orangeAccent,
    'exhale': Colors.teal,
    'ready': Colors.grey,
    'stopped': Colors.purple,
  };

  @override
  void initState() {
    super.initState();

    // Setup animation
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.5).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _setupStreamListeners();
  }

  void _setupStreamListeners() {
    _instructionSub = _breathingService.instructionStream.listen((instruction) {
      final parts = instruction.split('|');
      if (parts.length >= 1) {
        final newPhase = parts[0];

        if (_currentPhase != newPhase) {
          setState(() {
            _currentPhase = newPhase;
          });
          _handleAnimationForPhase(newPhase);
        }
      }
    });

    _countdownSub = _breathingService.countdownStream.listen((seconds) {
      setState(() {
        _remainingTime = seconds;
      });
    });

    _playingStateSub = _breathingService.playingStateStream.listen((playing) {
      setState(() {
        _isPlaying = playing;
        if (!playing) {
          _currentPhase = 'stopped';
          _animationController.reset();
        }
      });
    });
  }

  void _handleAnimationForPhase(String phase) {
    _animationController.stop();

    switch (phase) {
      case 'inhale':
        _animationController.duration = const Duration(seconds: 4);
        _animationController.forward(from: 0.0);
        break;

      case 'hold':
        _animationController.value = 1.0;

      case 'exhale':
        _animationController.duration = const Duration(seconds: 8);
        _animationController.reverse(from: 1.0);

      case 'ready':
      case 'stopped':
        _animationController.reset();
        break;
    }
  }

  String _formatTime(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final remainingSeconds = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$remainingSeconds';
  }

  void _onDurationSelected(int minutes) {
    setState(() {
      _selectedDuration = minutes;
      _remainingTime = minutes * 60;
    });

    _breathingService.setDuration(minutes);
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Center(child: const Text('Breathing Guide'))),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),

              // 1. VISUALISASI LINGKARAN
              _buildBreathingCircle(),

              const SizedBox(height: 40),

              // 2. TEKS INSTRUKSI UTAMA
              Text(
                _phaseTitles[_currentPhase] ?? 'Ready',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: _phaseColors[_currentPhase],
                ),
              ),

              const SizedBox(height: 20),

              // 3. DESKRIPSI TEKNIK
              if (!_isPlaying && _currentPhase == 'ready')
                const Text(
                  '4-7-8 Technique\nInhale (4s) - Hold (7s) - Exhale (8s)',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),

              const SizedBox(height: 40),

              // 4. PEMILIH DURASI
              _buildDurationSelector(),

              const SizedBox(height: 20),

              // 5. KONTROL START/STOP
              _buildControlButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBreathingCircle() {
    return SizedBox(
      height: 300, // Area tetap agar tidak geser
      child: Center(
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Container(
              width: 200 * _scaleAnimation.value,
              height: 200 * _scaleAnimation.value,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                // Warna solid agar terlihat jelas mengembang/mengempis
                color: _phaseColors[_currentPhase]?.withOpacity(0.2),
                border: Border.all(
                  color: _phaseColors[_currentPhase] ?? Colors.grey,
                  width: 4,
                ),
                boxShadow: [
                  if (_currentPhase != 'ready' && _currentPhase != 'stopped')
                    BoxShadow(
                      color: _phaseColors[_currentPhase]!.withOpacity(0.3),
                      blurRadius: 20 * _scaleAnimation.value,
                      spreadRadius: 5,
                    ),
                ],
              ),
              child: Center(
                // Timer mundur di tengah lingkaran
                child: Text(
                  _formatTime(_remainingTime),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: _phaseColors[_currentPhase],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDurationSelector() {
    if (_isPlaying) return const SizedBox(height: 60); // Placeholder height

    return Column(
      children: [
        const Text(
          "Session Duration",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [1, 3, 5, 10].map((minutes) {
              final isSelected = _selectedDuration == minutes;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ChoiceChip(
                  label: Text('$minutes min'),
                  selected: isSelected,
                  selectedColor: Colors.blue.shade100,
                  onSelected: (selected) {
                    if (selected) _onDurationSelected(minutes);
                  },
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildControlButtons() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton.icon(
        onPressed: _isPlaying
            ? () => _breathingService.stopBreathing()
            : () => _breathingService.startBreathing(),
        style: ElevatedButton.styleFrom(
          backgroundColor: _isPlaying ? Colors.redAccent : Colors.green,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        icon: Icon(
          _isPlaying ? Icons.stop : Icons.play_arrow,
          color: Colors.white,
        ),
        label: Text(
          _isPlaying ? 'STOP SESSION' : 'START BREATHING',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _instructionSub?.cancel();
    _countdownSub?.cancel();
    _playingStateSub?.cancel();
    _animationController.dispose();
    // Jangan dispose _breathingService jika dia Singleton yang dipakai di tempat lain
    // _breathingService.dispose();
    super.dispose();
  }
}
