import 'package:aura/model/category_model.dart';
import 'package:aura/model/health_day_data.dart';
import 'package:flutter/material.dart';
import 'package:huawei_health/huawei_health.dart';

class HealthDataProcessor {
  static HealthDayData mapSampleToDayData(SamplePoint point) {
    final exercise = ExerciseData();
    final panic = PanicVariableData();
    String kategori = '';

    final dt = point.dataType;
    final fv = point.fieldValues;

    switch (point.dataType) {
      case DataType.DT_CONTINUOUS_STEPS_DELTA:
        exercise.dailyActivitySummary = _toDouble(
          fv?[Field.FIELD_STEPS_DELTA].toString(),
        );
        // kategori = 'non_panic';
        break;

      case DataType.DT_CONTINUOUS_DISTANCE_DELTA:
        exercise.distance = _toDouble(fv?[Field.FIELD_DISTANCE]?.toString());
        // kategori = 'non_panic';
        break;

      // case DataType.DT_CONTINUOUS_ACTIVE_TIME:
      //   exercise.activeHours = _toDouble(fv?[Field.FIELD_DURATION]?.toString());
      //   break;

      case DataType.DT_INSTANTANEOUS_HEART_RATE:
        panic.heartRate = _toInt(fv?[Field.FIELD_BPM]?.toString());
        kategori = (panic.heartRate != null && panic.heartRate! > 85)
            ? 'panic'
            : 'normal';
        break;

      case DataType.DT_INSTANTANEOUS_STRESS:
        panic.stress = _toDouble(fv?[Field.STRESS_LAST]?.toString());
        break;

      // case DataType.DT_INSTANTANEOUS_SPO2:
      //   panic.spo2 = _toDouble(point.getFieldValue(Field.FIELD_SPO2));
      //   kategori = 'panic';
      //   break;

      // case DataType.DT_INSTANTANEOUS_BODY_TEMPERATURE:
      //   panic.bodyTemperature = _toDouble(
      //     point.getFieldValue(Field.FIELD_BODY_TEMPERATURE),
      //   );
      //   kategori = 'panic';
      //   break;

      // case DataType.DT_INSTANTANEOUS_BLOOD_PRESSURE:
      //   panic.systolicBP = _toInt(
      //     point.getFieldValue(Field.FIELD_BLOOD_PRESSURE_SYSTOLIC),
      //   );
      //   panic.diastolicBP = _toInt(
      //     point.getFieldValue(Field.FIELD_BLOOD_PRESSURE_DIASTOLIC),
      //   );
      //   kategori = 'panic';
      //   break;

      default:
        kategori = 'non_panic';
    }

    return HealthDayData(
      kategori,
      point.startTime!.toIso8601String(),
      exercise,
      panic,
    );
  }

  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is int) return v.toDouble();
    if (v is double) return v;
    return double.tryParse(v.toString());
  }

  static int? _toInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is double) return v.round();
    return int.tryParse(v.toString());
  }
}
