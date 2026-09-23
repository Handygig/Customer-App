import 'package:dio/dio.dart';
import 'package:customer_app/core/constants/app_endpoints.dart';
import 'package:customer_app/core/errors/auth_exception.dart';
import 'package:customer_app/src/data/data_sources/remote/services/service_category_remote_data_source.dart';
import 'package:customer_app/src/data/models/services/service_category_model.dart';

class ServiceCategoryRemoteDataSourceImpl implements ServiceCategoryRemoteDataSource {
  final Dio _dio;

  ServiceCategoryRemoteDataSourceImpl(this._dio);

  @override
  Future<List<ServiceCategoryModel>> getServiceCategories() async {
    try {
      final response = await _dio.get(AppEndpoints.customerServiceCategories);

      final rawData = response.data;
      final List<dynamic> items;

      if (rawData is Map && rawData['data'] is List) {
        items = rawData['data'] as List;
      } else if (rawData is List) {
        items = rawData;
      } else {
        items = const [];
      }

      return items
          .whereType<Map<String, dynamic>>()
          .map((json) => ServiceCategoryModel.fromJson(json))
          .toList();
    } on DioException catch (error) {
      throw AuthException(_extractErrorMessage(error));
    } catch (error) {
      if (error is AuthException) rethrow;
      throw AuthException('Failed to load service categories: $error');
    }
  }

  String _extractErrorMessage(DioException error) {
    final data = error.response?.data;
    if (data is Map) {
      final message = data['message']?.toString().trim();
      if (message != null && message.isNotEmpty) return message;
    }

    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return 'The server took too long to respond. Please try again.';
    }

    if (error.type == DioExceptionType.connectionError) {
      return 'Unable to connect to the server. Check your internet connection.';
    }

    return 'Failed to load service categories. Please try again.';
  }
}
