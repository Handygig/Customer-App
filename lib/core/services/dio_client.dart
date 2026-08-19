import 'package:dio/dio.dart';
import 'package:customer_app/config/router/app_router.dart';
import 'package:customer_app/config/router/app_routes.dart';
import 'package:customer_app/core/constants/app_endpoints.dart';
import 'package:customer_app/core/constants/app_local_keys.dart';
import 'package:customer_app/core/di/service_locator.dart';
import 'package:customer_app/core/services/auth_manager.dart';
import 'package:customer_app/core/utils/extensions.dart';
import 'package:customer_app/core/utils/snackbar_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class DioClient {
  DioClient._();

  static Dio? _instance;

  static Dio create() {
    _instance = Dio(
      BaseOptions(
        baseUrl: AppEndpoints.baseUrl,
        contentType: Headers.jsonContentType,
        responseType: ResponseType.json,
        headers: {
          'Accept': 'application/json',
        },
        receiveDataWhenStatusError: true,
      ),
    );

    _instance!.interceptors.addAll([
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await AuthManager.getAccessToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          try {
            final storage = sl<FlutterSecureStorage>();
            final langCode =
                await storage.read(key: AppLocalKeys.languageCode) ?? 'en';
            options.headers['locale'] = langCode;
          } catch (e) {
            options.headers['locale'] = 'en';
          }

          handler.next(options);
        },
        onResponse: (response, handler) async {
          final token = await AuthManager.getAccessToken();
          final isAuthPath =
              response.requestOptions.path.contains(
                AppEndpoints.customerLogin,
              ) ||
              response.requestOptions.path.contains(
                AppEndpoints.customerRegister,
              );

          if (token != null && response.statusCode == 401 && !isAuthPath) {
            _handleUnauthorized(response.data);
          }
          handler.next(response);
        },
        onError: (DioException e, handler) async {
          final context = AppRouter.rootNavigatorKey.currentContext;
          final token = await AuthManager.getAccessToken();

          if (e.type == DioExceptionType.connectionTimeout ||
              e.type == DioExceptionType.sendTimeout ||
              e.type == DioExceptionType.receiveTimeout ||
              e.type == DioExceptionType.connectionError ||
              (e.type == DioExceptionType.unknown &&
                  e.message?.contains('SocketException') == true)) {
            final message =
                context?.loc.no_internet_message ?? 'No Internet Connection';

            final networkError = e.copyWith(message: message);
            return handler.next(networkError);
          }

          final isAuthPath =
              e.requestOptions.path.contains(AppEndpoints.customerLogin) ||
              e.requestOptions.path.contains(AppEndpoints.customerRegister);

          if (token != null && e.response?.statusCode == 401 && !isAuthPath) {
            _handleUnauthorized(e.response?.data);
          }
          handler.next(e);
        },
      ),
      _AppLogInterceptor(),
    ]);

    return _instance!;
  }

  static void updateBaseUrl(String newUrl) {
    if (_instance != null) {
      _instance!.options.baseUrl = newUrl;
      debugPrint('DioClient baseUrl updated to: $newUrl');
    }
  }

  static void _handleUnauthorized(dynamic data) async {
    debugPrint('⚠️ [DioClient] Unauthorized (401) — clearing session.');

    final context = AppRouter.rootNavigatorKey.currentContext;
    if (context != null) {
      SnackBarUtils.showError(context, context.loc.unAuthorizedError);
    }
    await AuthManager.logout();
    AppRouter.router.go(AppRoutes.welcome);
  }
}

class _AppLogInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    debugPrint('Dio 🚀 [REQUEST] | ${options.method} | Path: ${options.path}');
    if (options.queryParameters.isNotEmpty) {
      debugPrint('Dio      └─ QueryParameters: ${options.queryParameters}');
    }
    if (options.data != null) {
      debugPrint('Dio      └─ Body: ${options.data}');
    }
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    debugPrint(
      'Dio ✅ [RESPONSE] | ${response.statusCode} | Path: ${response.requestOptions.path}',
    );
    if (response.data != null) {
      final responseStr = response.data.toString();
      final truncatedStr = responseStr.length > 800
          ? '${responseStr.substring(0, 800)}... [truncated]'
          : responseStr;
      debugPrint('Dio      └─ Body: $truncatedStr');
    }
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    debugPrint(
      'Dio ❌ [ERROR] | ${err.response?.statusCode ?? 'No Code'} | Path: ${err.requestOptions.path}',
    );
    if (err.response?.data != null) {
      debugPrint('Dio      └─ Response Body: ${err.response?.data}');
    }
    debugPrint('Dio      └─ Message: ${err.message}');
    super.onError(err, handler);
  }
}
