import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:customer_app/config/router/app_routes.dart';
import 'package:customer_app/core/services/auth_manager.dart';
import 'package:customer_app/src/presentation/screens/language/language_selection_screen.dart';
import 'package:customer_app/src/presentation/screens/welcome/welcome_screen.dart';
import 'package:customer_app/src/presentation/screens/auth/mobile_number_screen.dart';
import 'package:customer_app/src/presentation/screens/auth/otp_verification_screen.dart';
import 'package:customer_app/src/presentation/screens/auth/customer_details_screen.dart';
import 'package:customer_app/src/presentation/screens/auth/add_properties_screen.dart';
import 'package:customer_app/src/presentation/screens/auth/map_selector_screen.dart';
import 'package:customer_app/src/presentation/screens/main_navigation_screen.dart';
import 'package:customer_app/src/domain/entities/profile/user_profile.dart';
import 'package:customer_app/src/domain/entities/properties/property_entity.dart';
import 'package:customer_app/src/domain/entities/job_requests/job_request_entity.dart';
import 'package:customer_app/src/domain/entities/job_requests/job_assignment_entity.dart';
import 'package:customer_app/src/presentation/screens/profile/rewards_referral_screen.dart';
import 'package:customer_app/src/presentation/screens/profile/properties_management_screen.dart';
import 'package:customer_app/src/presentation/screens/profile/add_new_property_screen.dart';
import 'package:customer_app/src/presentation/screens/profile/payment_methods_screen.dart';
import 'package:customer_app/src/presentation/screens/profile/add_card_screen.dart';
import 'package:customer_app/src/presentation/screens/profile/edit_profile_screen.dart';
import 'package:customer_app/src/presentation/screens/profile/help_support_screen.dart';
import 'package:customer_app/src/presentation/screens/profile/settings_screen.dart';
import 'package:customer_app/src/presentation/screens/services/all_services_screen.dart';
import 'package:customer_app/src/presentation/screens/jobs/job_details_screen.dart';
import 'package:customer_app/src/presentation/screens/chat/chat_screen.dart';

class AppRouter {
  AppRouter._();

  static final rootNavigatorKey = GlobalKey<NavigatorState>();

  static final GoRouter router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation:
        AuthManager.isLoggedIn ? AppRoutes.mainNavigation : AppRoutes.welcome,
    onException: (context, state, router) {
      final uriString = state.uri.toString();
      if (uriString.contains('firebaseauth') ||
          uriString.contains('link') ||
          uriString.contains('callback')) {
        debugPrint('ℹ️ Handled Firebase Auth redirect deep link: $uriString');
        return;
      }
      debugPrint('⚠️ GoRouter exception for $uriString: ${state.error}');
    },
    routes: [
      GoRoute(
        path: AppRoutes.welcome,
        name: AppRoutes.welcome,
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.languageSelection,
        name: AppRoutes.languageSelection,
        builder: (context, state) => const LanguageSelectionScreen(),
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

      // Profile & Wallet Routes
      GoRoute(
        path: AppRoutes.rewards,
        name: AppRoutes.rewards,
        builder: (context, state) => const RewardsReferralScreen(),
      ),
      GoRoute(
        path: AppRoutes.properties,
        name: AppRoutes.properties,
        builder: (context, state) => const PropertiesManagementScreen(),
      ),
      GoRoute(
        path: AppRoutes.addNewProperty,
        name: AppRoutes.addNewProperty,
        builder: (context, state) {
          final extra = state.extra;
          return AddNewPropertyScreen(
            propertyToEdit: extra is PropertyEntity ? extra : null,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.paymentMethods,
        name: AppRoutes.paymentMethods,
        builder: (context, state) => const PaymentMethodsScreen(),
      ),
      GoRoute(
        path: AppRoutes.addCard,
        name: AppRoutes.addCard,
        builder: (context, state) => const AddCardScreen(),
      ),
      GoRoute(
        path: AppRoutes.editProfile,
        name: AppRoutes.editProfile,
        builder: (context, state) {
          final profile = state.extra as UserProfile?;
          return EditProfileScreen(
            profile: profile ??
                const UserProfile(
                  id: '',
                  firstName: '',
                  lastName: '',
                  email: '',
                  phone: '',
                  gender: GenderType.male,
                  membershipTier: 'Member',
                  rewardPoints: 0,
                  walletBalance: 0.0,
                  referralCode: '',
                  isTwoFactorEnabled: false,
                  languageCode: 'en',
                  pushNotificationsEnabled: true,
                  biometricsEnabled: true,
                  memberSinceYear: '2026',
                ),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.helpSupport,
        name: AppRoutes.helpSupport,
        builder: (context, state) => const HelpSupportScreen(),
      ),
      GoRoute(
        path: AppRoutes.settings,
        name: AppRoutes.settings,
        builder: (context, state) => const SettingsScreen(),
      ),

      // Catalog, Jobs & Chat Routes
      GoRoute(
        path: AppRoutes.allServices,
        name: AppRoutes.allServices,
        builder: (context, state) {
          final extra = state.extra;
          final initialCategory = extra is String
              ? extra
              : (extra is Map ? extra['initialCategory'] as String? : null);
          return AllServicesScreen(initialCategory: initialCategory);
        },
      ),
      GoRoute(
        path: AppRoutes.jobDetails,
        name: AppRoutes.jobDetails,
        builder: (context, state) {
          final extra = state.extra;
          if (extra is JobRequestEntity) {
            return JobDetailsScreen(jobRequest: extra);
          } else if (extra is JobAssignmentEntity) {
            return JobDetailsScreen(jobAssignment: extra);
          } else if (extra is Map<String, dynamic>) {
            return JobDetailsScreen(
              job: extra['job'] as Map<String, dynamic>?,
              jobRequest: extra['jobRequest'] as JobRequestEntity?,
              jobRequestId: extra['jobRequestId'] as int?,
              jobAssignment: extra['jobAssignment'] as JobAssignmentEntity?,
              assignmentId: extra['assignmentId'] as int?,
            );
          } else if (extra is int) {
            return JobDetailsScreen(jobRequestId: extra);
          }
          return const JobDetailsScreen();
        },
      ),
      GoRoute(
        path: AppRoutes.chat,
        name: AppRoutes.chat,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return ChatScreen(
            providerName: extra['providerName'] as String? ?? 'David Miller',
            serviceTitle:
                extra['serviceTitle'] as String? ?? 'Deep Home Sanitization',
            jobId: extra['jobId'] as String? ?? 'JOB-9842',
            providerAvatar: extra['providerAvatar'] as String?,
          );
        },
      ),
    ],
  );
}
