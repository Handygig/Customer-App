import 'package:dartz/dartz.dart';
import 'package:customer_app/core/errors/failures.dart';
import 'package:customer_app/src/domain/entities/providers/service_provider_entity.dart';

abstract class ProviderRepository {
  Future<Either<Failure, List<ServiceProviderEntity>>> searchProviders({
    double? latitude,
    double? longitude,
    double? radius,
    String? service,
    int? categoryId,
    String? location,
  });
}
