import 'package:aura_bluetooth/services/firestore_service.dart';
import 'package:aura_bluetooth/utils/storage_helper.dart';
import 'package:aura_bluetooth/views/breathing_page.dart';
import 'package:flutter/material.dart';

class ValidationPage extends StatefulWidget {
  final String eventTimestamp;
  const ValidationPage({super.key, required this.eventTimestamp});

  @override
  State<ValidationPage> createState() => _ValidationPageState();
}

class _ValidationPageState extends State<ValidationPage> {
  bool _isUpdating = false;

  Future<void> submitFeedback(String status, VoidCallback onSuccess) async {
    setState(() {
      _isUpdating = true;
    });

    try {
      // final int ms = int.parse(widget.eventTimestamp);
      // final DateTime dt = DateTime.fromMillisecondsSinceEpoch(ms);

      final String isoString;
      // CHECK: Is the input already an ISO Date string (contains 'T')?
      if (widget.eventTimestamp.contains('T')) {
        // Case 1: It's already "2025-12-01T..."
        isoString = widget.eventTimestamp;
      } else {
        // Case 2: It's a timestamp integer "17645..." (from Notification payload)
        final int ms = int.parse(widget.eventTimestamp);
        final DateTime dt = DateTime.fromMillisecondsSinceEpoch(ms);
        isoString = dt.toIso8601String();
      }

      await FirestoreService().updatePanicValidation(isoString, status);

      if (mounted) {
        setState(() => _isUpdating = false);
        onSuccess();
      }
    } catch (e) {
      print("Error submitting feedback: $e");
      if (mounted) {
        setState(() => _isUpdating = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Gagal menyimpan: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(child: const Text("Panic Validation")),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: _isUpdating
            ? const CircularProgressIndicator()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.help_outline,
                    size: 64,
                    color: Colors.orange,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "We detected a potential panic attack.",
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Are you feeling panicked?",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 40),

                  SizedBox(
                    width: 200,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade100,
                        foregroundColor: Colors.red.shade900,
                      ),
                      onPressed: () {
                        submitFeedback('confirmed', () {
                          // Jika ya, arahkan ke relaksasi
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const BreathingGuidePage(),
                            ),
                          );
                        });
                      },
                      child: const Text("Yes, I need help"),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // TOMBOL NO (False Positive)
                  SizedBox(
                    width: 200,
                    height: 50,
                    child: TextButton(
                      onPressed: () {
                        submitFeedback('rejected', () {
                          // Jika tidak, tutup halaman dan kembali ke Home
                          Navigator.pop(context);
                        });
                      },
                      child: const Text("No, I'm fine"),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
