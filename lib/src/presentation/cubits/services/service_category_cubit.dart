import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:customer_app/src/domain/entities/services/service_category_entity.dart';
import 'package:customer_app/src/domain/usecases/services/get_service_categories_usecase.dart';
import 'package:customer_app/src/presentation/cubits/services/service_category_state.dart';

class ServiceCategoryCubit extends Cubit<ServiceCategoryState> {
  final GetServiceCategoriesUseCase _getServiceCategoriesUseCase;

  ServiceCategoryCubit(this._getServiceCategoriesUseCase)
      : super(const ServiceCategoryInitial());

  Future<void> loadCategories({bool forceRefresh = false}) async {
    if (!forceRefresh && state is ServiceCategoryLoaded) {
      return;
    }

    emit(const ServiceCategoryLoading());

    final result = await _getServiceCategoriesUseCase();
    result.fold(
      (failure) => emit(ServiceCategoryError(failure.errorMessage)),
      (categories) => emit(ServiceCategoryLoaded(categories)),
    );
  }

  List<ServiceCategoryEntity> get categories {
    final s = state;
    if (s is ServiceCategoryLoaded) return s.categories;
    return const [];
  }
}
