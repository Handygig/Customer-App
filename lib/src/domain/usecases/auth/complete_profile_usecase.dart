import 'package:dartz/dartz.dart';
import 'package:customer_app/core/errors/failures.dart';
import 'package:customer_app/src/domain/entities/auth/user_entity.dart';
import 'package:customer_app/src/domain/repositories/auth/auth_repository.dart';

class CompleteProfileUsecase {
  final AuthRepository _repository;

  const CompleteProfileUsecase(this._repository);

  Future<Either<Failure, UserEntity>> call({
    required String firstName,
    required String lastName,
    required String email,
    required String gender,
    String? profileImagePath,
  }) {
    return _repository.completeProfile(
      firstName: firstName,
      lastName: lastName,
      email: email,
      gender: gender,
      profileImagePath: profileImagePath,
    );
  }
}
