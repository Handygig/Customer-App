import 'package:dio/dio.dart';
import 'package:customer_app/core/constants/app_endpoints.dart';
import 'package:customer_app/core/errors/auth_exception.dart';
import 'package:customer_app/src/data/data_sources/remote/job_requests/job_request_remote_data_source.dart';
import 'package:customer_app/src/data/models/job_requests/job_request_model.dart';
import 'package:customer_app/src/data/models/job_requests/quotation_model.dart';

class JobRequestRemoteDataSourceImpl implements JobRequestRemoteDataSource {
  final Dio _dio;

  JobRequestRemoteDataSourceImpl(this._dio);

  @override
  Future<List<JobRequestModel>> getJobRequests() async {
    try {
      final response = await _dio.get(AppEndpoints.customerJobRequests);
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
          .map((json) => JobRequestModel.fromJson(json))
          .toList();
    } on DioException catch (error) {
      throw AuthException(_extractErrorMessage(error));
    } catch (error) {
      if (error is AuthException) rethrow;
      throw AuthException('Failed to load job requests: $error');
    }
  }

  @override
  Future<JobRequestModel> getJobRequest(int id) async {
    try {
      final response = await _dio.get(AppEndpoints.customerJobRequest(id));
      final rawData = response.data;
      final Map<String, dynamic> itemJson;

      if (rawData is Map && rawData['data'] is Map) {
        itemJson = Map<String, dynamic>.from(rawData['data'] as Map);
      } else if (rawData is Map) {
        itemJson = Map<String, dynamic>.from(rawData);
      } else {
        throw const AuthException('Invalid response format for job request.');
      }

      return JobRequestModel.fromJson(itemJson);
    } on DioException catch (error) {
      throw AuthException(_extractErrorMessage(error));
    } catch (error) {
      if (error is AuthException) rethrow;
      throw AuthException('Failed to load job request details: $error');
    }
  }

  @override
  Future<JobRequestModel> createJobRequest({
    int? propertyId,
    required int serviceCategoryId,
    required String description,
    required DateTime preferredDate,
    String paymentMethod = 'card',
    int? cardId,
  }) async {
    try {
      final body = JobRequestModel.toStoreJson(
        propertyId: propertyId,
        serviceCategoryId: serviceCategoryId,
        description: description,
        preferredDate: preferredDate,
        paymentMethod: paymentMethod,
        cardId: cardId,
      );

      final response = await _dio.post(
        AppEndpoints.customerJobRequests,
        data: body,
      );

      final rawData = response.data;
      final Map<String, dynamic> itemJson;

      if (rawData is Map && rawData['data'] is Map) {
        itemJson = Map<String, dynamic>.from(rawData['data'] as Map);
      } else if (rawData is Map) {
        itemJson = Map<String, dynamic>.from(rawData);
      } else {
        throw const AuthException(
            'Invalid response format after creating job request.');
      }

      return JobRequestModel.fromJson(itemJson);
    } on DioException catch (error) {
      throw AuthException(_extractErrorMessage(error));
    } catch (error) {
      if (error is AuthException) rethrow;
      throw AuthException('Failed to create job request: $error');
    }
  }

  @override
  Future<void> cancelJobRequest(int id) async {
    try {
      await _dio.post(AppEndpoints.customerJobRequestCancel(id));
    } on DioException catch (error) {
      throw AuthException(_extractErrorMessage(error));
    } catch (error) {
      if (error is AuthException) rethrow;
      throw AuthException('Failed to cancel job request: $error');
    }
  }

  @override
  Future<List<QuotationModel>> getJobRequestQuotations(int id) async {
    try {
      final response =
          await _dio.get(AppEndpoints.customerJobRequestQuotations(id));
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
          .map((json) => QuotationModel.fromJson(json))
          .toList();
    } on DioException catch (error) {
      throw AuthException(_extractErrorMessage(error));
    } catch (error) {
      if (error is AuthException) rethrow;
      throw AuthException('Failed to load quotations: $error');
    }
  }

  @override
  Future<void> acceptQuotation(int quotationId) async {
    try {
      await _dio.post(AppEndpoints.customerQuotationAccept(quotationId));
    } on DioException catch (error) {
      throw AuthException(_extractErrorMessage(error));
    } catch (error) {
      if (error is AuthException) rethrow;
      throw AuthException('Failed to accept quotation: $error');
    }
  }

  @override
  Future<QuotationModel> simulateQuotation(int jobRequestId) async {
    try {
      final response = await _dio.post(
        AppEndpoints.customerJobRequestSimulateQuotation(jobRequestId),
      );
      final rawData = response.data;
      final Map<String, dynamic> itemJson;
      if (rawData is Map && rawData['quotation'] is Map) {
        itemJson = Map<String, dynamic>.from(rawData['quotation'] as Map);
      } else if (rawData is Map && rawData['data'] is Map) {
        itemJson = Map<String, dynamic>.from(rawData['data'] as Map);
      } else if (rawData is Map) {
        itemJson = Map<String, dynamic>.from(rawData);
      } else {
        throw const FormatException('Invalid quotation response format');
      }

      return QuotationModel.fromJson(itemJson);
    } on DioException catch (error) {
      throw AuthException(_extractErrorMessage(error));
    } catch (error) {
      if (error is AuthException) rethrow;
      throw AuthException('Failed to simulate quotation: $error');
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

    return 'Job request operation failed. Please try again.';
  }
}
