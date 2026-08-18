class ApiConfig {
  const ApiConfig._();

  /// Pass your backend URL at run/build time, for example:
  /// flutter run --dart-define=API_BASE_URL=https://example.com/api
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000/api',
  );

  static const String customerRegister = '/customer/register';
  static const String customerLogin = '/customer/login';
  static const String customerCompleteProfile = '/customer/complete-profile';
}
