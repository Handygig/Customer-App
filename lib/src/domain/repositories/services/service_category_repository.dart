import 'package:dartz/dartz.dart';
import 'package:customer_app/core/errors/failures.dart';
import 'package:customer_app/src/domain/entities/services/service_category_entity.dart';

abstract class ServiceCategoryRepository {
  Future<Either<Failure, List<ServiceCategoryEntity>>> getServiceCategories();
}
