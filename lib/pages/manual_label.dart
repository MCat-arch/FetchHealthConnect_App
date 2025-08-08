import 'package:flutter/material.dart';

class ManualLabelPage extends StatelessWidget {
  const ManualLabelPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manual Label')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text('Apakah kamu sedang mengalami panic attack?'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Simpan label sebagai "Panic"
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Label disimpan sebagai Panic')),
                );
                Navigator.pop(context);
              },
              child: const Text('Ya, saya panic'),
            ),
            ElevatedButton(
              onPressed: () {
                // Simpan label sebagai "Tidak Panic"
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Label disimpan sebagai Tidak Panic')),
                );
                Navigator.pop(context);
              },
              child: const Text('Tidak, saya baik-baik saja'),
            ),
          ],
        ),
      ),
    );
  }
}
