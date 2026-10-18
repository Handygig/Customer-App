import 'package:customer_app/src/data/models/services/service_model.dart';

abstract class ServiceRemoteDataSource {
  Future<List<ServiceModel>> getServices({int? categoryId, String? search});
}
