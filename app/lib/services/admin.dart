import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mlapp/services/preditct.dart';
import 'package:mlapp/services/server.dart';
import 'package:mlapp/services/auth.dart';
import 'package:mlapp/services/token.dart'; // To get token

class AdminApiService {
  
  static Future<Map<String, String>> _getAuthenticatedHeaders() async {
    final token = await AuthLocalDataSource.instance.getAccessToken();
    if (token == null) {
      throw ApiException("Not authorized. Please log in again.");
    }
    return {
      'Content-Type': 'application/json',
      'Authorization': token,
      'ngrok-skip-browser-warning': 'true',
    };
  }

  static Future<List<dynamic>> getAllUsers() async {
    final url = Uri.parse('$serverUrl/admin/users');
    final headers = await _getAuthenticatedHeaders();

    final response = await http.get(
      url,
      headers: headers,
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return json['data']; 
    } else {
      throw Exception("Failed to load users");
    }
  }
}