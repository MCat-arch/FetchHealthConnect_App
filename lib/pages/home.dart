import 'package:app_aura/components/box_stats.dart';
import 'package:app_aura/components/data_date.dart';
import 'package:app_aura/pages/manual_input_form.dart';
import 'package:flutter/material.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Hai')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(padding: EdgeInsets.all(15)),
            BoxStats(),
            Expanded(child: DataDate()),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ManualInputForm()),
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
