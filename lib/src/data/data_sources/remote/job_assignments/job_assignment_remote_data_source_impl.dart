import 'package:dio/dio.dart';
import 'package:customer_app/core/constants/app_endpoints.dart';
import 'package:customer_app/core/errors/auth_exception.dart';
import 'package:customer_app/src/data/data_sources/remote/job_assignments/job_assignment_remote_data_source.dart';
import 'package:customer_app/src/data/models/job_requests/job_assignment_model.dart';
import 'package:customer_app/src/data/models/job_assignments/review_model.dart';
import 'package:customer_app/src/data/models/job_assignments/dispute_model.dart';

class JobAssignmentRemoteDataSourceImpl
    implements JobAssignmentRemoteDataSource {
  final Dio _dio;

  JobAssignmentRemoteDataSourceImpl(this._dio);

  @override
  Future<List<JobAssignmentModel>> getJobAssignments() async {
    try {
      final response = await _dio.get(AppEndpoints.customerJobAssignments);
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
          .map((json) => JobAssignmentModel.fromJson(json))
          .toList();
    } on DioException catch (error) {
      throw AuthException(_extractErrorMessage(error));
    } catch (error) {
      if (error is AuthException) rethrow;
      throw AuthException('Failed to load job assignments: $error');
    }
  }

  @override
  Future<JobAssignmentModel> getJobAssignment(int id) async {
    try {
      final response = await _dio.get(AppEndpoints.customerJobAssignment(id));
      final rawData = response.data;
      final Map<String, dynamic> itemJson;

      if (rawData is Map && rawData['data'] is Map) {
        itemJson = Map<String, dynamic>.from(rawData['data'] as Map);
      } else if (rawData is Map) {
        itemJson = Map<String, dynamic>.from(rawData);
      } else {
        throw const AuthException(
            'Invalid response format for job assignment.');
      }

      return JobAssignmentModel.fromJson(itemJson);
    } on DioException catch (error) {
      throw AuthException(_extractErrorMessage(error));
    } catch (error) {
      if (error is AuthException) rethrow;
      throw AuthException('Failed to load job assignment details: $error');
    }
  }

  @override
  Future<ReviewModel> submitReview(
    int assignmentId, {
    required int rating,
    String? comment,
  }) async {
    try {
      final payload = <String, dynamic>{
        'rating': rating,
        if (comment != null && comment.trim().isNotEmpty)
          'comment': comment.trim(),
      };

      final response = await _dio.post(
        AppEndpoints.customerJobAssignmentReviews(assignmentId),
        data: payload,
      );

      final rawData = response.data;
      final Map<String, dynamic> itemJson;

      if (rawData is Map && rawData['data'] is Map) {
        itemJson = Map<String, dynamic>.from(rawData['data'] as Map);
      } else if (rawData is Map) {
        itemJson = Map<String, dynamic>.from(rawData);
      } else {
        throw const AuthException('Invalid response format after review.');
      }

      return ReviewModel.fromJson(itemJson);
    } on DioException catch (error) {
      throw AuthException(_extractErrorMessage(error));
    } catch (error) {
      if (error is AuthException) rethrow;
      throw AuthException('Failed to submit review: $error');
    }
  }

  @override
  Future<DisputeModel> submitDispute(
    int assignmentId, {
    required String reason,
  }) async {
    try {
      final response = await _dio.post(
        AppEndpoints.customerJobAssignmentDisputes(assignmentId),
        data: {'reason': reason.trim()},
      );

      final rawData = response.data;
      final Map<String, dynamic> itemJson;

      if (rawData is Map && rawData['data'] is Map) {
        itemJson = Map<String, dynamic>.from(rawData['data'] as Map);
      } else if (rawData is Map) {
        itemJson = Map<String, dynamic>.from(rawData);
      } else {
        throw const AuthException('Invalid response format after dispute.');
      }

      return DisputeModel.fromJson(itemJson);
    } on DioException catch (error) {
      throw AuthException(_extractErrorMessage(error));
    } catch (error) {
      if (error is AuthException) rethrow;
      throw AuthException('Failed to submit dispute: $error');
    }
  }

  @override
  Future<JobAssignmentModel> approveExtraCharge(int assignmentId) async {
    try {
      await _dio.post(
        AppEndpoints.customerJobAssignmentApproveExtra(assignmentId),
      );
      return await getJobAssignment(assignmentId);
    } on DioException catch (error) {
      throw AuthException(_extractErrorMessage(error));
    } catch (error) {
      if (error is AuthException) rethrow;
      throw AuthException('Failed to approve updated quotation: $error');
    }
  }

  @override
  Future<JobAssignmentModel> rejectExtraCharge(int assignmentId) async {
    try {
      await _dio.post(
        AppEndpoints.customerJobAssignmentRejectExtra(assignmentId),
      );
      return await getJobAssignment(assignmentId);
    } on DioException catch (error) {
      throw AuthException(_extractErrorMessage(error));
    } catch (error) {
      if (error is AuthException) rethrow;
      throw AuthException('Failed to decline updated quotation: $error');
    }
  }

  @override
  Future<JobAssignmentModel> simulateExtraQuote(int assignmentId) async {
    try {
      final response = await _dio.post(
        AppEndpoints.customerJobAssignmentSimulateExtraQuote(assignmentId),
      );
      final rawData = response.data;
      final Map<String, dynamic> itemJson;

      if (rawData is Map && rawData['data'] is Map) {
        itemJson = Map<String, dynamic>.from(rawData['data'] as Map);
      } else if (rawData is Map) {
        itemJson = Map<String, dynamic>.from(rawData);
      } else {
        return await getJobAssignment(assignmentId);
      }

      return JobAssignmentModel.fromJson(itemJson);
    } on DioException catch (error) {
      throw AuthException(_extractErrorMessage(error));
    } catch (error) {
      if (error is AuthException) rethrow;
      throw AuthException('Failed to simulate updated quotation: $error');
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

    return 'Job assignment operation failed. Please try again.';
  }
}
