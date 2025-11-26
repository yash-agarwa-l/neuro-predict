import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:mlapp/services/server.dart';
import 'package:mlapp/services/token.dart';


class AuthApiException implements Exception {
  final String message;
  final int? statusCode;
  AuthApiException(this.message, {this.statusCode});

  @override
  String toString() {
    return "ApiException: $message (Status code: $statusCode)";
  }
}

class AuthApiService {
  static const String _baseurl = serverUrl;

  static Future<Map<String, dynamic>> login(
      String phoneNo, String password) async {
    var url = Uri.parse('$_baseurl/auth/signin');

    var body = {"email": phoneNo, "password": password};

    try {
      var response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
            },
            body: json.encode(body),
          )
          .timeout(const Duration(seconds: 30));

      final responseBody = json.decode(response.body);

      if (response.statusCode == 200 || response.statusCode == 210) {
        final data = responseBody['data'];
        final String? accessToken = data?['accessToken'];
        final String? refreshToken =
            response.headers['refresh-token'] ?? data?['refreshToken'];

        if (accessToken != null && refreshToken != null) {
          await AuthLocalDataSource.instance
              .saveAuthToken(accessToken, refreshToken);
        } else {
          throw AuthApiException("Login successful but tokens were not provided.",
              statusCode: response.statusCode);
        }

        return responseBody;
      } else {
        final message = responseBody['message'] ?? "An unknown error occurred";
        throw AuthApiException(message, statusCode: response.statusCode);
      }
    } on SocketException {
      throw AuthApiException("Network error: Please check your internet connection.");
    } on TimeoutException {
      throw AuthApiException("Request timed out. The server might be busy.");
    } on FormatException {
      throw AuthApiException("Failed to parse server response.");
    } catch (e) {
      print("Error in login: $e");
      if (e is AuthApiException) rethrow;
      throw AuthApiException("An unknown error occurred: $e");
    }
  }

  static Future<void> logout() async {
    await AuthLocalDataSource.instance.deleteAllTokens();
  }
}