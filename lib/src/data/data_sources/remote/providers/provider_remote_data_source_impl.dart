import 'package:dio/dio.dart';
import 'package:customer_app/core/constants/app_endpoints.dart';
import 'package:customer_app/core/errors/auth_exception.dart';
import 'package:customer_app/src/data/data_sources/remote/providers/provider_remote_data_source.dart';
import 'package:customer_app/src/data/models/providers/service_provider_model.dart';

class ProviderRemoteDataSourceImpl implements ProviderRemoteDataSource {
  final Dio _dio;

  ProviderRemoteDataSourceImpl(this._dio);

  @override
  Future<List<ServiceProviderModel>> searchProviders({
    double? latitude,
    double? longitude,
    double? radius,
    String? service,
    int? categoryId,
    String? location,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (latitude != null) queryParams['latitude'] = latitude;
      if (longitude != null) queryParams['longitude'] = longitude;
      if (radius != null && radius > 0) queryParams['radius'] = radius;
      if (service != null && service.trim().isNotEmpty) {
        queryParams['service'] = service.trim();
      }
      if (categoryId != null && categoryId > 0) {
        queryParams['category_id'] = categoryId;
      }
      if (location != null && location.trim().isNotEmpty) {
        queryParams['location'] = location.trim();
      }

      final response = await _dio.get(
        AppEndpoints.customerProviderSearch,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

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
          .map((json) => ServiceProviderModel.fromJson(json))
          .toList();
    } on DioException catch (error) {
      throw AuthException(_extractErrorMessage(error));
    } catch (error) {
      if (error is AuthException) rethrow;
      throw AuthException('Failed to load providers: $error');
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

    return 'Failed to load providers. Please try again.';
  }
}
