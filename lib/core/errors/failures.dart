import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String errorMessage;
  final StackTrace? stackTrace;

  const Failure({required this.errorMessage, this.stackTrace});

  @override
  List<Object?> get props => [errorMessage, stackTrace];
}

class APIFailure extends Failure {
  const APIFailure({required super.errorMessage, super.stackTrace});
}

class DatabaseFailure extends Failure {
  const DatabaseFailure({required super.errorMessage, super.stackTrace});
}

class CacheFailure extends Failure {
  const CacheFailure({required super.errorMessage, super.stackTrace});
}

class NetworkFailure extends Failure {
  const NetworkFailure({required super.errorMessage, super.stackTrace});
}

class CancelledFailure extends Failure {
  const CancelledFailure({
    super.errorMessage = 'Request was cancelled',
    super.stackTrace,
  });
}
