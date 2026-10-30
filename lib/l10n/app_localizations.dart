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

  /// Title on complete profile screen
  ///
  /// In en, this message translates to:
  /// **'Complete Profile'**
  String get completeProfileTitle;

  /// Subtitle on complete profile screen
  ///
  /// In en, this message translates to:
  /// **'Set up your customer profile to continue.'**
  String get completeProfileSubtitle;

  /// Title on edit profile screen
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfileTitle;

  /// First name field label
  ///
  /// In en, this message translates to:
  /// **'First Name'**
  String get firstName;

  /// Last name field label
  ///
  /// In en, this message translates to:
  /// **'Last Name'**
  String get lastName;

  /// Email address field label
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get emailAddress;

  /// Gender field label
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get gender;

  /// Male gender option
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get male;

  /// Female gender option
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get female;

  /// Take photo action label
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get takePhoto;

  /// Choose photo from gallery action label
  ///
  /// In en, this message translates to:
  /// **'Choose from Gallery'**
  String get chooseFromGallery;

  /// Success message when profile is completed
  ///
  /// In en, this message translates to:
  /// **'Profile completed!'**
  String get profileCompleted;

  /// Success message when profile is updated
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully!'**
  String get profileUpdated;

  /// Personal information header
  ///
  /// In en, this message translates to:
  /// **'Personal Information'**
  String get personalInformation;

  /// Phone number field label
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// Title on properties setup screen
  ///
  /// In en, this message translates to:
  /// **'Add your Properties'**
  String get addPropertiesTitle;

  /// Subtitle on properties setup screen
  ///
  /// In en, this message translates to:
  /// **'Add your homes, offices, or other locations to order cleaning or repairs faster.'**
  String get addPropertiesSubtitle;

  /// New property screen title
  ///
  /// In en, this message translates to:
  /// **'New Property'**
  String get newProperty;

  /// New property subtitle
  ///
  /// In en, this message translates to:
  /// **'Set up your home or workspace coordinates'**
  String get newPropertySubtitle;

  /// Add new property button label
  ///
  /// In en, this message translates to:
  /// **'Add New Property'**
  String get addNewProperty;

  /// Manage properties title
  ///
  /// In en, this message translates to:
  /// **'Manage Properties'**
  String get manageProperties;

  /// Count of registered properties
  ///
  /// In en, this message translates to:
  /// **'{count} properties registered'**
  String propertiesRegistered(int count);

  /// Empty state for properties
  ///
  /// In en, this message translates to:
  /// **'No properties added yet'**
  String get noPropertiesAdded;

  /// Prompt to add first property
  ///
  /// In en, this message translates to:
  /// **'Tap to register your first property'**
  String get tapToRegisterFirstProperty;

  /// Location type field label
  ///
  /// In en, this message translates to:
  /// **'Location Type'**
  String get locationType;

  /// Property name field label
  ///
  /// In en, this message translates to:
  /// **'Property Name'**
  String get propertyName;

  /// Location on map section title
  ///
  /// In en, this message translates to:
  /// **'Location on Map'**
  String get locationOnMap;

  /// Coordinates selected status
  ///
  /// In en, this message translates to:
  /// **'Coordinates Selected'**
  String get coordinatesSelected;

  /// Map picker prompt
  ///
  /// In en, this message translates to:
  /// **'Tap to pinpoint on map ➔'**
  String get tapToPinpointOnMap;

  /// Address line 1 label
  ///
  /// In en, this message translates to:
  /// **'Address Line 1'**
  String get addressLine1;

  /// Address line 2 label
  ///
  /// In en, this message translates to:
  /// **'Address Line 2 (Optional)'**
  String get addressLine2Optional;

  /// City label
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get city;

  /// Province or state label
  ///
  /// In en, this message translates to:
  /// **'Province / State'**
  String get provinceState;

  /// Postal code label
  ///
  /// In en, this message translates to:
  /// **'Postal / ZIP Code'**
  String get postalZipCode;

  /// Property photo label
  ///
  /// In en, this message translates to:
  /// **'Property Photo'**
  String get propertyPhoto;

  /// Upload property photo button
  ///
  /// In en, this message translates to:
  /// **'Upload Property Photo'**
  String get uploadPropertyPhoto;

  /// Upload property photo instructions
  ///
  /// In en, this message translates to:
  /// **'Select or take a high-resolution photo of your property.'**
  String get uploadPropertyPhotoSubtitle;

  /// Success banner for attached property photo
  ///
  /// In en, this message translates to:
  /// **'Property photo attached'**
  String get propertyPhotoAttached;

  /// Upload property image placeholder
  ///
  /// In en, this message translates to:
  /// **'Upload Property Image'**
  String get uploadPropertyImage;

  /// Upload image placeholder hint
  ///
  /// In en, this message translates to:
  /// **'Tap to select or capture front photo (JPG, PNG)'**
  String get tapToSelectPropertyPhoto;

  /// Save location button
  ///
  /// In en, this message translates to:
  /// **'Save Location'**
  String get saveLocation;

  /// Confirm location button
  ///
  /// In en, this message translates to:
  /// **'Confirm Location'**
  String get confirmLocation;

  /// Skip button
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// Skip and finish button
  ///
  /// In en, this message translates to:
  /// **'Skip & Finish'**
  String get skipAndFinish;

  /// Finish registration button
  ///
  /// In en, this message translates to:
  /// **'Finish Registration'**
  String get finishRegistration;

  /// Home property type
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get typeHome;

  /// Office property type
  ///
  /// In en, this message translates to:
  /// **'Office'**
  String get typeOffice;

  /// Apartment property type
  ///
  /// In en, this message translates to:
  /// **'Apartment'**
  String get typeApartment;

  /// Other property type
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get typeOther;

  /// Default property badge
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get defaultProperty;

  /// Set as default property action
  ///
  /// In en, this message translates to:
  /// **'Set as Default'**
  String get setDefaultProperty;

  /// Confirmation message for deleting a property
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this property?'**
  String get deletePropertyConfirm;

  /// Generic morning greeting
  ///
  /// In en, this message translates to:
  /// **'Good Morning'**
  String get goodMorning;

  /// Personalized morning greeting
  ///
  /// In en, this message translates to:
  /// **'Good Morning, {name}'**
  String goodMorningUser(String name);

  /// Search input placeholder on home tab
  ///
  /// In en, this message translates to:
  /// **'Search for cleaning, repairs, plumbing...'**
  String get homeSearchPlaceholder;

  /// Added properties carousel title
  ///
  /// In en, this message translates to:
  /// **'Added Properties'**
  String get addedProperties;

  /// Manage button label
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get manage;

  /// Explore services section title
  ///
  /// In en, this message translates to:
  /// **'Explore Services'**
  String get exploreServices;

  /// Explore all services button label
  ///
  /// In en, this message translates to:
  /// **'Explore All'**
  String get exploreAll;

  /// View all button label
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get viewAll;

  /// Ongoing jobs section title
  ///
  /// In en, this message translates to:
  /// **'Ongoing Jobs'**
  String get ongoingJobs;

  /// Active count badge
  ///
  /// In en, this message translates to:
  /// **'{count} Active'**
  String activeCount(int count);

  /// Empty state title for ongoing jobs
  ///
  /// In en, this message translates to:
  /// **'No Ongoing Jobs'**
  String get noOngoingJobs;

  /// Empty state subtitle for ongoing jobs
  ///
  /// In en, this message translates to:
  /// **'Active assignments in progress will show up here.'**
  String get noOngoingJobsSubtitle;

  /// Exclusive offers section title
  ///
  /// In en, this message translates to:
  /// **'Exclusive Offers & Discounts'**
  String get exclusiveOffers;

  /// Track service action label
  ///
  /// In en, this message translates to:
  /// **'Track'**
  String get trackService;

  /// Service progress section title
  ///
  /// In en, this message translates to:
  /// **'Service Progress'**
  String get serviceProgress;

  /// Toast when coupon is copied
  ///
  /// In en, this message translates to:
  /// **'Coupon \"{code}\" copied to clipboard!'**
  String couponCopied(String code);

  /// Toast when offer is applied
  ///
  /// In en, this message translates to:
  /// **'Offer code \"{code}\" applied! Navigating to services...'**
  String offerApplied(String code);

  /// Title on jobs tab
  ///
  /// In en, this message translates to:
  /// **'My Bookings & Jobs'**
  String get myBookingsAndJobs;

  /// Subtitle on jobs tab
  ///
  /// In en, this message translates to:
  /// **'Track requests, approve quotes & review active work'**
  String get myBookingsSubtitle;

  /// Waiting tab name
  ///
  /// In en, this message translates to:
  /// **'Waiting'**
  String get tabWaiting;

  /// To Approve tab name
  ///
  /// In en, this message translates to:
  /// **'To Approve'**
  String get tabToApprove;

  /// Ongoing tab name
  ///
  /// In en, this message translates to:
  /// **'Ongoing'**
  String get tabOngoing;

  /// Completed tab name
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get tabCompleted;

  /// Empty state waiting requests category name
  ///
  /// In en, this message translates to:
  /// **'waiting requests'**
  String get waitingRequests;

  /// Empty state quotes to approve category name
  ///
  /// In en, this message translates to:
  /// **'quotes to approve'**
  String get quotesToApprove;

  /// Empty state completed jobs category name
  ///
  /// In en, this message translates to:
  /// **'completed jobs'**
  String get completedJobs;

  /// Empty state for jobs in specific category
  ///
  /// In en, this message translates to:
  /// **'No {category}'**
  String noJobsInCategory(String category);

  /// Job details title
  ///
  /// In en, this message translates to:
  /// **'Job Details'**
  String get jobDetails;

  /// Job status title
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get jobStatus;

  /// Job timeline title
  ///
  /// In en, this message translates to:
  /// **'Timeline'**
  String get jobTimeline;

  /// Cancelled job status
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get jobCancelled;

  /// Completed job status
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get jobCompletedStatus;

  /// Awaiting quotes status
  ///
  /// In en, this message translates to:
  /// **'Awaiting Quotes'**
  String get awaitingQuotes;

  /// Quotes available status
  ///
  /// In en, this message translates to:
  /// **'Quotes Available'**
  String get quotesAvailable;

  /// Pending quote status
  ///
  /// In en, this message translates to:
  /// **'Pending Quote'**
  String get pendingQuote;

  /// Lowest quote price prefix
  ///
  /// In en, this message translates to:
  /// **'From LKR {price}'**
  String fromPrice(String price);

  /// Quotes count badge
  ///
  /// In en, this message translates to:
  /// **'{count} Quote(s)'**
  String quotesCount(int count);

  /// Cancel request button label
  ///
  /// In en, this message translates to:
  /// **'Cancel Request'**
  String get cancelRequest;

  /// Confirmation message for cancelling request
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to cancel this request?'**
  String get cancelRequestConfirm;

  /// Accept quote button
  ///
  /// In en, this message translates to:
  /// **'Accept Quote'**
  String get acceptQuote;

  /// Decline quote button
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get declineQuote;

  /// Contact provider button
  ///
  /// In en, this message translates to:
  /// **'Contact Provider'**
  String get contactProvider;

  /// Search tab title
  ///
  /// In en, this message translates to:
  /// **'Service Locator'**
  String get serviceLocator;

  /// Search service type header
  ///
  /// In en, this message translates to:
  /// **'SERVICE TYPE'**
  String get serviceType;

  /// Service type search placeholder
  ///
  /// In en, this message translates to:
  /// **'Search service type (e.g. Plumbing, Cleaning)'**
  String get serviceTypePlaceholder;

  /// Search location header
  ///
  /// In en, this message translates to:
  /// **'LOCATION'**
  String get locationLabel;

  /// Location search placeholder
  ///
  /// In en, this message translates to:
  /// **'Search location or area (e.g. Downtown)'**
  String get locationPlaceholder;

  /// Near me button
  ///
  /// In en, this message translates to:
  /// **'Near me'**
  String get nearMe;

  /// All category filter
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get categoryAll;

  /// Book provider button
  ///
  /// In en, this message translates to:
  /// **'Book Provider'**
  String get bookProvider;

  /// Toast when contacting provider
  ///
  /// In en, this message translates to:
  /// **'Contacting {name}...'**
  String contactingProvider(String name);

  /// Provider available status
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get available;

  /// Provider busy status
  ///
  /// In en, this message translates to:
  /// **'Busy'**
  String get busy;

  /// Reviews count
  ///
  /// In en, this message translates to:
  /// **'{count} reviews'**
  String reviews(int count);

  /// Filter all chip
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// Filter unread chip
  ///
  /// In en, this message translates to:
  /// **'Unread'**
  String get filterUnread;

  /// Filter jobs chip
  ///
  /// In en, this message translates to:
  /// **'Jobs'**
  String get filterJobs;

  /// Filter offers chip
  ///
  /// In en, this message translates to:
  /// **'Offers'**
  String get filterOffers;

  /// Filter rewards chip
  ///
  /// In en, this message translates to:
  /// **'Rewards'**
  String get filterRewards;

  /// Filter updates chip
  ///
  /// In en, this message translates to:
  /// **'Updates'**
  String get filterUpdates;

  /// Mark all as read action
  ///
  /// In en, this message translates to:
  /// **'Mark all as read'**
  String get markAllAsRead;

  /// Toast when notification is dismissed
  ///
  /// In en, this message translates to:
  /// **'Notification removed'**
  String get notificationRemoved;

  /// Try again button
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get tryAgain;

  /// Empty state for notifications in selected category
  ///
  /// In en, this message translates to:
  /// **'No notifications in this category'**
  String get noNotificationsCategory;

  /// Sign out button label
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// Sign out dialog title
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOutConfirmTitle;

  /// Sign out dialog message
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out of your account?'**
  String get signOutConfirmMessage;

  /// Manage profile tile title
  ///
  /// In en, this message translates to:
  /// **'Manage Profile'**
  String get manageProfile;

  /// Manage profile tile subtitle
  ///
  /// In en, this message translates to:
  /// **'Name, Email, Phone, Gender'**
  String get manageProfileSubtitle;

  /// Payment methods tile title
  ///
  /// In en, this message translates to:
  /// **'Payment Methods'**
  String get paymentMethods;

  /// Empty cards state label
  ///
  /// In en, this message translates to:
  /// **'No cards saved'**
  String get noCardsSaved;

  /// Card summary description
  ///
  /// In en, this message translates to:
  /// **'{brand} ending {digits}'**
  String cardEnding(String brand, String digits);

  /// Rewards and wallet tile title
  ///
  /// In en, this message translates to:
  /// **'Rewards & Wallet'**
  String get rewardsAndWallet;

  /// Rewards and wallet tile subtitle
  ///
  /// In en, this message translates to:
  /// **'{points} pts • LKR {balance} balance'**
  String rewardsSubtitle(int points, String balance);

  /// Help and support tile title
  ///
  /// In en, this message translates to:
  /// **'Help & 24/7 Support'**
  String get helpAndSupport;

  /// Help and support tile subtitle
  ///
  /// In en, this message translates to:
  /// **'Emergency hotline, FAQ, Live Chat'**
  String get helpAndSupportSubtitle;

  /// Settings and security tile subtitle
  ///
  /// In en, this message translates to:
  /// **'Language, Password, 2FA & Security'**
  String get settingsSecuritySubtitle;

  /// Add new payment card title
  ///
  /// In en, this message translates to:
  /// **'Add New Card'**
  String get addNewCard;

  /// Card number field label
  ///
  /// In en, this message translates to:
  /// **'Card Number'**
  String get cardNumber;

  /// Expiry date field label
  ///
  /// In en, this message translates to:
  /// **'Expiry Date'**
  String get expiryDate;

  /// CVV security code field label
  ///
  /// In en, this message translates to:
  /// **'CVV'**
  String get cvv;

  /// Cardholder name field label
  ///
  /// In en, this message translates to:
  /// **'Cardholder Name'**
  String get cardholderName;

  /// Emergency hotline title
  ///
  /// In en, this message translates to:
  /// **'Emergency Hotline'**
  String get emergencyHotline;

  /// FAQ title
  ///
  /// In en, this message translates to:
  /// **'Frequently Asked Questions'**
  String get faq;

  /// Live chat title
  ///
  /// In en, this message translates to:
  /// **'Live Chat Support'**
  String get liveChat;

  /// Referral code title
  ///
  /// In en, this message translates to:
  /// **'Referral Code'**
  String get referralCode;

  /// Share referral action
  ///
  /// In en, this message translates to:
  /// **'Share with Friends'**
  String get shareReferral;

  /// Book service modal title
  ///
  /// In en, this message translates to:
  /// **'Book Service'**
  String get bookServiceTitle;

  /// Select date and time label
  ///
  /// In en, this message translates to:
  /// **'Select Date & Time'**
  String get selectDateTime;

  /// Service address label
  ///
  /// In en, this message translates to:
  /// **'Service Address'**
  String get serviceAddress;

  /// Payment method label
  ///
  /// In en, this message translates to:
  /// **'Payment Method'**
  String get paymentMethod;

  /// Cash payment option
  ///
  /// In en, this message translates to:
  /// **'Cash on Service'**
  String get cashOnService;

  /// Card payment option
  ///
  /// In en, this message translates to:
  /// **'Credit / Debit Card'**
  String get creditDebitCard;

  /// Job description label
  ///
  /// In en, this message translates to:
  /// **'Job Description & Notes'**
  String get notesDescription;

  /// Job description placeholder
  ///
  /// In en, this message translates to:
  /// **'Describe the problem or any special requirements...'**
  String get notesPlaceholder;

  /// Confirm booking button
  ///
  /// In en, this message translates to:
  /// **'Confirm Booking'**
  String get confirmBooking;

  /// Toast message after booking request is sent
  ///
  /// In en, this message translates to:
  /// **'Booking request sent successfully!'**
  String get bookingSuccess;

  /// Alerts tab header title
  ///
  /// In en, this message translates to:
  /// **'Alerts & Notifications'**
  String get alertsAndNotifications;

  /// Alerts tab header subtitle
  ///
  /// In en, this message translates to:
  /// **'Stay updated on your ongoing bookings and offers'**
  String get alertsSubtitle;

  /// Empty state subtitle in alerts tab
  ///
  /// In en, this message translates to:
  /// **'You are all caught up! When updates or offers arrive, you will see them here.'**
  String get allCaughtUp;

  /// Refresh feed button
  ///
  /// In en, this message translates to:
  /// **'Refresh Feed'**
  String get refreshFeed;

  /// Failed to load notifications error message
  ///
  /// In en, this message translates to:
  /// **'Failed to load notifications'**
  String get failedToLoadNotifications;

  /// Profile member since label
  ///
  /// In en, this message translates to:
  /// **'Member since {year}'**
  String memberSince(String year);

  /// Sign out tile subtitle
  ///
  /// In en, this message translates to:
  /// **'Log out of customer app account'**
  String get signOutSubtitle;
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
