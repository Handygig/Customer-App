import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:customer_app/config/router/app_routes.dart';
import 'package:customer_app/src/presentation/screens/welcome/welcome_screen.dart';
import 'package:customer_app/src/presentation/screens/auth/mobile_number_screen.dart';
import 'package:customer_app/src/presentation/screens/auth/otp_verification_screen.dart';
import 'package:customer_app/src/presentation/screens/auth/customer_details_screen.dart';
import 'package:customer_app/src/presentation/screens/auth/add_properties_screen.dart';
import 'package:customer_app/src/presentation/screens/auth/map_selector_screen.dart';
import 'package:customer_app/src/presentation/screens/main_navigation_screen.dart';


class AppRouter {
  AppRouter._();

  static final rootNavigatorKey = GlobalKey<NavigatorState>();

  static final GoRouter router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutes.welcome,
    routes: [
      GoRoute(
        path: AppRoutes.welcome,
        name: AppRoutes.welcome,
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.mobileNumber,
        name: AppRoutes.mobileNumber,
        builder: (context, state) => const MobileNumberScreen(),
      ),
      GoRoute(
        path: AppRoutes.otpVerification,
        name: AppRoutes.otpVerification,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          final phoneNumber = extra['phoneNumber'] as String;
          final verificationId = extra['verificationId'] as String;
          final forceResendingToken = extra['forceResendingToken'] as int?;
          return OtpVerificationScreen(
            phoneNumber: phoneNumber,
            verificationId: verificationId,
            forceResendingToken: forceResendingToken,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.customerDetails,
        name: AppRoutes.customerDetails,
        builder: (context, state) => const CustomerDetailsScreen(),
      ),
      GoRoute(
        path: AppRoutes.addProperties,
        name: AppRoutes.addProperties,
        builder: (context, state) => const AddPropertiesScreen(),
      ),
      GoRoute(
        path: AppRoutes.mapSelector,
        name: AppRoutes.mapSelector,
        builder: (context, state) => const MapSelectorScreen(),
      ),
      GoRoute(
        path: AppRoutes.mainNavigation,
        name: AppRoutes.mainNavigation,
        builder: (context, state) => const MainNavigationScreen(),
      ),
    ],
  );
}
