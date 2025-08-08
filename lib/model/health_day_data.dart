class HealthDayData {
  // String id;
  // String title;
  String kategori;
  String time;
  int? hr;
  int? steps;

  HealthDayData(
    // this.id,
    this.kategori,
    this.time,
    this.hr,
    this.steps,
  );

  Map<String, dynamic> toJson() => {
    'kategori': kategori,
    'time': time,
    'hr': hr,
    'steps': steps,
  };
  factory HealthDayData.fromJson(Map<String, dynamic> json) {
    return HealthDayData(
      json['kategori'],
      json['time'],
      json['hr'],
      json['steps'],
    );
  }
}
