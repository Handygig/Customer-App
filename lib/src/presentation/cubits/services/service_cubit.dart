import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:customer_app/src/domain/entities/services/service_entity.dart';
import 'package:customer_app/src/domain/usecases/services/get_services_usecase.dart';
import 'package:customer_app/src/presentation/cubits/services/service_state.dart';

class ServiceCubit extends Cubit<ServiceState> {
  final GetServicesUseCase _getServicesUseCase;

  ServiceCubit(this._getServicesUseCase) : super(const ServiceInitial());

  Future<void> loadServices({
    int? categoryId,
    String? search,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && state is ServiceLoaded) {
      return;
    }

    emit(const ServiceLoading());

    final result = await _getServicesUseCase(
      categoryId: categoryId,
      search: search,
    );

    result.fold(
      (failure) => emit(ServiceError(failure.errorMessage)),
      (services) => emit(ServiceLoaded(services)),
    );
  }

  List<ServiceEntity> get services {
    final s = state;
    if (s is ServiceLoaded) return s.services;
    return const [];
  }
}
