import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:rsia_employee_app/api/request.dart';
import 'package:rsia_employee_app/models/inmut_model.dart';

class MutuApi {
  /// Mengambil daftar unit yang terkait dengan user (sebagai PIC atau Validator)
  static Future<List<InmutUnitItem>> getMyUnits({int? bulan, int? tahun}) async {
    try {
      final now = DateTime.now();
      final b = bulan ?? now.month;
      final t = tahun ?? now.year;

      final res = await Api().getData('/indikator-mutu/my-units?bulan=$b&tahun=$t');
      if (res.statusCode == 200) {
        final body = json.decode(res.body);
        if (body['success'] == true && body['data'] is List) {
          return (body['data'] as List)
              .map((e) => InmutUnitItem.fromJson(Map<String, dynamic>.from(e)))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('[MutuApi] Error getMyUnits: $e');
    }
    return [];
  }

  /// Mengambil daftar indikator mutu unit untuk proses validasi bulanan
  static Future<List<InmutValidationItem>> getValidasiList({
    required String depId,
    required int bulan,
    required int tahun,
  }) async {
    try {
      final res = await Api().getData('/indikator-mutu/validasi?dep_id=$depId&bulan=$bulan&tahun=$tahun');
      if (res.statusCode == 200) {
        final body = json.decode(res.body);
        if (body['success'] == true && body['data'] is List) {
          return (body['data'] as List)
              .map((e) => InmutValidationItem.fromJson(Map<String, dynamic>.from(e)))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('[MutuApi] Error getValidasiList: $e');
    }
    return [];
  }

  /// Menyimpan atau memperbarui data validasi bulanan (P2)
  static Future<Map<String, dynamic>> storeValidasi({
    required int idInmut,
    required String depId,
    required int bulan,
    required int tahun,
    required int numValidasi,
    required int denumValidasi,
    required String status,
    String? catatan,
  }) async {
    try {
      final payload = {
        'id_inmut': idInmut,
        'dep_id': depId,
        'bulan': bulan,
        'tahun': tahun,
        'num_validasi': numValidasi,
        'denum_validasi': denumValidasi,
        'status': status,
        'catatan': catatan ?? '',
      };

      final res = await Api().postData(payload, '/indikator-mutu/validasi');
      final body = json.decode(res.body);
      return {
        'success': res.statusCode == 200 && (body['success'] == true),
        'message': body['message'] ?? 'Status: ${res.statusCode}',
        'data': body['data'],
      };
    } catch (e) {
      debugPrint('[MutuApi] Error storeValidasi: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Mengambil data analisa mutu untuk indikator tertentu pada periode bulan YYYY-MM
  static Future<InmutAnalisaItem?> getAnalisa({
    required String depId,
    required String yyyyMm,
    required int idInmut,
  }) async {
    try {
      final res = await Api().getData('/indikator-mutu/analisa?dep_id=$depId&bulan=$yyyyMm&id_inmut=$idInmut');
      if (res.statusCode == 200) {
        final body = json.decode(res.body);
        final list = body['data']?['data'];
        if (list is List && list.isNotEmpty) {
          return InmutAnalisaItem.fromJson(Map<String, dynamic>.from(list.first));
        }
      }
    } catch (e) {
      debugPrint('[MutuApi] Error getAnalisa: $e');
    }
    return null;
  }

  /// Menyimpan analisa mutu bulanan
  static Future<Map<String, dynamic>> storeAnalisa({
    required int idInmut,
    required String analisa,
    required String tindakLanjut,
    required int jmlNum,
    required int jmlDenum,
    required String yyyyMm,
  }) async {
    try {
      final payload = {
        'id_inmut': idInmut,
        'analisa': analisa,
        'tindak_lanjut': tindakLanjut,
        'jml_num': jmlNum,
        'jml_denum': jmlDenum,
        'bulan': yyyyMm,
      };

      final res = await Api().postData(payload, '/indikator-mutu/analisa');
      final body = json.decode(res.body);
      return {
        'success': res.statusCode == 200 && (body['success'] == true),
        'message': body['message'] ?? 'Status: ${res.statusCode}',
        'data': body['data'],
      };
    } catch (e) {
      debugPrint('[MutuApi] Error storeAnalisa: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Mengirim push notification permintaan validasi dari PIC ke Validator
  static Future<Map<String, dynamic>> requestValidation({
    required String depId,
    required int bulan,
    required int tahun,
  }) async {
    try {
      final payload = {
        'dep_id': depId,
        'bulan': bulan,
        'tahun': tahun,
      };

      final res = await Api().postData(payload, '/indikator-mutu/request-validation');
      final body = json.decode(res.body);
      return {
        'success': res.statusCode == 200 && (body['success'] == true),
        'message': body['message'] ?? 'Status: ${res.statusCode}',
      };
    } catch (e) {
      debugPrint('[MutuApi] Error requestValidation: $e');
      return {'success': false, 'message': e.toString()};
    }
  }
}
