import 'package:dartz/dartz.dart';
import 'package:customer_app/core/errors/failures.dart';
import 'package:customer_app/src/domain/entities/services/service_entity.dart';
import 'package:customer_app/src/domain/repositories/services/service_repository.dart';

class GetServicesUseCase {
  final ServiceRepository _repository;

  const GetServicesUseCase(this._repository);

  Future<Either<Failure, List<ServiceEntity>>> call({int? categoryId, String? search}) {
    return _repository.getServices(categoryId: categoryId, search: search);
  }
}
