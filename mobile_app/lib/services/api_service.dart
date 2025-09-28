import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

import '../config/app_config.dart';
import '../models/category.dart';
import '../models/prompt.dart';

class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? message;
  final String? error;
  final Map<String, dynamic>? pagination;

  const ApiResponse({
    required this.success,
    this.data,
    this.message,
    this.error,
    this.pagination,
  });

  factory ApiResponse.fromJson(Map<String, dynamic> json, T Function(dynamic)? fromJsonT) {
    return ApiResponse<T>(
      success: json['success'] ?? false,
      data: json['data'] != null && fromJsonT != null ? fromJsonT(json['data']) : json['data'],
      message: json['message'],
      error: json['error'],
      pagination: json['pagination'],
    );
  }
}

class ApiService {
  static final ApiService _instance = ApiService._internal();
  static ApiService get instance => _instance;
  ApiService._internal();

  late Dio _dio;
  final Logger _logger = Logger();
  String? _authToken;

  void initialize() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConfig.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
      },
    ));

    // Add interceptors
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (_authToken != null) {
          options.headers['Authorization'] = 'Bearer $_authToken';
        }
        _logger.d('${options.method} ${options.path}');
        handler.next(options);
      },
      onResponse: (response, handler) {
        _logger.d('Response: ${response.statusCode} ${response.requestOptions.path}');
        handler.next(response);
      },
      onError: (DioException error, handler) {
        _logger.e('API Error: ${error.requestOptions.path} - ${error.message}');
        handler.next(error);
      },
    ));
  }

  void setAuthToken(String? token) {
    _authToken = token;
  }

  // Helper method to handle API responses
  ApiResponse<T> _handleResponse<T>(
    Response response,
    T Function(dynamic)? fromJsonT,
  ) {
    try {
      if (response.statusCode == 200 || response.statusCode == 201) {
        return ApiResponse.fromJson(response.data, fromJsonT);
      } else {
        return ApiResponse<T>(
          success: false,
          error: 'HTTP ${response.statusCode}',
        );
      }
    } catch (e) {
      return ApiResponse<T>(
        success: false,
        error: e.toString(),
      );
    }
  }

  // Helper method to handle API errors
  ApiResponse<T> _handleError<T>(DioException error) {
    String errorMessage = 'Network error';
    
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      errorMessage = 'Connection timeout';
    } else if (error.type == DioExceptionType.connectionError) {
      errorMessage = 'Connection error';
    } else if (error.response != null) {
      final responseData = error.response!.data;
      if (responseData is Map<String, dynamic>) {
        errorMessage = responseData['message'] ?? responseData['error'] ?? errorMessage;
      }
    }

    return ApiResponse<T>(
      success: false,
      error: errorMessage,
    );
  }

  // Health check
  Future<ApiResponse<Map<String, dynamic>>> healthCheck() async {
    try {
      final response = await _dio.get('/health');
      return _handleResponse(response, null);
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  // Version check
  Future<ApiResponse<Map<String, dynamic>>> getVersion() async {
    try {
      final response = await _dio.get('/version');
      return _handleResponse(response, null);
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  // Categories API
  Future<ApiResponse<List<Category>>> getCategories({
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final response = await _dio.get('/categories', queryParameters: {
        'page': page,
        'limit': limit,
      });
      
      return _handleResponse(response, (data) {
        return (data as List).map((json) => Category.fromJson(json)).toList();
      });
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse<List<Category>>> getCategoriesWithCounts() async {
    try {
      final response = await _dio.get('/categories/with-counts');
      
      return _handleResponse(response, (data) {
        return (data as List).map((json) => Category.fromJson(json)).toList();
      });
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse<Category>> getCategoryById(String id) async {
    try {
      final response = await _dio.get('/categories/$id');
      return _handleResponse(response, (data) => Category.fromJson(data));
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  // Prompts API
  Future<ApiResponse<List<Prompt>>> getPrompts({
    int page = 1,
    int limit = 20,
    String? categoryId,
    String? search,
    List<String>? tags,
    List<String>? excludeTags,
    String? updatedAfter,
    String sortBy = 'updated_at',
    String sortOrder = 'DESC',
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
        'sortBy': sortBy,
        'sortOrder': sortOrder,
      };

      if (categoryId != null) queryParams['categoryId'] = categoryId;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (tags != null && tags.isNotEmpty) queryParams['tags'] = tags.join(',');
      if (excludeTags != null && excludeTags.isNotEmpty) queryParams['excludeTags'] = excludeTags.join(',');
      if (updatedAfter != null) queryParams['updatedAfter'] = updatedAfter;

      final response = await _dio.get('/prompts', queryParameters: queryParams);
      
      return _handleResponse(response, (data) {
        return (data as List).map((json) => Prompt.fromJson(json)).toList();
      });
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse<Prompt>> getPromptById(String id) async {
    try {
      final response = await _dio.get('/prompts/$id');
      return _handleResponse(response, (data) => Prompt.fromJson(data));
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse<List<Prompt>>> getRecentlyUsedPrompts({int limit = 10}) async {
    try {
      final response = await _dio.get('/prompts/recent', queryParameters: {
        'limit': limit,
      });
      
      return _handleResponse(response, (data) {
        return (data as List).map((json) => Prompt.fromJson(json)).toList();
      });
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> incrementUsageCount(String promptId) async {
    try {
      final response = await _dio.put('/prompts/$promptId/usage');
      return _handleResponse(response, null);
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> parseVariables(String body) async {
    try {
      final response = await _dio.post('/prompts/parse-variables', data: {
        'body': body,
      });
      return _handleResponse(response, null);
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  // Import/Export API
  Future<ApiResponse<Map<String, dynamic>>> exportData({
    bool categories = true,
    bool prompts = true,
    String? categoryId,
  }) async {
    try {
      final response = await _dio.get('/export', queryParameters: {
        'categories': categories,
        'prompts': prompts,
        if (categoryId != null) 'categoryId': categoryId,
      });
      return _handleResponse(response, null);
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> validateImportData(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/validate-import', data: {
        'data': data,
      });
      return _handleResponse(response, null);
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  // Connectivity check
  Future<bool> isConnected() async {
    try {
      final response = await _dio.get('/health');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Test connection with timeout
  Future<bool> testConnection({Duration timeout = const Duration(seconds: 5)}) async {
    try {
      final response = await _dio.get(
        '/health',
        options: Options(
          receiveTimeout: timeout,
          sendTimeout: timeout,
        ),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}