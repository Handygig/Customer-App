import 'package:customer_app/src/data/models/providers/service_provider_model.dart';

abstract class ProviderRemoteDataSource {
  Future<List<ServiceProviderModel>> searchProviders({
    double? latitude,
    double? longitude,
    double? radius,
    String? service,
    int? categoryId,
    String? location,
  });
}
