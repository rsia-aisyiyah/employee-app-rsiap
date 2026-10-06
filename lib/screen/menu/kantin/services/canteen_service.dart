import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:get_storage/get_storage.dart';
import 'package:rsia_employee_app/api/request.dart';
import 'package:rsia_employee_app/screen/menu/kantin/models/canteen_model.dart';

class CanteenService {
  static final box = GetStorage();

  static String getEmployeeNik() {
    return (box.read('sub') ?? box.read('nik') ?? '').toString().trim();
  }

  static String getEmployeeName() {
    return (box.read('nama') ?? box.read('name') ?? 'Karyawan RSIA').toString().trim();
  }

  static String getEmployeeDepartment() {
    return (box.read('departemen') ?? box.read('unit') ?? '-').toString().trim();
  }

  /// Ambil Katalog Menu & Kategori Kantin
  static Future<Map<String, dynamic>> fetchMenu({int? categoryId, String? search}) async {
    try {
      String query = '';
      if (categoryId != null && categoryId > 0) {
        query += '?category_id=$categoryId';
      }
      if (search != null && search.isNotEmpty) {
        query += '${query.isEmpty ? '?' : '&'}search=${Uri.encodeComponent(search)}';
      }

      var res = await Api().getData('/kantin/menu$query');
      if (res.statusCode == 200) {
        var body = json.decode(res.body);
        if (body['success'] == true) {
          var catList = (body['categories'] as List? ?? [])
              .map((c) => CanteenCategory.fromJson(c as Map<String, dynamic>))
              .toList();

          var prodList = (body['data'] as List? ?? [])
              .map((p) => CanteenProduct.fromJson(p as Map<String, dynamic>))
              .toList();

          return {
            'categories': catList,
            'products': prodList,
          };
        }
      }
    } catch (e) {
      debugPrint('KantinService::fetchMenu API Error: $e');
    }

    // Fallback data jika server kantin belum aktif atau sedang offline
    return _getFallbackMenu();
  }

  /// Ambil Daftar Lokasi Pengantaran di Lingkungan RSIA
  static Future<List<String>> fetchLocations() async {
    try {
      var res = await Api().getData('/kantin/locations');
      if (res.statusCode == 200) {
        var body = json.decode(res.body);
        if (body['data'] is List) {
          return List<String>.from(body['data'].map((e) => e.toString()));
        }
      }
    } catch (e) {
      debugPrint('KantinService::fetchLocations Error: $e');
    }

    return [
      'Ruang Rawat Inap (Ranap)',
      'Poli Rawat Jalan',
      'IGD',
      'VK / Kamar Bersalin',
      'Ruang Operasi (OK)',
      'Ruang Perinatologi',
      'Farmasi',
      'Laboratorium',
      'Radiologi',
      'Kantor SDI / Manajemen',
      'Ruang IT',
      'Dapur Gizi',
      'Pos Satpam',
      'Lainnya',
    ];
  }

  /// Kirim Pesanan Baru ke Kantin
  static Future<Map<String, dynamic>> submitOrder({
    required String orderType, // 'delivery' or 'pickup'
    required String deliveryLocation,
    required String paymentMethod, // 'bon', 'qris', 'cash'
    required List<CanteenCartItem> items,
    String? notes,
  }) async {
    final nik = getEmployeeNik();
    final name = getEmployeeName();
    final department = getEmployeeDepartment();

    final payload = {
      'nik': nik.isNotEmpty ? nik : 'PEGAWAI-RSIA',
      'name': name,
      'department': department,
      'order_type': orderType,
      'delivery_location': deliveryLocation,
      'payment_method': paymentMethod,
      'notes': notes,
      'items': items.map((i) => i.toJson()).toList(),
    };

    try {
      var res = await Api().postData(payload, '/kantin/orders');
      var body = json.decode(res.body);

      if (res.statusCode == 200 || res.statusCode == 201) {
        if (body['success'] == true) {
          return {
            'success': true,
            'message': body['message'] ?? 'Pesanan berhasil dikirim ke Kantin RSIA!',
            'order': CanteenOrderModel.fromJson(body['data'] as Map<String, dynamic>),
          };
        }
      }
      return {
        'success': false,
        'message': body['message'] ?? 'Gagal membuat pesanan.',
      };
    } catch (e) {
      debugPrint('KantinService::submitOrder Error: $e');
      return {
        'success': false,
        'message': 'Gagal terhubung ke server kantin. Silakan periksa jaringan.',
      };
    }
  }

  /// Ambil Riwayat Pesanan Karyawan
  static Future<List<CanteenOrderModel>> fetchMyOrders() async {
    final nik = getEmployeeNik();
    if (nik.isEmpty) return [];

    try {
      var res = await Api().getData('/kantin/orders/my-orders?nik=$nik');
      if (res.statusCode == 200) {
        var body = json.decode(res.body);
        if (body['success'] == true && body['data'] is List) {
          return (body['data'] as List)
              .map((o) => CanteenOrderModel.fromJson(o as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('KantinService::fetchMyOrders Error: $e');
    }

    return [];
  }

  /// Batalkan Pesanan (Jika masih pending)
  static Future<bool> cancelOrder(String orderNumber, {String? reason}) async {
    try {
      var res = await Api().postData({'reason': reason ?? 'Dibatalkan oleh pemesan'}, '/kantin/orders/$orderNumber/cancel');
      if (res.statusCode == 200) {
        var body = json.decode(res.body);
        return body['success'] == true;
      }
    } catch (e) {
      debugPrint('KantinService::cancelOrder Error: $e');
    }
    return false;
  }

  /// Fallback Katalog Cepat
  static Map<String, dynamic> _getFallbackMenu() {
    final categories = [
      CanteenCategory(id: 1, name: 'Makanan', slug: 'makanan'),
      CanteenCategory(id: 2, name: 'Minuman', slug: 'minuman'),
      CanteenCategory(id: 6, name: 'Snack & Jajan', slug: 'snack'),
    ];

    final products = [
      CanteenProduct(
        id: 1,
        sku: 'MKN-01',
        name: 'Nasi Goreng RSIA Spesial',
        categoryId: 1,
        categoryName: 'Makanan',
        description: 'Nasi goreng harum dengan telur dadar, ayam suwir & kerupuk renyah.',
        priceEmployee: 12000,
        priceRetail: 15000,
        hasDiscount: true,
        trackStock: false,
        stockAvailable: 25,
        isReady: true,
        isConsignment: false,
        baseUnitId: 1,
        baseUnitName: 'Porsi',
      ),
      CanteenProduct(
        id: 2,
        sku: 'MKN-02',
        name: 'Mie Nyemek Telur',
        categoryId: 1,
        categoryName: 'Makanan',
        description: 'Mie kuah nyemek gurih dengan telur rebus dan sayuran segar.',
        priceEmployee: 10000,
        priceRetail: 12000,
        hasDiscount: true,
        trackStock: false,
        stockAvailable: 20,
        isReady: true,
        isConsignment: false,
        baseUnitId: 2,
        baseUnitName: 'Porsi',
      ),
      CanteenProduct(
        id: 3,
        sku: 'MNM-01',
        name: 'Es Teh Manis Segar',
        categoryId: 2,
        categoryName: 'Minuman',
        description: 'Teh melati wangi dan manis alami disajikan dingin segar.',
        priceEmployee: 3000,
        priceRetail: 4000,
        hasDiscount: true,
        trackStock: false,
        stockAvailable: 50,
        isReady: true,
        isConsignment: false,
        baseUnitId: 3,
        baseUnitName: 'Gelas',
      ),
      CanteenProduct(
        id: 4,
        sku: 'MNM-02',
        name: 'Kopi Susu Gula Aren',
        categoryId: 2,
        categoryName: 'Minuman',
        description: 'Kopi mantap dipadukan susu kental creamy & manis gula aren.',
        priceEmployee: 6000,
        priceRetail: 8000,
        hasDiscount: true,
        trackStock: false,
        stockAvailable: 30,
        isReady: true,
        isConsignment: false,
        baseUnitId: 4,
        baseUnitName: 'Cup',
      ),
      CanteenProduct(
        id: 5,
        sku: 'SNK-01',
        name: 'Garuda Crunchy',
        categoryId: 6,
        categoryName: 'Snack & Jajan',
        description: 'Snack jagung renyah gurih cocok untuk teman jaga shift.',
        priceEmployee: 2000,
        priceRetail: 2500,
        hasDiscount: true,
        trackStock: true,
        stockAvailable: 30,
        isReady: true,
        isConsignment: false,
        baseUnitId: 5,
        baseUnitName: 'Bungkus',
      ),
      CanteenProduct(
        id: 6,
        sku: 'SNK-02',
        name: 'Risoles Mayo Daging',
        categoryId: 6,
        categoryName: 'Snack & Jajan',
        description: 'Risoles renyah isi smoked beef, telur & mayonaise lumer.',
        priceEmployee: 3500,
        priceRetail: 4000,
        hasDiscount: true,
        trackStock: true,
        stockAvailable: 15,
        isReady: true,
        isConsignment: true,
        baseUnitId: 6,
        baseUnitName: 'Pcs',
      ),
    ];

    return {
      'categories': categories,
      'products': products,
    };
  }
}
