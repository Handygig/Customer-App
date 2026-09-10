import 'package:dartz/dartz.dart';
import 'package:customer_app/core/errors/failures.dart';
import 'package:customer_app/src/domain/entities/properties/property_entity.dart';

abstract class PropertyRepository {
  Future<Either<Failure, List<PropertyEntity>>> getProperties();

  Future<Either<Failure, PropertyEntity>> getProperty(int id);

  Future<Either<Failure, PropertyEntity>> addProperty({
    required String label,
    required String addressLine,
    required String city,
    double? latitude,
    double? longitude,
    bool? isDefault,
  });

  Future<Either<Failure, PropertyEntity>> updateProperty({
    required int id,
    String? label,
    String? addressLine,
    String? city,
    double? latitude,
    double? longitude,
    bool? isDefault,
  });

  Future<Either<Failure, void>> deleteProperty(int id);
}
