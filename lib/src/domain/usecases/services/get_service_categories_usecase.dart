import 'package:dartz/dartz.dart';
import 'package:customer_app/core/errors/failures.dart';
import 'package:customer_app/src/domain/entities/services/service_category_entity.dart';
import 'package:customer_app/src/domain/repositories/services/service_category_repository.dart';

class GetServiceCategoriesUseCase {
  final ServiceCategoryRepository _repository;

  const GetServiceCategoriesUseCase(this._repository);

  Future<Either<Failure, List<ServiceCategoryEntity>>> call() {
    return _repository.getServiceCategories();
  }
}
