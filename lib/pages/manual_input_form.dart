import 'package:flutter/material.dart';

class ManualInputForm extends StatefulWidget {
  const ManualInputForm({super.key});

  @override
  State<ManualInputForm> createState() => _ManualInputFormState();
}

class _ManualInputFormState extends State<ManualInputForm> {
  final _formKey = GlobalKey<FormState>();
  String? panicStatus; 
  TimeOfDay? startTime;
  TimeOfDay? endTime;
  DateTime? selectedDate;
  TextEditingController contentController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Manual Input')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Title
              Text(
                'Manual Data Fill by User',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),

              // Dropdown Panic
              DropdownButtonFormField<String>(
                decoration: InputDecoration(labelText: 'Apakah mengalami Panic Attack?'),
                value: panicStatus,
                items: ['Iya', 'Tidak'].map((value) {
                  return DropdownMenuItem(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    panicStatus = val;
                  });
                },
                validator: (val) => val == null ? 'Wajib dipilih' : null,
              ),
              SizedBox(height: 16),

              // Date Picker
              ListTile(
                title: Text(selectedDate == null
                    ? 'Pilih Tanggal'
                    : 'Tanggal: ${selectedDate!.toLocal().toString().split(' ')[0]}'),
                trailing: Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) {
                    setState(() {
                      selectedDate = picked;
                    });
                  }
                },
              ),
              SizedBox(height: 16),

              // Start Time Picker
              ListTile(
                title: Text(startTime == null
                    ? 'Pilih Waktu Mulai'
                    : 'Waktu Mulai: ${startTime!.format(context)}'),
                trailing: Icon(Icons.access_time),
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                  if (picked != null) {
                    setState(() {
                      startTime = picked;
                    });
                  }
                },
              ),
              SizedBox(height: 16),

              // End Time Picker
              ListTile(
                title: Text(endTime == null
                    ? 'Pilih Waktu Selesai'
                    : 'Waktu Selesai: ${endTime!.format(context)}'),
                trailing: Icon(Icons.access_time),
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                  if (picked != null) {
                    setState(() {
                      endTime = picked;
                    });
                  }
                },
              ),
              SizedBox(height: 16),

              // Optional Content Input
              TextFormField(
                controller: contentController,
                decoration: InputDecoration(
                  labelText: 'Konten (Opsional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              SizedBox(height: 24),

              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate() &&
                      selectedDate != null &&
                      startTime != null &&
                      endTime != null) {
                    // Simpan data
                    final id = DateTime.now().millisecondsSinceEpoch.toString();
                    final title = "manual data fill by user";

                    // contoh print
                    print('ID: $id');
                    print('Title: $title');
                    print('Kategori: ${panicStatus == "Iya" ? "Panic" : "Kesehatan"}');
                    print('Tanggal: $selectedDate');
                    print('Jam mulai: ${startTime!.format(context)}');
                    print('Jam selesai: ${endTime!.format(context)}');
                    print('Konten: ${contentController.text}');
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Lengkapi semua field yang wajib')),
                    );
                  }
                },
                child: Text('Simpan Data'),
              )
            ],
          ),
        ),
      ),
    );
  }
}
