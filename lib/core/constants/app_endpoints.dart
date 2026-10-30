import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppEndpoints {
  AppEndpoints._();

  static String get baseUrl {
    var url = dotenv.env['BASE_URL']?.trim();
    if (url == null || url.isEmpty) {
      url = const String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: 'http://127.0.0.1:8000/api',
      );
    }

    // iOS Simulator cannot reach Android's 10.0.2.2 loopback address
    if (!kIsWeb && Platform.isIOS && url.contains('10.0.2.2')) {
      return url.replaceAll('10.0.2.2', '127.0.0.1');
    }

    // Android Emulator cannot reach host localhost / 127.0.0.1
    if (!kIsWeb && Platform.isAndroid && (url.contains('127.0.0.1') || url.contains('localhost'))) {
      return url.replaceAll('127.0.0.1', '10.0.2.2').replaceAll('localhost', '10.0.2.2');
    }

    return url;
  }

  // Auth endpoints
  static const String customerRegister = '/customer/register';
  static const String customerLogin = '/customer/login';
  static const String customerCompleteProfile = '/customer/complete-profile';
  static const String logout = '/auth/logout';
  static const String userProfile = '/user/profile';

  // Services endpoints
  static const String customerServiceCategories = '/customer/service-categories';
  static const String customerServices = '/customer/services';
  static String customerCategoryServices(int categoryId) =>
      '/customer/service-categories/$categoryId/services';
  static String customerService(int id) => '/customer/services/$id';

  // Provider Search & Locator endpoints
  static const String customerProviderSearch = '/customer/providers/search';
  static const String publicProviderSearch = '/providers/search';

  // Properties endpoints
  static const String customerProperties = '/customer/properties';
  static String customerProperty(int id) => '/customer/properties/$id';

  // Payment Cards & Payments endpoints
  static const String customerCards = '/customer/cards';
  static String customerCard(int id) => '/customer/cards/$id';
  static String customerCardDefault(int id) => '/customer/cards/$id/default';
  static String customerCardFreeze(int id) => '/customer/cards/$id/freeze';
  static String customerJobAssignmentPay(int id) => '/customer/job-assignments/$id/pay';

  // Job Requests & Quotations endpoints
  static const String customerJobRequests = '/customer/job-requests';
  static String customerJobRequest(int id) => '/customer/job-requests/$id';
  static String customerJobRequestCancel(int id) => '/customer/job-requests/$id/cancel';
  static String customerJobRequestQuotations(int id) => '/customer/job-requests/$id/quotations';
  static String customerQuotationAccept(int id) => '/customer/quotations/$id/accept';
  static String customerJobRequestSimulateQuotation(int id) =>
      '/customer/job-requests/$id/simulate-quotation';

  // Job Assignments, Reviews & Disputes endpoints
  static const String customerJobAssignments = '/customer/job-assignments';
  static String customerJobAssignment(int id) => '/customer/job-assignments/$id';
  static String customerJobAssignmentReviews(int id) => '/customer/job-assignments/$id/reviews';
  static String customerJobAssignmentDisputes(int id) => '/customer/job-assignments/$id/disputes';
  static String customerJobAssignmentApproveExtra(int id) =>
      '/customer/job-assignments/$id/extra-charge/approve';
  static String customerJobAssignmentRejectExtra(int id) =>
      '/customer/job-assignments/$id/extra-charge/reject';
  static String customerJobAssignmentSimulateExtraQuote(int id) =>
      '/customer/job-assignments/$id/simulate-extra-quote';
  static String customerJobAssignmentSimulateStartJob(int id) =>
      '/customer/job-assignments/$id/simulate-start-job';
  static String customerJobAssignmentSimulateCompleteJob(int id) =>
      '/customer/job-assignments/$id/simulate-complete-job';

  // Exclusive Offers endpoints
  static const String customerExclusiveOffers = '/customer/exclusive-offers';
  static const String publicExclusiveOffers = '/exclusive-offers';
  static const String customerClaimOffer = '/customer/exclusive-offers/claim';

  // Rewards & Referrals endpoints
  static const String customerRewards = '/customer/rewards';
  static const String customerRedeemPoints = '/customer/rewards/redeem';
  static const String customerApplyReferral = '/customer/referral/apply';

  // Notifications & Alerts endpoints
  static const String customerNotifications = '/customer/notifications';
  static String customerNotificationRead(int id) => '/customer/notifications/$id/read';
  static const String customerMarkAllNotificationsRead = '/customer/notifications/mark-all-read';
  static String customerNotificationDelete(int id) => '/customer/notifications/$id';

  // FAQ endpoints
  static const String customerFaqs = '/customer/faqs';
  static const String publicFaqs = '/faqs';
  static const String faqCategories = '/faqs/categories';
}