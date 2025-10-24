// class HealthDayData {
//   // String id;
//   // String title;
//   String kategori;
//   String time;
//   int? hr;
//   int? steps;

//   HealthDayData(
//     // this.id,
//     this.kategori,
//     this.time,
//     this.hr,
//     this.steps,
//   );

//   Map<String, dynamic> toJson() => {
//     'kategori': kategori,
//     'time': time,
//     'hr': hr,
//     'steps': steps,
//   };
//   factory HealthDayData.fromJson(Map<String, dynamic> json) {
//     return HealthDayData(
//       json['kategori'],
//       json['time'],
//       json['hr'],
//       json['steps'],
//     );
//   }
// }

import 'package:aura/model/category_model.dart';

class HealthDayData {
  // String id;
  // String title;
  String kategori;
  String time;
  ExerciseData? exerciseData;
  PanicVariableData? panicData;

  HealthDayData(
    // this.id,
    this.kategori,
    this.time,
    this.exerciseData,
    this.panicData,
  );

  Map<String, dynamic> toJson() => {
    'kategori': kategori,
    'time': time,
    'exerciseData': exerciseData?.toJson(),
    'panicData': panicData?.toJson(),
  };
  factory HealthDayData.fromJson(Map<String, dynamic> json) => HealthDayData(
    json['kategori'] ?? '',
    json['time'] ?? '',
    json['exerciseData'] != null
        ? ExerciseData.fromJson(Map<String, dynamic>.from(json['exerciseData']))
        : null,
    json['panicData'] != null
        ? PanicVariableData.fromJson(
            Map<String, dynamic>.from(json['panicData']),
          )
        : null,
  );
}
