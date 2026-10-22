import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_si.dart';
import 'app_localizations_ta.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('si'),
    Locale('ta'),
  ];

  /// Application title
  ///
  /// In en, this message translates to:
  /// **'JobHive'**
  String get appTitle;

  /// Error message when device has no internet connection
  ///
  /// In en, this message translates to:
  /// **'No Internet Connection'**
  String get noInternetMessage;

  /// Snake case fallback for internet message
  ///
  /// In en, this message translates to:
  /// **'No Internet Connection'**
  String get no_internet_message;

  /// Error message when token is expired or unauthorized
  ///
  /// In en, this message translates to:
  /// **'Unauthorized access. Please log in again.'**
  String get unAuthorizedError;

  /// Generic continue button label
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueText;

  /// Get started button label on welcome screen
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// Generic cancel button label
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Generic save button label
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Generic delete button label
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// Generic edit button label
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// Generic confirm button label
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// Generic back button label
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// Generic done button label
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// Generic retry button label
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// Generic loading state text
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// Generic search text
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// See all button label
  ///
  /// In en, this message translates to:
  /// **'See All'**
  String get seeAll;

  /// OK dialog confirmation
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// Generic error title
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// Generic success title
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// Pill tag on welcome screen
  ///
  /// In en, this message translates to:
  /// **'ON-DEMAND HOME SERVICES'**
  String get onDemandHomeServices;

  /// Hero title on welcome screen
  ///
  /// In en, this message translates to:
  /// **'Expert Services,\nRight at Your Door'**
  String get welcomeHeroTitle;

  /// Hero subtitle on welcome screen
  ///
  /// In en, this message translates to:
  /// **'Connect with certified plumbers, electricians, carpenters, and home repair experts in minutes.'**
  String get welcomeHeroSubtitle;

  /// Fast arrival feature badge
  ///
  /// In en, this message translates to:
  /// **'Fast Arrival'**
  String get fastArrival;

  /// Guaranteed feature badge
  ///
  /// In en, this message translates to:
  /// **'Guaranteed'**
  String get guaranteed;

  /// Rating feature badge
  ///
  /// In en, this message translates to:
  /// **'4.9/5 Rating'**
  String get ratingBadge;

  /// Verified professionals badge
  ///
  /// In en, this message translates to:
  /// **'Verified Pros'**
  String get verifiedPros;

  /// Title on language selection screen
  ///
  /// In en, this message translates to:
  /// **'Choose your\nLanguage'**
  String get chooseLanguageTitle;

  /// Subtitle on language selection screen
  ///
  /// In en, this message translates to:
  /// **'Select your preferred language to continue.'**
  String get chooseLanguageSubtitle;

  /// English language name
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// Sinhala language name
  ///
  /// In en, this message translates to:
  /// **'සිංහල'**
  String get languageSinhala;

  /// Tamil language name
  ///
  /// In en, this message translates to:
  /// **'தமிழ்'**
  String get languageTamil;

  /// Title on mobile number input screen
  ///
  /// In en, this message translates to:
  /// **'Enter your\nMobile Number'**
  String get enterMobileNumberTitle;

  /// Subtitle on mobile number input screen
  ///
  /// In en, this message translates to:
  /// **'We will send you a 6-digit verification code to confirm your number.'**
  String get enterMobileNumberSubtitle;

  /// Placeholder for phone number input
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get phoneInputPlaceholder;

  /// Security assurance notice
  ///
  /// In en, this message translates to:
  /// **'Your info is safe and secured with us'**
  String get securityNotice;

  /// Terms notice prefix
  ///
  /// In en, this message translates to:
  /// **'By continuing, you agree to JobHive\'s '**
  String get termsNoticePrefix;

  /// Terms of service link text
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// Ampersand and text
  ///
  /// In en, this message translates to:
  /// **' & '**
  String get andText;

  /// Privacy policy link text
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// Send code button label
  ///
  /// In en, this message translates to:
  /// **'Send Code'**
  String get sendCode;

  /// Title on OTP verification screen
  ///
  /// In en, this message translates to:
  /// **'Enter 6-digit\nVerification Code'**
  String get verificationTitle;

  /// Subtitle on OTP verification screen before phone number
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code sent to '**
  String get verificationSubtitle;

  /// Text asking if code was received
  ///
  /// In en, this message translates to:
  /// **'Didn\'t receive the code? '**
  String get didNotReceiveCode;

  /// Resend OTP button label
  ///
  /// In en, this message translates to:
  /// **'Resend Code'**
  String get resendCode;

  /// Countdown timer to resend code
  ///
  /// In en, this message translates to:
  /// **'Resend code in {seconds}s'**
  String resendCodeIn(int seconds);

  /// Verify OTP and continue button
  ///
  /// In en, this message translates to:
  /// **'Verify & Continue'**
  String get verifyAndContinue;

  /// Notification when OTP resend succeeds
  ///
  /// In en, this message translates to:
  /// **'A new verification code was sent.'**
  String get codeSentSuccess;

  /// Home tab label
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get tabHome;

  /// Jobs tab label
  ///
  /// In en, this message translates to:
  /// **'Jobs'**
  String get tabJobs;

  /// Search tab label
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get tabSearch;

  /// Alerts tab label
  ///
  /// In en, this message translates to:
  /// **'Alerts'**
  String get tabAlerts;

  /// Profile tab label
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get tabProfile;

  /// Settings screen title
  ///
  /// In en, this message translates to:
  /// **'Settings & Security'**
  String get settingsAndSecurity;

  /// Account security section title
  ///
  /// In en, this message translates to:
  /// **'ACCOUNT SECURITY'**
  String get accountSecurity;

  /// Change password setting title
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePassword;

  /// Change password subtitle
  ///
  /// In en, this message translates to:
  /// **'Update account password'**
  String get changePasswordSubtitle;

  /// 2FA setting title
  ///
  /// In en, this message translates to:
  /// **'Two-Factor Authentication (2FA)'**
  String get twoFactorAuth;

  /// 2FA enabled subtitle
  ///
  /// In en, this message translates to:
  /// **'SMS OTP Protection Enabled'**
  String get twoFactorEnabledSubtitle;

  /// 2FA disabled subtitle
  ///
  /// In en, this message translates to:
  /// **'Extra layer of security for logins'**
  String get twoFactorDisabledSubtitle;

  /// Biometric login setting title
  ///
  /// In en, this message translates to:
  /// **'Biometric Login (Face ID / Touch ID)'**
  String get biometricLogin;

  /// Biometric login subtitle
  ///
  /// In en, this message translates to:
  /// **'Sign in quickly using biometrics'**
  String get biometricLoginSubtitle;

  /// Preferences section title
  ///
  /// In en, this message translates to:
  /// **'PREFERENCES & APP'**
  String get preferencesAndApp;

  /// App language setting title
  ///
  /// In en, this message translates to:
  /// **'App Language'**
  String get appLanguage;

  /// Dark mode setting title
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// Dark mode enabled subtitle
  ///
  /// In en, this message translates to:
  /// **'Dark theme enabled'**
  String get darkModeEnabled;

  /// Dark mode disabled subtitle
  ///
  /// In en, this message translates to:
  /// **'Light theme enabled'**
  String get darkModeDisabled;

  /// Push notifications setting title
  ///
  /// In en, this message translates to:
  /// **'Push Notifications'**
  String get pushNotifications;

  /// Push notifications subtitle
  ///
  /// In en, this message translates to:
  /// **'Service updates, job alerts, and receipts'**
  String get pushNotificationsSubtitle;

  /// Log out button
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get logout;

  /// Book service button label
  ///
  /// In en, this message translates to:
  /// **'Book Service'**
  String get bookService;

  /// Popular services section title
  ///
  /// In en, this message translates to:
  /// **'Popular Services'**
  String get popularServices;

  /// All services header
  ///
  /// In en, this message translates to:
  /// **'All Services'**
  String get allServices;

  /// My bookings header
  ///
  /// In en, this message translates to:
  /// **'My Bookings'**
  String get myBookings;

  /// Active jobs section title
  ///
  /// In en, this message translates to:
  /// **'Active Jobs'**
  String get activeJobs;

  /// Empty state for jobs
  ///
  /// In en, this message translates to:
  /// **'No jobs found'**
  String get noJobsFound;

  /// Notifications title
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// Empty notifications state text
  ///
  /// In en, this message translates to:
  /// **'No notifications yet'**
  String get noNotifications;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'si', 'ta'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'si':
      return AppLocalizationsSi();
    case 'ta':
      return AppLocalizationsTa();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
