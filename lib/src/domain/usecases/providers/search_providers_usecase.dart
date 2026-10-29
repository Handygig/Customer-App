import 'package:dartz/dartz.dart';
import 'package:customer_app/core/errors/failures.dart';
import 'package:customer_app/src/domain/entities/providers/service_provider_entity.dart';
import 'package:customer_app/src/domain/repositories/providers/provider_repository.dart';

class SearchProvidersUseCase {
  final ProviderRepository _repository;

  const SearchProvidersUseCase(this._repository);

  Future<Either<Failure, List<ServiceProviderEntity>>> call({
    double? latitude,
    double? longitude,
    double? radius,
    String? service,
    int? categoryId,
    String? location,
  }) {
    return _repository.searchProviders(
      latitude: latitude,
      longitude: longitude,
      radius: radius,
      service: service,
      categoryId: categoryId,
      location: location,
    );
  }
}
