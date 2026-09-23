import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppEndpoints {
  AppEndpoints._();

  static String get baseUrl {
    final baseUrl = dotenv.env['BASE_URL'];
    if (baseUrl == null || baseUrl.trim().isEmpty) {
      // Fallback to environment variable or standard localhost
      return const String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: 'http://10.0.2.2:8000/api',
      );
    }
    return baseUrl;
  }

  // Auth endpoints
  static const String customerRegister = '/customer/register';
  static const String customerLogin = '/customer/login';
  static const String customerCompleteProfile = '/customer/complete-profile';

  // Services endpoints
  static const String customerServiceCategories = '/customer/service-categories';

  // Properties endpoints
  static const String customerProperties = '/customer/properties';
  static String customerProperty(int id) => '/customer/properties/$id';
}
