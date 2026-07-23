import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:rsia_employee_app/api/request.dart';

class EbookService {
  final Api _api = Api();

  /// Fetch list of e-books or jurnals with pagination and filters
  Future<Map<String, dynamic>> fetchEbooks({
    int page = 1,
    int perPage = 12,
    String jenis = 'ebook', // 'ebook' or 'jurnal'
    String? kategoriId,
    String? search,
    String sort = 'terbaru',
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'per_page': perPage.toString(),
        'jenis': jenis,
        'sort': sort,
      };

      if (kategoriId != null && kategoriId.isNotEmpty) {
        queryParams['kategori_id'] = kategoriId;
      }
      if (search != null && search.trim().isNotEmpty) {
        queryParams['search'] = search.trim();
      }

      final queryString = Uri(queryParameters: queryParams).query;
      final response = await _api.getData('/sdi/ebook?$queryString');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data['success'] == true) {
          final List<dynamic> rawList = data['data'] ?? [];
          final Map<String, dynamic> pagination = data['pagination'] ?? {
            'current_page': 1,
            'last_page': 1,
            'per_page': perPage,
            'total': rawList.length,
          };

          return {
            'success': true,
            'data': rawList.cast<Map<String, dynamic>>(),
            'pagination': pagination,
          };
        }
      }
      return {'success': false, 'data': <Map<String, dynamic>>[], 'pagination': {}};
    } catch (e) {
      debugPrint('Error fetching ebooks: $e');
      return {'success': false, 'data': <Map<String, dynamic>>[], 'pagination': {}};
    }
  }

  /// Fetch categories for E-Book & Jurnal
  Future<List<Map<String, dynamic>>> fetchCategories() async {
    try {
      final response = await _api.getData('/sdi/ebook/categories');
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data['success'] == true) {
          final List<dynamic> rawList = data['data'] ?? [];
          return rawList.cast<Map<String, dynamic>>();
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching ebook categories: $e');
      return [];
    }
  }

  /// Increment view counter
  Future<bool> incrementView(int id) async {
    try {
      final response = await _api.postData({}, '/sdi/ebook/$id/view');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      debugPrint('Error incrementing view: $e');
      return false;
    }
  }
}
