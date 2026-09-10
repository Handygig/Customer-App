import 'package:dio/dio.dart';
import 'package:customer_app/core/constants/app_endpoints.dart';
import 'package:customer_app/core/errors/auth_exception.dart';
import 'package:customer_app/src/data/data_sources/remote/properties/property_remote_data_source.dart';
import 'package:customer_app/src/data/models/properties/property_model.dart';

class PropertyRemoteDataSourceImpl implements PropertyRemoteDataSource {
  final Dio _dio;

  PropertyRemoteDataSourceImpl(this._dio);

  @override
  Future<List<PropertyModel>> getProperties() async {
    try {
      final response = await _dio.get(AppEndpoints.customerProperties);
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
          .map((json) => PropertyModel.fromJson(json))
          .toList();
    } on DioException catch (error) {
      throw AuthException(_extractErrorMessage(error));
    } catch (error) {
      if (error is AuthException) rethrow;
      throw AuthException('Failed to load properties: $error');
    }
  }

  @override
  Future<PropertyModel> getProperty(int id) async {
    try {
      final response = await _dio.get(AppEndpoints.customerProperty(id));
      final rawData = response.data;
      final Map<String, dynamic> itemJson;

      if (rawData is Map && rawData['data'] is Map) {
        itemJson = Map<String, dynamic>.from(rawData['data'] as Map);
      } else if (rawData is Map) {
        itemJson = Map<String, dynamic>.from(rawData);
      } else {
        throw const AuthException('Invalid response format for property.');
      }

      return PropertyModel.fromJson(itemJson);
    } on DioException catch (error) {
      throw AuthException(_extractErrorMessage(error));
    } catch (error) {
      if (error is AuthException) rethrow;
      throw AuthException('Failed to load property details: $error');
    }
  }

  @override
  Future<PropertyModel> addProperty({
    required String label,
    required String addressLine,
    required String city,
    double? latitude,
    double? longitude,
    bool? isDefault,
  }) async {
    try {
      final body = PropertyModel.toStoreJson(
        label: label,
        addressLine: addressLine,
        city: city,
        latitude: latitude,
        longitude: longitude,
        isDefault: isDefault,
      );

      final response = await _dio.post(
        AppEndpoints.customerProperties,
        data: body,
      );

      final rawData = response.data;
      final Map<String, dynamic> itemJson;

      if (rawData is Map && rawData['data'] is Map) {
        itemJson = Map<String, dynamic>.from(rawData['data'] as Map);
      } else if (rawData is Map) {
        itemJson = Map<String, dynamic>.from(rawData);
      } else {
        throw const AuthException('Invalid response format after creating property.');
      }

      return PropertyModel.fromJson(itemJson);
    } on DioException catch (error) {
      throw AuthException(_extractErrorMessage(error));
    } catch (error) {
      if (error is AuthException) rethrow;
      throw AuthException('Failed to create property: $error');
    }
  }

  @override
  Future<PropertyModel> updateProperty({
    required int id,
    String? label,
    String? addressLine,
    String? city,
    double? latitude,
    double? longitude,
    bool? isDefault,
  }) async {
    try {
      final body = PropertyModel.toUpdateJson(
        label: label,
        addressLine: addressLine,
        city: city,
        latitude: latitude,
        longitude: longitude,
        isDefault: isDefault,
      );

      final response = await _dio.put(
        AppEndpoints.customerProperty(id),
        data: body,
      );

      final rawData = response.data;
      final Map<String, dynamic> itemJson;

      if (rawData is Map && rawData['data'] is Map) {
        itemJson = Map<String, dynamic>.from(rawData['data'] as Map);
      } else if (rawData is Map) {
        itemJson = Map<String, dynamic>.from(rawData);
      } else {
        throw const AuthException('Invalid response format after updating property.');
      }

      return PropertyModel.fromJson(itemJson);
    } on DioException catch (error) {
      throw AuthException(_extractErrorMessage(error));
    } catch (error) {
      if (error is AuthException) rethrow;
      throw AuthException('Failed to update property: $error');
    }
  }

  @override
  Future<void> deleteProperty(int id) async {
    try {
      await _dio.delete(AppEndpoints.customerProperty(id));
    } on DioException catch (error) {
      throw AuthException(_extractErrorMessage(error));
    } catch (error) {
      if (error is AuthException) rethrow;
      throw AuthException('Failed to delete property: $error');
    }
  }

  String _extractErrorMessage(DioException error) {
    final data = error.response?.data;
    if (data is Map) {
      final message = data['message']?.toString().trim();
      if (message != null && message.isNotEmpty) return message;

      final errors = data['errors'];
      if (errors is Map) {
        for (final val in errors.values) {
          if (val is List && val.isNotEmpty) {
            return val.first.toString();
          }
          if (val != null) return val.toString();
        }
      }
    }

    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return 'The server took too long to respond. Please try again.';
    }

    if (error.type == DioExceptionType.connectionError) {
      return 'Unable to connect to the server. Check your internet connection.';
    }

    return 'Property request failed. Please try again.';
  }
}
