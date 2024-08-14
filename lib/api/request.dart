import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:rsia_employee_app/config/config.dart';
import 'package:get_storage/get_storage.dart';

class Api {
  var token;

  _getToken() async {
    final box = GetStorage();
    token = await box.read('token');
  }

  auth(data, pathUrl) async {
    var fullUrl = apiUrl + pathUrl;
    return await http.post(Uri.parse(fullUrl),
        body: jsonEncode(data), headers: _setHeaders());
  }

  getData(pathUrl) async {
    var fullUrl = apiUrl + pathUrl;
    await _getToken();
    return await http.get(Uri.parse(fullUrl), headers: _setHeaders());
  }

  postRequest(pathUrl) async {
    var fullUrl = apiUrl + pathUrl;
    await _getToken();
    return await http.post(Uri.parse(fullUrl), headers: _setHeaders());
  }

  postData(data, pathUrl) async {
    var fullUrl = apiUrl + pathUrl;
    await _getToken();
    return await http.post(
      Uri.parse(fullUrl),
      body: jsonEncode(data),
      headers: _setHeaders(),
    );
  }

  deleteData(data, pathUrl) async {
    var fullUrl = apiUrl + pathUrl;
    await _getToken();
    return await http.delete(
      Uri.parse(fullUrl),
      body: jsonEncode(data),
      headers: _setHeaders(),
    );
  }

  getFullUrl(fullUrl) async {
    await _getToken();
    return await http.get(
      Uri.parse(fullUrl),
      headers: _setHeaders(),
    );
  }

  postFullUrl(data, fullUrl) async {
    await _getToken();
    return await http.post(
      Uri.parse(fullUrl),
      body: jsonEncode(data),
      headers: _setHeaders(),
    );
  }

  getDataUrl(String url) async {
    await _getToken();
    return await http.get(
      Uri.parse(url),
      headers: _setHeaders(),
    );
  }

  _setHeaders() => {
    'Content-type': 'application/json',
    'Accept': 'application/json',
    'Authorization': 'Bearer $token',
  };
}
