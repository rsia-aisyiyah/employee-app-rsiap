import 'dart:convert';
import 'dart:io';
import 'package:get_storage/get_storage.dart';
import 'package:rsia_employee_app/api/request.dart';

class AkreditasiService {
  final _api = Api();
  final _box = GetStorage();

  // ─── BAB ───────────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getBab() async {
    final res = await _api.getData('/akred/bab?limit=100&sort=urutan');
    final body = json.decode(res.body);
    return List<Map<String, dynamic>>.from(body['data'] ?? []);
  }

  // ─── POKJA ─────────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getPokjaByBab(int babId) async {
    final res = await _api.getData('/akred/pokja?bab_id=$babId&limit=100&sort=urutan');
    final body = json.decode(res.body);
    return List<Map<String, dynamic>>.from(body['data'] ?? []);
  }

  Future<List<Map<String, dynamic>>> getAllPokja() async {
    final res = await _api.getData('/akred/pokja?limit=200&sort=urutan');
    final body = json.decode(res.body);
    return List<Map<String, dynamic>>.from(body['data'] ?? []);
  }

  // ─── STANDAR (dengan EP, todos, dokumens sekaligus - 1 request) ────────────

  /// Load standar by pokja dengan semua EP, todos, dan dokumens (satu request).
  /// Pendekatan ini sama seperti rsiap-v2 agar efisien dan data lengkap.
  Future<List<Map<String, dynamic>>> getStandarWithEpByPokja(int pokjaId) async {
    final res = await _api.postData({
      'search': {'value': ''},
      'filters': [
        {'field': 'pokja_id', 'operator': '=', 'value': pokjaId}
      ],
      'sort': [
        {'field': 'urutan', 'direction': 'asc'}
      ],
      'limit': 200,
      'includes': [
        {'relation': 'elemenPenilaians'},
        {'relation': 'elemenPenilaians.todos'},
        {'relation': 'elemenPenilaians.dokumens'},
      ]
    }, '/akred/standar/search');
    final body = json.decode(res.body);
    return List<Map<String, dynamic>>.from(body['data'] ?? []);
  }

  // ─── ELEMEN PENILAIAN (EP) ─────────────────────────────────────────────────

  Future<Map<String, dynamic>> getEpById(int epId) async {
    final res = await _api.getData('/akred/elemen-penilaian/$epId?include=todos,dokumens');
    final body = json.decode(res.body);
    return Map<String, dynamic>.from(body['data'] ?? {});
  }

  Future<List<Map<String, dynamic>>> searchEp(String query) async {
    final res = await _api.postData({
      'search': {'value': query},
      'sort': [
        {'field': 'kode_ep', 'direction': 'asc'}
      ],
      'limit': 50,
      'includes': [
        {'relation': 'todos'},
        {'relation': 'dokumens'},
        {'relation': 'standar'}
      ]
    }, '/akred/elemen-penilaian/search');
    final body = json.decode(res.body);
    return List<Map<String, dynamic>>.from(body['data'] ?? []);
  }

  // ─── TODO / CATATAN ────────────────────────────────────────────────────────

  Future<bool> createTodo(int epId, String text) async {
    final res = await _api.postData({
      'elemen_penilaian_id': epId,
      'todo': text,
      'status': 0,
    }, '/akred/elemen-penilaian-todo');
    return res.statusCode == 200 || res.statusCode == 201;
  }

  Future<bool> updateTodoStatus(int todoId, int status) async {
    final res = await _api.putData({
      'status': status,
    }, '/akred/elemen-penilaian-todo/$todoId');
    return res.statusCode == 200;
  }

  Future<bool> updateTodoText(int todoId, String text) async {
    final res = await _api.putData({
      'todo': text,
    }, '/akred/elemen-penilaian-todo/$todoId');
    return res.statusCode == 200;
  }

  Future<bool> deleteTodo(int todoId) async {
    final res = await _api.deleteWitoutData('/akred/elemen-penilaian-todo/$todoId');
    return res.statusCode == 200;
  }

  // ─── DOKUMEN BUKTI ─────────────────────────────────────────────────────────

  Future<bool> uploadDokumen(int epId, File file, String namaFile) async {
    final res = await _api.postMultipart(
      {
        'elemen_penilaian_id': epId.toString(),
        'nama': namaFile,
      },
      file,
      '/akred/elemen-penilaian-dokumen',
      fieldName: 'file',
    );
    return res.statusCode == 200 || res.statusCode == 201;
  }

  Future<bool> deleteDokumen(int dokumenId) async {
    final res = await _api.deleteWitoutData('/akred/elemen-penilaian-dokumen/$dokumenId');
    return res.statusCode == 200;
  }

  // ─── TIM AKREDITASI & HAK AKSES ────────────────────────────────────────────

  /// Ambil semua anggota tim, filter di frontend berdasarkan NIK/NIP user
  Future<({bool isCoreTeam, Set<int> pokjaIds})> fetchUserAccess() async {
    final nik = _box.read('nik') ?? _box.read('sub') ?? _box.read('id_user');
    if (nik == null) return (isCoreTeam: false, pokjaIds: <int>{});

    final cNik = nik.toString().trim();

    try {
      final res = await _api.getData('/akred/tim?limit=500');
      final body = json.decode(res.body);
      final List<dynamic> all = body['data'] ?? [];

      final members = all.where((m) {
        final mNik = (m['nik'] ?? '').toString().trim();
        final mNip = (m['nip'] ?? '').toString().trim();
        return mNik == cNik || mNip == cNik;
      }).toList();

      bool isCoreTeam = false;
      final Set<int> pokjaIds = {};

      for (final m in members) {
        if (m['pokja_id'] == null) {
          isCoreTeam = true;
        } else {
          pokjaIds.add(int.parse(m['pokja_id'].toString()));
        }
      }

      return (isCoreTeam: isCoreTeam, pokjaIds: pokjaIds);
    } catch (e) {
      return (isCoreTeam: false, pokjaIds: <int>{});
    }
  }
}
