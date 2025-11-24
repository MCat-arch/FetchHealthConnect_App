

class RawHrModel {
  int bpm;
  List<double>? rrIntervals;
  DateTime time;

  RawHrModel({
    required this.bpm,
    this.rrIntervals,
    required this.time,
  });
}
