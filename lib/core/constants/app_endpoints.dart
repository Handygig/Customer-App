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
  static const String logout = '/auth/logout';
  static const String userProfile = '/user/profile';

  // Services endpoints
  static const String customerServiceCategories = '/customer/service-categories';
  static const String customerServices = '/customer/services';
  static String customerCategoryServices(int categoryId) =>
      '/customer/service-categories/$categoryId/services';
  static String customerService(int id) => '/customer/services/$id';

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

  // Job Assignments, Reviews & Disputes endpoints
  static const String customerJobAssignments = '/customer/job-assignments';
  static String customerJobAssignment(int id) => '/customer/job-assignments/$id';
  static String customerJobAssignmentReviews(int id) => '/customer/job-assignments/$id/reviews';
  static String customerJobAssignmentDisputes(int id) => '/customer/job-assignments/$id/disputes';

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