import 'package:dio/dio.dart';
import 'package:customer_app/core/constants/app_endpoints.dart';
import 'package:customer_app/core/errors/auth_exception.dart';
import 'package:customer_app/src/data/data_sources/remote/payments/payment_remote_data_source.dart';
import 'package:customer_app/src/data/models/payments/card_model.dart';
import 'package:customer_app/src/data/models/payments/payment_model.dart';

class PaymentRemoteDataSourceImpl implements PaymentRemoteDataSource {
  final Dio _dio;

  PaymentRemoteDataSourceImpl(this._dio);

  @override
  Future<List<CardModel>> getCards() async {
    try {
      final response = await _dio.get(AppEndpoints.customerCards);
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
          .map((json) => CardModel.fromJson(json))
          .toList();
    } on DioException catch (error) {
      throw AuthException(_extractErrorMessage(error));
    } catch (error) {
      if (error is AuthException) rethrow;
      throw AuthException('Failed to load payment cards: $error');
    }
  }

  @override
  Future<CardModel> addCard({
    required String cardType,
    required String maskedCardNumber,
    required String expiryDate,
    required String cardHolderName,
    String? billingAddress,
  }) async {
    try {
      final payload = <String, dynamic>{
        'card_type': cardType,
        'masked_card_number': maskedCardNumber,
        'expiry_date': expiryDate,
        'card_holder_name': cardHolderName,
        if (billingAddress != null && billingAddress.trim().isNotEmpty)
          'billing_address': billingAddress.trim(),
      };

      final response = await _dio.post(
        AppEndpoints.customerCards,
        data: payload,
      );

      final rawData = response.data;
      final Map<String, dynamic> itemJson;

      if (rawData is Map && rawData['data'] is Map) {
        itemJson = Map<String, dynamic>.from(rawData['data'] as Map);
      } else if (rawData is Map) {
        itemJson = Map<String, dynamic>.from(rawData);
      } else {
        throw const AuthException('Invalid response format when adding card.');
      }

      return CardModel.fromJson(itemJson);
    } on DioException catch (error) {
      throw AuthException(_extractErrorMessage(error));
    } catch (error) {
      if (error is AuthException) rethrow;
      throw AuthException('Failed to add payment card: $error');
    }
  }

  @override
  Future<void> deleteCard(int cardId) async {
    try {
      await _dio.delete(AppEndpoints.customerCard(cardId));
    } on DioException catch (error) {
      throw AuthException(_extractErrorMessage(error));
    } catch (error) {
      if (error is AuthException) rethrow;
      throw AuthException('Failed to delete payment card: $error');
    }
  }
  @override
  Future<void> setDefaultCard(int cardId) async {
    try {
      await _dio.post(AppEndpoints.customerCardDefault(cardId));
    } on DioException catch (error) {
      if (error.response?.statusCode == 405) {
        try {
          await _dio.put(AppEndpoints.customerCardDefault(cardId));
          return;
        } catch (_) {}
      }
      throw AuthException(_extractErrorMessage(error));
    } catch (error) {
      if (error is AuthException) rethrow;
      throw AuthException('Failed to set default card: $error');
    }
  }

  @override
  Future<void> toggleFreezeCard(int cardId, bool freeze) async {
    try {
      await _dio.post(
        AppEndpoints.customerCardFreeze(cardId),
        data: {'is_frozen': freeze},
      );
    } on DioException catch (error) {
      if (error.response?.statusCode == 405) {
        try {
          await _dio.put(
            AppEndpoints.customerCardFreeze(cardId),
            data: {'is_frozen': freeze},
          );
          return;
        } catch (_) {}
      }
      throw AuthException(_extractErrorMessage(error));
    } catch (error) {
      if (error is AuthException) rethrow;
      throw AuthException('Failed to update card status: $error');
    }
  }


  @override
  Future<PaymentModel> payJobAssignment({
    required int jobAssignmentId,
    required int cardId,
  }) async {
    try {
      final payload = <String, dynamic>{
        'card_id': cardId,
      };

      final response = await _dio.post(
        AppEndpoints.customerJobAssignmentPay(jobAssignmentId),
        data: payload,
      );

      final rawData = response.data;
      final Map<String, dynamic> itemJson;

      if (rawData is Map && rawData['data'] is Map) {
        itemJson = Map<String, dynamic>.from(rawData['data'] as Map);
      } else if (rawData is Map) {
        itemJson = Map<String, dynamic>.from(rawData);
      } else {
        throw const AuthException('Invalid response format when processing payment.');
      }

      return PaymentModel.fromJson(itemJson);
    } on DioException catch (error) {
      throw AuthException(_extractErrorMessage(error));
    } catch (error) {
      if (error is AuthException) rethrow;
      throw AuthException('Failed to process payment: $error');
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

    return 'Payment operation failed. Please try again.';
  }
}
