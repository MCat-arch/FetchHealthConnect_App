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

  String _currentInstruction = 'Ready to start';
  String _currentPhase = 'ready';
  int _phaseProgress = 0;
  int _phaseTotal = 0;
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
    'inhale': Colors.green,
    'hold': Colors.orange,
    'exhale': Colors.blue,
    'ready': Colors.grey,
    'stopped': Colors.purple,
  };

  @override
  void initState() {
    super.initState();

    // Setup animation
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _setupStreamListeners();
  }

  void _setupStreamListeners() {
    _instructionSub = _breathingService.instructionStream.listen((instruction) {
      final parts = instruction.split('|');
      if (parts.length == 3) {
        setState(() {
          _currentPhase = parts[0];
          _phaseProgress = int.parse(parts[1]);
          _phaseTotal = int.parse(parts[2]);
        });
        _triggerAnimation();
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
        }
      });
    });
  }

  void _triggerAnimation() {
    _animationController.reset();
    _animationController.forward();
  }

  String _formatTime(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final remainingSeconds = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$remainingSeconds';
  }

  Widget _buildBreathingCircle() {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: _phaseColors[_currentPhase]?.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: _phaseColors[_currentPhase] ?? Colors.grey,
                width: 4,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _phaseTitles[_currentPhase] ?? 'Ready',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: _phaseColors[_currentPhase] ?? Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                if (_currentPhase != 'ready' && _currentPhase != 'stopped')
                  Text(
                    '$_phaseProgress / $_phaseTotal',
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProgressIndicator() {
    if (_currentPhase == 'ready' || _currentPhase == 'stopped') {
      return const SizedBox();
    }

    return Container(
      width: 200,
      height: 8,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Stack(
        children: [
          Container(
            width: 200 * (_phaseProgress / _phaseTotal),
            decoration: BoxDecoration(
              color: _phaseColors[_currentPhase],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructions() {
    final Map<String, String> instructions = {
      'inhale': 'Breathe in slowly through your nose...',
      'hold': 'Hold your breath and relax...',
      'exhale': 'Breathe out slowly through your mouth...',
      'ready': 'Tap Start to begin breathing exercise',
      'stopped': 'Great job! You completed the session.',
    };

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Text(
            instructions[_currentPhase] ?? 'Follow the guidance',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, height: 1.5),
          ),
          const SizedBox(height: 12),
          if (_currentPhase != 'ready' && _currentPhase != 'stopped')
            Text(
              '4-7-8 Breathing Technique\n'
              'for Anxiety and Panic Relief',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildControlButtons() {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (!_isPlaying) ...[
            ElevatedButton.icon(
              onPressed: () => _breathingService.startBreathing(),
              icon: const Icon(Icons.play_arrow),
              label: const Text('Start Session'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ] else ...[
            ElevatedButton.icon(
              onPressed: () => _breathingService.stopBreathing(),
              icon: const Icon(Icons.stop),
              label: const Text('Stop Session'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDurationSelector() {
    if (_isPlaying) return const SizedBox();

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        children: [
          const Text(
            'Session Duration',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [1, 3, 5, 10].map((minutes) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text('$minutes min'),
                    selected: minutes == 5, // Default 5 minutes
                    onSelected: (selected) {
                      // You can implement duration change here
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Breathing Guide'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (_isPlaying)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _formatTime(_remainingTime),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Breathing visualization
              _buildBreathingCircle(),

              const SizedBox(height: 20),

              // Progress indicator
              _buildProgressIndicator(),

              const SizedBox(height: 20),

              // Instructions
              _buildInstructions(),

              // Duration selector (only when not playing)
              _buildDurationSelector(),

              // Control buttons
              _buildControlButtons(),

              // Additional info
              if (!_isPlaying)
                Container(
                  margin: const EdgeInsets.only(top: 30),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Column(
                    children: [
                      Icon(
                        Icons.health_and_safety,
                        color: Colors.blue,
                        size: 32,
                      ),
                      SizedBox(height: 8),
                      Text(
                        '4-7-8 Breathing Technique',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'This technique helps calm the nervous system, '
                        'reduce anxiety, and promote relaxation. '
                        'Follow the audio guidance for best results.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
            ],
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
    _breathingService.dispose();
    super.dispose();
  }
}
