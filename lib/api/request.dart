import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:rsia_employee_app/config/config.dart';
import 'package:get_storage/get_storage.dart';

class Api {
  var token;
  // Reduced to 15 seconds to be reasonable but safe
  final Duration timeoutDuration = const Duration(seconds: 15);

  _getToken() async {
    final box = GetStorage();
    token = await box.read('token');
  }

  auth(data, pathUrl) async {
    return await _retryWithFallback(() async {
      var fullUrl = apiUrl + pathUrl;
      return await http
          .post(Uri.parse(fullUrl),
              body: jsonEncode(data), headers: _setHeaders())
          .timeout(timeoutDuration);
    });
  }

  /// Retry wrapper that automatically tries alternative URL on failure
  Future<http.Response> _retryWithFallback(
      Future<http.Response> Function() request) async {
    try {
      // Try with current URL
      return await request();
    } catch (e) {
      // If failed, try with alternative URL
      debugPrint('⚠️ Request failed with current URL. Trying alternative...');
      AppConfig.switchToAlternativeUrl();

      try {
        return await request();
      } catch (e2) {
        // Both URLs failed, switch back to original and rethrow
        AppConfig.switchToAlternativeUrl();
        debugPrint('❌ Both URLs failed. Error: $e2');
        rethrow;
      }
    }
  }

  getData(pathUrl) async {
    await _getToken();
    return await _retryWithFallback(() async {
      var fullUrl = apiUrl + pathUrl;
      return await http
          .get(Uri.parse(fullUrl), headers: _setHeaders())
          .timeout(timeoutDuration);
    });
  }

  getGuestData(pathUrl) async {
    return await _retryWithFallback(() async {
      var fullUrl = apiUrl + pathUrl;
      return await http.get(Uri.parse(fullUrl), headers: {
        'Content-type': 'application/json',
        'Accept': 'application/json',
        'X-App-Type': 'mobile',
      }).timeout(timeoutDuration);
    });
  }

  postRequest(pathUrl) async {
    var fullUrl = apiUrl + pathUrl;
    await _getToken();
    return await http
        .post(Uri.parse(fullUrl), headers: _setHeaders())
        .timeout(timeoutDuration);
  }

  postData(data, pathUrl) async {
    var fullUrl = apiUrl + pathUrl;
    await _getToken();
    return await http
        .post(
          Uri.parse(fullUrl),
          body: jsonEncode(data),
          headers: _setHeaders(),
        )
        .timeout(timeoutDuration);
  }

  putData(data, pathUrl) async {
    var fullUrl = apiUrl + pathUrl;
    await _getToken();
    return await http
        .put(
          Uri.parse(fullUrl),
          body: jsonEncode(data),
          headers: _setHeaders(),
        )
        .timeout(timeoutDuration);
  }

  deleteData(data, pathUrl) async {
    var fullUrl = apiUrl + pathUrl;
    await _getToken();
    return await http
        .delete(
          Uri.parse(fullUrl),
          body: jsonEncode(data),
          headers: _setHeaders(),
        )
        .timeout(timeoutDuration);
  }

  getFullUrl(fullUrl) async {
    await _getToken();
    return await http
        .get(
          Uri.parse(fullUrl),
          headers: _setHeaders(),
        )
        .timeout(timeoutDuration);
  }

  postFullUrl(data, fullUrl) async {
    await _getToken();
    return await http
        .post(
          Uri.parse(fullUrl),
          body: jsonEncode(data),
          headers: _setHeaders(),
        )
        .timeout(timeoutDuration);
  }

  getDataUrl(String url) async {
    await _getToken();
    return await http
        .get(
          Uri.parse(url),
          headers: _setHeaders(),
        )
        .timeout(timeoutDuration);
  }

  deleteWitoutData(pathUrl) async {
    var fullUrl = apiUrl + pathUrl;
    await _getToken();
    return await http
        .delete(
          Uri.parse(fullUrl),
          headers: _setHeaders(),
        )
        .timeout(timeoutDuration);
  }

  postMultipart(Map<String, String> fields, File file, String pathUrl,
      {String fieldName = 'file'}) async {
    await _getToken();
    var fullUrl = apiUrl + pathUrl;

    var request = http.MultipartRequest('POST', Uri.parse(fullUrl));
    request.headers.addAll({
      'Authorization': 'Bearer $token',
      'X-App-Type': 'mobile',
      'Accept': 'application/json',
    });

    fields.forEach((key, value) {
      request.fields[key] = value;
    });

    if (await file.exists()) {
      request.files.add(
        await http.MultipartFile.fromPath(fieldName, file.path),
      );
    }

    var stream = await request.send();
    return await http.Response.fromStream(stream);
  }

  _setHeaders() => {
        'Content-type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
        'X-App-Type': 'mobile',
      };
}
