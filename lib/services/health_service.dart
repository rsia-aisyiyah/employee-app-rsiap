import 'package:flutter/foundation.dart';
import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';

class HealthService {
  static final Health _health = Health();

  static final List<HealthDataType> _types = [
    HealthDataType.STEPS,
    HealthDataType.HEART_RATE,
    HealthDataType.SLEEP_ASLEEP,
    HealthDataType.SLEEP_AWAKE,
    HealthDataType.BLOOD_OXYGEN,
  ];

  /// Configure Health instance once
  static void configure() {
    try {
      _health.configure();
    } catch (e) {
      debugPrint("Health configure error: $e");
    }
  }

  /// Request authorization from HealthKit / Health Connect
  static Future<bool> requestPermissions() async {
    try {
      configure();

      // Trigger native OS permission dialogs on Android
      if (defaultTargetPlatform == TargetPlatform.android) {
        try {
          await Permission.activityRecognition.request();
          await Permission.sensors.request();

          var status = await _health.getHealthConnectSdkStatus();
          if (status == HealthConnectSdkStatus.sdkUnavailableProviderUpdateRequired) {
            await _health.installHealthConnect();
          }
        } catch (e) {
          debugPrint("Android Health Connect check error: $e");
        }
      }

      bool? hasPermission = await _health.hasPermissions(_types);
      if (hasPermission == true) return true;

      bool authorized = await _health.requestAuthorization(_types);
      return authorized;
    } catch (e) {
      debugPrint("Health authorization error: $e");
      return false;
    }
  }

  /// Fetch today's health metrics from smartwatch / OS health store
  static Future<Map<String, dynamic>> fetchTodayHealthData() async {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);

    int totalSteps = 0;
    double avgHeartRate = 0;
    double restingHeartRate = 0;
    int maxHeartRate = 0;
    int totalSleepMinutes = 0;
    int deepSleepMinutes = 0;
    int remSleepMinutes = 0;
    double? avgSpo2;
    String statusLog = "";

    try {
      bool authorized = await requestPermissions();
      statusLog += "Permission Authorized: $authorized. ";

      // Always try fetching steps even if HealthConnect authorization is partial
      try {
        int? steps = await _health.getTotalStepsInInterval(midnight, now);
        if (steps != null && steps > 0) {
          totalSteps = steps;
          statusLog += "Steps: $steps. ";
        } else {
          statusLog += "Steps: 0/null. ";
        }
      } catch (e) {
        statusLog += "Steps Err: $e. ";
        debugPrint("Error fetching steps: $e");
      }

      // Fetch Health Data Points (Heart Rate, Sleep, SpO2)
      try {
        List<HealthDataPoint> dataPoints = await _health.getHealthDataFromTypes(
          types: _types,
          startTime: midnight,
          endTime: now,
        );

        statusLog += "DataPoints count: ${dataPoints.length}. ";

        List<double> hrValues = [];
        for (var point in dataPoints) {
          if (point.type == HealthDataType.HEART_RATE) {
            if (point.value is NumericHealthValue) {
              double val = (point.value as NumericHealthValue).numericValue.toDouble();
              hrValues.add(val);
            }
          } else if (point.type == HealthDataType.SLEEP_ASLEEP) {
            int durationMin = point.dateTo.difference(point.dateFrom).inMinutes;
            totalSleepMinutes += durationMin;
          } else if (point.type == HealthDataType.BLOOD_OXYGEN) {
            if (point.value is NumericHealthValue) {
              avgSpo2 = (point.value as NumericHealthValue).numericValue.toDouble();
            }
          }
        }

        if (hrValues.isNotEmpty) {
          avgHeartRate = hrValues.reduce((a, b) => a + b) / hrValues.length;
          maxHeartRate = hrValues.reduce((a, b) => a > b ? a : b).toInt();
          restingHeartRate = hrValues.reduce((a, b) => a < b ? a : b);
        }
      } catch (e) {
        statusLog += "Points Err: $e. ";
        debugPrint("Error fetching health points: $e");
      }
    } catch (e) {
      statusLog += "Global Err: $e. ";
      debugPrint("HealthService fetch error: $e");
    }

    double distanceKm = double.parse((totalSteps * 0.00075).toStringAsFixed(1));
    int activeCalories = (totalSteps * 0.04).toInt();
    int activeMinutes = (totalSteps / 100).toInt();

    return {
      'jumlah_langkah': totalSteps,
      'jarak_km': distanceKm,
      'kalori_aktif': activeCalories,
      'menit_aktif': activeMinutes,
      'detak_jantung_avg': avgHeartRate > 0 ? avgHeartRate.round() : null,
      'detak_jantung_max': maxHeartRate > 0 ? maxHeartRate : null,
      'detak_jantung_resting': restingHeartRate > 0 ? restingHeartRate.round() : null,
      'durasi_tidur_menit': totalSleepMinutes > 0 ? totalSleepMinutes : null,
      'tidur_nyenyak_menit': deepSleepMinutes,
      'tidur_rem_menit': remSleepMinutes,
      'spo2_avg': avgSpo2,
      'sumber_device': defaultTargetPlatform == TargetPlatform.iOS ? 'Apple Watch / HealthKit' : 'Smartwatch / Health Connect',
      'has_real_sensor_data': totalSteps > 0 || totalSleepMinutes > 0 || avgHeartRate > 0,
      'status_log': statusLog,
    };
  }
}
