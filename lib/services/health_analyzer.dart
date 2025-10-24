import 'package:aura/model/category_model.dart';

class HealthAnalyzer {
  static double? computeHRV(List<int> heartRates) {
    if (heartRates.isEmpty || heartRates.length < 2) return null;
    final diffs = <double>[];
    for (int i = 1; i < heartRates.length; i++) {
      diffs.add((heartRates[i] - heartRates[i - 1]).abs().toDouble());
    }
    return diffs.reduce((a, b) => a + b) / diffs.length;
  }

  static double? computeARMD(List<PanicVariableData> data) {
    final valid = data.where((d) =>
        d.heartRate != null  && d.stress != null);
    if (valid.isEmpty) return null;

    return valid
            .map((d) =>
                (d.heartRate! / 100) +
                (1 - (d.stress! / 100)))
            .reduce((a, b) => a + b) /
        valid.length;
  }
}