import 'package:customer_app/src/data/models/properties/property_model.dart';

abstract class PropertyRemoteDataSource {
  Future<List<PropertyModel>> getProperties();

  Future<PropertyModel> getProperty(int id);

  Future<PropertyModel> addProperty({
    required String label,
    required String addressLine,
    required String city,
    double? latitude,
    double? longitude,
    bool? isDefault,
  });

  Future<PropertyModel> updateProperty({
    required int id,
    String? label,
    String? addressLine,
    String? city,
    double? latitude,
    double? longitude,
    bool? isDefault,
  });

  Future<void> deleteProperty(int id);
}
