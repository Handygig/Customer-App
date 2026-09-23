import 'package:customer_app/src/data/models/services/service_category_model.dart';

abstract class ServiceCategoryRemoteDataSource {
  Future<List<ServiceCategoryModel>> getServiceCategories();
}
