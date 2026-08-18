import 'package:customer_app/src/domain/entities/auth/auth_result_entity.dart';
import 'package:customer_app/src/domain/repositories/auth/auth_repository.dart';

class LoginWithFirebaseUsecase {
  final AuthRepository _repository;

  const LoginWithFirebaseUsecase(this._repository);

  Future<AuthResultEntity> call() {
    return _repository.loginWithCurrentFirebaseUser();
  }
}
