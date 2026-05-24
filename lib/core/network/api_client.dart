import 'package:dio/dio.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class NetworkException extends ApiException {
  NetworkException(super.message);
}

class AuthException extends ApiException {
  AuthException(super.message, {super.statusCode});
}

class ApiClient {
  final Dio _dio;

  ApiClient({Dio? dio}) : _dio = dio ?? Dio(
    BaseOptions(
      baseUrl: 'https://api.kosmo.com/v1',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  // Simulated request helper that mocks network delay and returns mock JSON data
  Future<dynamic> mockGet(String path, {Map<String, dynamic>? mockResponse}) async {
    // Simulate real network delay
    await Future.delayed(const Duration(milliseconds: 600));

    if (mockResponse != null) {
      return mockResponse;
    }
    throw ApiException('Data tidak ditemukan', statusCode: 404);
  }

  // Real request wrapper (ready to point to a backend)
  Future<dynamic> get(String path, {Map<String, dynamic>? queryParameters}) async {
    try {
      final response = await _dio.get(path, queryParameters: queryParameters);
      return response.data;
    } on DioException catch (e) {
      _handleDioException(e);
    }
  }

  void _handleDioException(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      throw NetworkException('Koneksi terputus. Silakan coba lagi.');
    }
    if (e.response != null) {
      final code = e.response!.statusCode;
      if (code == 401 || code == 403) {
        throw AuthException('Sesi Anda telah berakhir. Silakan login kembali.', statusCode: code);
      }
      throw ApiException(
        e.response?.data is Map && e.response?.data['message'] != null
            ? e.response?.data['message']
            : 'Terjadi kesalahan sistem.',
        statusCode: code,
      );
    }
    throw NetworkException('Terjadi kesalahan jaringan.');
  }
}
