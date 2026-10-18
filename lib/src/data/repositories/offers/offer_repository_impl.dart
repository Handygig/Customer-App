import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/constants/app_endpoints.dart';
import 'package:customer_app/core/di/service_locator.dart';
import 'package:customer_app/core/errors/failures.dart';
import 'package:customer_app/core/services/dio_client.dart';
import 'package:customer_app/core/services/network_service.dart';
import 'package:customer_app/src/domain/entities/offers/exclusive_offer.dart';
import 'package:customer_app/src/domain/repositories/offers/offer_repository.dart';

class OfferRepositoryImpl implements OfferRepository {
  final Dio _dio;
  final NetworkService? _networkService;

  static OfferRepositoryImpl? _instance;

  factory OfferRepositoryImpl([Dio? dio, NetworkService? networkService]) {
    _instance ??= OfferRepositoryImpl._internal(
      dio ?? (sl.isRegistered<Dio>() ? sl<Dio>() : DioClient.create()),
      networkService ??
          (sl.isRegistered<NetworkService>() ? sl<NetworkService>() : null),
    );
    return _instance!;
  }

  OfferRepositoryImpl._internal(this._dio, this._networkService);

  // In-memory cache of offers fetched from backend
  List<ExclusiveOffer> _cachedOffers = [];

  @override
  Future<Either<Failure, List<ExclusiveOffer>>> getExclusiveOffers() async {
    if (_networkService != null && !await _networkService.isConnected()) {
      return Right(_cachedOffers);
    }

    try {
      dynamic responseData;
      try {
        final response = await _dio.get(AppEndpoints.customerExclusiveOffers);
        responseData = response.data;
      } on DioException catch (dioErr) {
        if (dioErr.response?.statusCode == 401 ||
            dioErr.response?.statusCode == 403 ||
            dioErr.response?.statusCode == 404) {
          debugPrint('ℹ️ [OfferRepositoryImpl] /customer/exclusive-offers gave ${dioErr.response?.statusCode}, trying public /exclusive-offers...');
          final publicResponse = await _dio.get(AppEndpoints.publicExclusiveOffers);
          responseData = publicResponse.data;
        } else {
          rethrow;
        }
      }

      List<dynamic> items = [];
      if (responseData is Map && responseData['data'] is List) {
        items = responseData['data'] as List<dynamic>;
      } else if (responseData is List) {
        items = responseData;
      }

      _cachedOffers = items
          .map((e) => ExclusiveOffer.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();

      debugPrint('✅ [OfferRepositoryImpl.getExclusiveOffers] Loaded ${_cachedOffers.length} offers');
      return Right(_cachedOffers);
    } on DioException catch (e) {
      debugPrint('⚠️ [OfferRepositoryImpl.getExclusiveOffers] DioException: ${e.message}');
      if (_cachedOffers.isNotEmpty) {
        return Right(_cachedOffers);
      }
      final msg = (e.response?.data is Map && e.response?.data['message'] != null)
          ? e.response!.data['message'].toString()
          : (e.message ?? 'Failed to load offers');
      return Left(APIFailure(errorMessage: msg));
    } catch (e, stackTrace) {
      debugPrint('⚠️ [OfferRepositoryImpl.getExclusiveOffers] Error: $e');
      if (_cachedOffers.isNotEmpty) {
        return Right(_cachedOffers);
      }
      return Left(APIFailure(errorMessage: e.toString(), stackTrace: stackTrace));
    }
  }

  @override
  Future<Either<Failure, void>> claimOffer(String code) async {
    try {
      await _dio.post(
        AppEndpoints.customerClaimOffer,
        data: {'code': code},
      );
      return const Right(null);
    } on DioException catch (e) {
      final msg = (e.response?.data is Map && e.response?.data['message'] != null)
          ? e.response!.data['message'].toString()
          : (e.message ?? 'Failed to claim offer');
      return Left(APIFailure(errorMessage: msg));
    } catch (e, stackTrace) {
      return Left(APIFailure(errorMessage: e.toString(), stackTrace: stackTrace));
    }
  }
}
