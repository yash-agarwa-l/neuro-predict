import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:mlapp/services/server.dart';
import 'package:mlapp/services/token.dart';

import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, {this.statusCode});

  @override
  String toString() {
    return "ApiException: $message (Status code: $statusCode)";
  }
}

class ApiService {

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

  static Future<List<dynamic>> getPredictionHistory() async {
    var url = Uri.parse('$serverUrl/predictions/history');
    try {
      final headers = await _getAuthenticatedHeaders();
      var response = await http
          .get(
            url,
            headers: headers,
          )
          .timeout(const Duration(seconds: 30));

      final responseBody = json.decode(response.body);

      if (response.statusCode == 200) {
        return responseBody['data'] as List<dynamic>;
      } else {
        final message = responseBody['message'] ?? "Failed to get history";
        throw ApiException(message, statusCode: response.statusCode);
      }
    } on SocketException {
      throw ApiException("Network error: Please check your internet connection.");
    } on TimeoutException {
      throw ApiException("Request timed out. The server might be busy.");
    } on FormatException {
      throw ApiException("Failed to parse server response.");
    } catch (e) {
      print("Error in getPredictionHistory: $e");
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> getNeuroPredictions(
      Map<String, dynamic> features) async {
    var url = Uri.parse('$mlServerUrl/predict');
    try {
      final headers = await _getAuthenticatedHeaders();
      var response = await http
          .post(
            url,
            headers: headers,
            body: json.encode(features),
          )
          .timeout(const Duration(seconds: 30));

      final responseBody = json.decode(response.body);

      if (response.statusCode == 200) {
        print("Raw API Response: $responseBody");

        final data = responseBody;

        // --- FIXED MAPPING BELOW ---
        // The server returns: {"Alzheimer": {"Risk_Score": 57.33, ...}, ...}
        // You were trying to access: data['alzheimer_risk_score'] which is null.

        return {
          "Alzheimer": {
            "Risk_Score": data['Alzheimer']?['Risk_Score'],
            "Risk_Stage": data['Alzheimer']?['Risk_Stage']
          },
          "Parkinson": {
            "Risk_Score": data['Parkinson']?['Risk_Score'],
            "Risk_Stage": data['Parkinson']?['Risk_Stage']
          },
          "Stress": {
            "Risk_Score": data['Stress']?['Risk_Score'],
            "Risk_Stage": data['Stress']?['Risk_Stage']
          }
        };
      } else {
        final message = responseBody['message'] ?? "Failed to get predictions";
        throw ApiException(message, statusCode: response.statusCode);
      }
    } on SocketException {
      throw ApiException("Network error: Please check your internet connection.");
    } on TimeoutException {
      throw ApiException("Request timed out. The server might be busy.");
    } on FormatException {
      throw ApiException("Failed to parse server response.");
    } catch (e) {
      print("Error in getNeuroPredictions: $e");
      rethrow;
    }
  }

  static Future<File> getNeuroReport(Map<String, dynamic> features) async {
    var status = await Permission.storage.request();

    var url = Uri.parse('$mlServerUrl/report');

    try {
      final headers = await _getAuthenticatedHeaders();
      var response = await http
          .post(
            url,
            headers: headers,
            body: json.encode(features),
          )
          .timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        Directory? directory = await getExternalStorageDirectory();
        if (directory == null) {
          throw ApiException("Could not find storage directory.");
        }

        String timestamp = DateTime.now().millisecondsSinceEpoch.toString();

        String filePath = '${directory.path}/NeuroPredict_Report_$timestamp.pdf';

        File pdfFile = File(filePath);
        await pdfFile.writeAsBytes(response.bodyBytes);

        print('PDF downloaded successfully to $filePath');
        return pdfFile;
      } else {
        var errorBody;
        try {
          errorBody = json.decode(response.body);
        } catch (e) {
          throw ApiException("Failed to download report", statusCode: response.statusCode);
        }
        throw ApiException(errorBody['message'] ?? "Failed to download report",
            statusCode: response.statusCode);
      }
    } on SocketException {
      throw ApiException("Network error: Please check your internet connection.");
    } on TimeoutException {
      throw ApiException("Request timed out. Report generation took too long.");
    } on FileSystemException {
      throw ApiException("Failed to save PDF to device storage.");
    } catch (e) {
      print("Error in getNeuroReport: $e");
      rethrow;
    }
  }
}