import 'package:flutter/services.dart';
import 'package:huawei_health/huawei_health.dart';
import 'package:aura/utils/storage_helper.dart';
import 'package:permission_handler/permission_handler.dart';

class HealthDataFetcher {
  static final HealthDataFetcher _instance = HealthDataFetcher._();
  factory HealthDataFetcher() => _instance;
  HealthDataFetcher._();

  DataController? _dataController;
  bool _isAuthorized = false;

  // panggil sekali saat app start
  Future<void> init() async {
    if (_dataController != null) return;
    _dataController = await DataController.init();
  }

  Future<void> requestRuntimePermissions() async {
    final activityGranted = await Permission.activityRecognition.request();
    final sensorGranted = await Permission.sensors.request();
    final allGranted = activityGranted.isGranted && sensorGranted.isGranted;
    await StorageHelper.permissionGranted(allGranted);
  }

  /// Pastikan user sudah sign in dan _dataController ter-init
  Future<void> _ensureHuaweiAuthAndController() async {
    if (!_isAuthorized) {
      final List<Scope> scopes = <Scope>[
        Scope.HEALTHKIT_ACTIVITY_READ,
        Scope.HEALTHKIT_BLOODPRESSURE_READ,
        Scope.HEALTHKIT_DISTANCE_READ,
        Scope.HEALTHKIT_HEARTHEALTH_READ,
        Scope.HEALTHKIT_HEARTRATE_READ,
        Scope.HEALTHKIT_BODYTEMPERATURE_READ,
        Scope.HEALTHKIT_STRESS_READ,
        Scope.HEALTHKIT_SLEEP_READ,
        Scope.HEALTHKIT_OXYGENSTATURATION_READ,
        Scope.HEALTHKIT_HISTORYDATA_OPEN_WEEK,
      ];

      try {
        AuthHuaweiId? result = await HealthAuth.signIn(scopes);
        _isAuthorized = true;
        // simpan token kalau perlu
        await StorageHelper.getaAcessToken(result?.accessToken ?? '');
      } on PlatformException catch (e) {
        print("Huawei Auth Error: $e");
        rethrow;
      }
    }

    _dataController ?? await DataController.init();
  }

  /// MENGAMBIL samplePoints dari Huawei Health

  Future<List<SamplePoint>> fetchHuaweiSamples(
    DateTime start,
    DateTime end,
  ) async {
    await _ensureHuaweiAuthAndController();
    final controller = _dataController!;

    final List<DataType> types = [
      DataType.DT_CONTINUOUS_STEPS_DELTA,
      DataType.DT_CONTINUOUS_DISTANCE_DELTA,
      // DataType.DT_CONTINUOUS_ACTIVE_TIME,
      DataType.DT_INSTANTANEOUS_HEART_RATE,
      DataType.DT_INSTANTANEOUS_STRESS,
      DataType.DT_VO2MAX,
      DataType.DT_WATER_TEMPERATURE,
      // DataType.DT_INSTANTANEOUS_BODY_TEMPERATURE,
      // DataType.DT_INSTANTANEOUS_SPO2,
      // DataType.DT_INSTANTANEOUS_BLOOD_PRESSURE,
    ];

    final List<SamplePoint> allPoints = [];

    for (final type in types) {
      // buat DataCollector untuk tipe ini
      try {
        final collector = DataCollector(
          dataType: type,
          dataGenerateType: DataGenerateType.DATA_TYPE_RAW,
        );

        final readOptions = ReadOptions(
          dataCollectors: <DataCollector>[collector],
          startTime: start,
          endTime: end,
          timeUnit: TimeUnit.MILLISECONDS,
          allowRemoteInquiry: true,
        );

        final ReadReply? reply = await controller.read(readOptions);
        final sampleSets = reply!.sampleSets;
        if (sampleSets != null) {
          for (final s in sampleSets) {
            if (s.samplePoints != null) {
              allPoints.addAll(s.samplePoints);
            }
          }
        }
      } catch (e) {
        print("⚠️ Error reading type $type: $e");
      }
    }
    return allPoints;
  }
}
