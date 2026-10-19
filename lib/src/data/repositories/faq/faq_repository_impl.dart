import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:customer_app/core/constants/app_endpoints.dart';
import 'package:customer_app/core/di/service_locator.dart';
import 'package:customer_app/core/errors/failures.dart';
import 'package:customer_app/core/services/dio_client.dart';
import 'package:customer_app/core/services/network_service.dart';
import 'package:customer_app/src/domain/entities/faq/faq_item.dart';
import 'package:customer_app/src/domain/repositories/faq/faq_repository.dart';

class FaqRepositoryImpl implements FaqRepository {
  final Dio _dio;
  final NetworkService? _networkService;

  static FaqRepositoryImpl? _instance;

  factory FaqRepositoryImpl([Dio? dio, NetworkService? networkService]) {
    _instance ??= FaqRepositoryImpl._internal(
      dio ?? (sl.isRegistered<Dio>() ? sl<Dio>() : DioClient.create()),
      networkService ??
          (sl.isRegistered<NetworkService>() ? sl<NetworkService>() : null),
    );
    return _instance!;
  }

  FaqRepositoryImpl._internal(this._dio, this._networkService);

  // In-memory cache
  List<FaqItem> _cachedFaqs = [];

  @override
  Future<Either<Failure, List<FaqItem>>> getFaqs({
    String? category,
    String? search,
  }) async {
    final isOnline = _networkService == null || await _networkService.isConnected();

    if (!isOnline && _cachedFaqs.isNotEmpty) {
      return Right(_filterFaqsLocally(_cachedFaqs, category, search));
    }

    try {
      final queryParams = <String, dynamic>{};
      if (category != null && category.trim().isNotEmpty && category != 'All') {
        queryParams['category'] = category.trim();
      }
      if (search != null && search.trim().isNotEmpty) {
        queryParams['search'] = search.trim();
      }

      dynamic responseData;
      try {
        final response = await _dio.get(
          AppEndpoints.customerFaqs,
          queryParameters: queryParams.isNotEmpty ? queryParams : null,
        );
        responseData = response.data;
      } on DioException catch (dioErr) {
        // Fall back to public endpoint if customer endpoint returns 401/403/404
        if (dioErr.response?.statusCode == 401 ||
            dioErr.response?.statusCode == 403 ||
            dioErr.response?.statusCode == 404) {
          debugPrint(
            'ℹ️ [FaqRepositoryImpl] /customer/faqs returned ${dioErr.response?.statusCode}, trying public /faqs...',
          );
          final publicResponse = await _dio.get(
            AppEndpoints.publicFaqs,
            queryParameters: queryParams.isNotEmpty ? queryParams : null,
          );
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

      final faqs = items
          .map((item) => FaqItem.fromJson(item as Map<String, dynamic>))
          .toList();

      if (category == null && search == null) {
        _cachedFaqs = faqs;
      }

      return Right(faqs);
    } catch (e) {
      debugPrint('⚠️ [FaqRepositoryImpl] Error fetching FAQs: $e');

      // Gracefully fall back to memory cache or baseline default FAQs
      if (_cachedFaqs.isNotEmpty) {
        return Right(_filterFaqsLocally(_cachedFaqs, category, search));
      }

      return Right(_filterFaqsLocally(FaqItem.defaultFaqs, category, search));
    }
  }

  @override
  Future<Either<Failure, List<String>>> getCategories() async {
    try {
      final response = await _dio.get(AppEndpoints.faqCategories);
      final responseData = response.data;

      List<String> categories = [];
      if (responseData is Map && responseData['data'] is List) {
        for (final item in responseData['data']) {
          if (item is Map && item['category'] != null) {
            categories.add(item['category'].toString());
          } else if (item is String) {
            categories.add(item);
          }
        }
      }

      if (categories.isEmpty && _cachedFaqs.isNotEmpty) {
        categories = _cachedFaqs.map((f) => f.category).toSet().toList();
      }

      return Right(categories);
    } catch (e) {
      debugPrint('⚠️ [FaqRepositoryImpl] Error fetching FAQ categories: $e');
      final fallbackCategories = (_cachedFaqs.isNotEmpty ? _cachedFaqs : FaqItem.defaultFaqs)
          .map((f) => f.category)
          .toSet()
          .toList();
      return Right(fallbackCategories);
    }
  }

  List<FaqItem> _filterFaqsLocally(
    List<FaqItem> list,
    String? category,
    String? search,
  ) {
    return list.where((faq) {
      if (!faq.isActive) return false;
      if (category != null && category.isNotEmpty && category != 'All') {
        if (faq.category.toLowerCase() != category.toLowerCase()) return false;
      }
      if (search != null && search.trim().isNotEmpty) {
        final q = search.trim().toLowerCase();
        final matchesQ = faq.question.toLowerCase().contains(q);
        final matchesA = faq.answer.toLowerCase().contains(q);
        if (!matchesQ && !matchesA) return false;
      }
      return true;
    }).toList();
  }
}
