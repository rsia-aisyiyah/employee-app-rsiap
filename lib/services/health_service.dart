import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:get_storage/get_storage.dart';
import 'package:health/health.dart';
import 'package:intl/intl.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';

class HealthService {
  // Pedometer for Android fallback (hardware step sensor)
  static StreamSubscription<StepCount>? _stepSubscription;
  static final GetStorage _box = GetStorage();
  static bool _isListening = false;

  // Health instance for Health Connect (Android) and Apple HealthKit (iOS)
  static final Health _health = Health();

  // iOS: Apple HealthKit / Apple Watch
  static final List<HealthDataType> _iosHealthTypes = [
    HealthDataType.STEPS,
    HealthDataType.HEART_RATE,
    HealthDataType.SLEEP_ASLEEP,
    HealthDataType.SLEEP_AWAKE,
    HealthDataType.BLOOD_OXYGEN,
  ];

  /// Initialize sensors on app start
  static Future<void> init() async {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      try {
        _health.configure();
      } catch (e) {
        debugPrint("Health configure error: $e");
      }
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      try {
        var status = await Permission.activityRecognition.status;
        if (status.isGranted) {
          _startListening();
        }
      } catch (e) {
        debugPrint("Error initializing Android pedometer: $e");
      }
    }
  }

  /// Request authorization depending on platform
  static Future<bool> requestPermissions() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      try {
        var actStatus = await Permission.activityRecognition.request();
        if (actStatus.isGranted) {
          _startListening();
          return true;
        }
      } catch (e) {
        debugPrint("Android activity recognition request error: $e");
      }
      return false;
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      try {
        _health.configure();
        bool? hasPermission = await _health.hasPermissions(_iosHealthTypes);
        if (hasPermission == true) return true;
        return await _health.requestAuthorization(_iosHealthTypes);
      } catch (e) {
        debugPrint("iOS Apple HealthKit permission error: $e");
        return false;
      }
    }
    return false;
  }

  // ==========================================
  // ANDROID: Pedometer & Health Connect (STEPS ONLY)
  // ==========================================
  static void _startListening() {
    if (_isListening) return;
    try {
      _isListening = true;
      _stepSubscription = Pedometer.stepCountStream.listen(
        _onStepCount,
        onError: (error) {
          debugPrint("Pedometer stream error: $error");
          _isListening = false;
        },
        cancelOnError: false,
      );
      debugPrint("Android pedometer listening started.");
    } catch (e) {
      debugPrint("Could not start pedometer stream: $e");
      _isListening = false;
    }
  }

  /// Stop pedometer listener if needed
  static void stopListening() {
    _stepSubscription?.cancel();
    _stepSubscription = null;
    _isListening = false;
  }

  static void _onStepCount(StepCount event) {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final lastDate = _box.read('pedometer_last_date');
    final rawSteps = event.steps;

    if (lastDate != today) {
      _box.write('pedometer_last_date', today);
      _box.write('pedometer_baseline_offset', rawSteps);
      _box.write('pedometer_today_steps', 0);
    } else {
      int baseline = _box.read('pedometer_baseline_offset') ?? rawSteps;
      if (rawSteps < baseline) {
        baseline = 0;
        _box.write('pedometer_baseline_offset', 0);
      }
      int todaySteps = rawSteps - baseline;
      _box.write('pedometer_today_steps', todaySteps);
    }
  }

  static Future<Map<String, dynamic>> _fetchAndroidHealthData(DateTime midnight, DateTime now) async {
    int totalSteps = 0;
    const String sumberDevice = "Sensor Pedometer HP";

    // Read steps from hardware pedometer
    _startListening();
    await Future.delayed(const Duration(milliseconds: 350));
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final lastDate = _box.read('pedometer_last_date');
    if (lastDate == today) {
      totalSteps = _box.read('pedometer_today_steps') ?? 0;
    }

    double distanceKm = double.parse((totalSteps * 0.00075).toStringAsFixed(2));
    int activeCalories = (totalSteps * 0.04).toInt();
    int activeMinutes = (totalSteps / 100).toInt();

    return {
      'jumlah_langkah': totalSteps,
      'jarak_km': distanceKm,
      'kalori_aktif': activeCalories,
      'menit_aktif': activeMinutes,
      'detak_jantung_avg': null,
      'detak_jantung_max': null,
      'detak_jantung_resting': null,
      'durasi_tidur_menit': null,
      'tidur_nyenyak_menit': 0,
      'tidur_rem_menit': 0,
      'spo2_avg': null,
      'sumber_device': sumberDevice,
      'has_real_sensor_data': totalSteps > 0,
      'status_log': "Sensor Pedometer HP: $totalSteps langkah.",
    };
  }

  // ==========================================
  // IOS: Apple HealthKit / Apple Watch
  // ==========================================
  static Future<Map<String, dynamic>> _fetchIosAppleHealthData(DateTime midnight, DateTime now) async {
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
      statusLog += "Apple HealthKit Authorized: $authorized. ";

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
        debugPrint("Error fetching Apple Health steps: $e");
      }

      try {
        List<HealthDataPoint> dataPoints = await _health.getHealthDataFromTypes(
          types: _iosHealthTypes,
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
        debugPrint("Error fetching Apple Health points: $e");
      }
    } catch (e) {
      statusLog += "Global Err: $e. ";
      debugPrint("Apple HealthService fetch error: $e");
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
      'sumber_device': 'Apple Watch / HealthKit',
      'has_real_sensor_data': totalSteps > 0 || totalSleepMinutes > 0 || avgHeartRate > 0,
      'status_log': statusLog,
    };
  }

  /// Universal entry point for both platforms
  static Future<Map<String, dynamic>> fetchTodayHealthData() async {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return await _fetchIosAppleHealthData(midnight, now);
    } else {
      return await _fetchAndroidHealthData(midnight, now);
    }
  }
}
