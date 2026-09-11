import 'package:dartz/dartz.dart';
import 'package:customer_app/core/errors/failures.dart';
import 'package:customer_app/src/domain/entities/properties/property_entity.dart';
import 'package:customer_app/src/domain/repositories/properties/property_repository.dart';

class GetPropertiesUseCase {
  final PropertyRepository _repository;

  const GetPropertiesUseCase(this._repository);

  Future<Either<Failure, List<PropertyEntity>>> call() {
    return _repository.getProperties();
  }
}

class GetPropertyUseCase {
  final PropertyRepository _repository;

  const GetPropertyUseCase(this._repository);

  Future<Either<Failure, PropertyEntity>> call(int id) {
    return _repository.getProperty(id);
  }
}

class AddPropertyUseCase {
  final PropertyRepository _repository;

  const AddPropertyUseCase(this._repository);

  Future<Either<Failure, PropertyEntity>> call({
    required String label,
    required String addressLine,
    required String city,
    double? latitude,
    double? longitude,
    bool? isDefault,
  }) {
    return _repository.addProperty(
      label: label,
      addressLine: addressLine,
      city: city,
      latitude: latitude,
      longitude: longitude,
      isDefault: isDefault,
    );
  }
}

class UpdatePropertyUseCase {
  final PropertyRepository _repository;

  const UpdatePropertyUseCase(this._repository);

  Future<Either<Failure, PropertyEntity>> call({
    required int id,
    String? label,
    String? addressLine,
    String? city,
    double? latitude,
    double? longitude,
    bool? isDefault,
  }) {
    return _repository.updateProperty(
      id: id,
      label: label,
      addressLine: addressLine,
      city: city,
      latitude: latitude,
      longitude: longitude,
      isDefault: isDefault,
    );
  }
}

class DeletePropertyUseCase {
  final PropertyRepository _repository;

  const DeletePropertyUseCase(this._repository);

  Future<Either<Failure, void>> call(int id) {
    return _repository.deleteProperty(id);
  }
}
