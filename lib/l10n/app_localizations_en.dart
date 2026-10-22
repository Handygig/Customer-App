// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'JobHive';

  @override
  String get noInternetMessage => 'No Internet Connection';

  @override
  String get no_internet_message => 'No Internet Connection';

  @override
  String get unAuthorizedError => 'Unauthorized access. Please log in again.';

  @override
  String get continueText => 'Continue';

  @override
  String get getStarted => 'Get Started';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get confirm => 'Confirm';

  @override
  String get back => 'Back';

  @override
  String get done => 'Done';

  @override
  String get retry => 'Retry';

  @override
  String get loading => 'Loading...';

  @override
  String get search => 'Search';

  @override
  String get seeAll => 'See All';

  @override
  String get ok => 'OK';

  @override
  String get error => 'Error';

  @override
  String get success => 'Success';

  @override
  String get onDemandHomeServices => 'ON-DEMAND HOME SERVICES';

  @override
  String get welcomeHeroTitle => 'Expert Services,\nRight at Your Door';

  @override
  String get welcomeHeroSubtitle =>
      'Connect with certified plumbers, electricians, carpenters, and home repair experts in minutes.';

  @override
  String get fastArrival => 'Fast Arrival';

  @override
  String get guaranteed => 'Guaranteed';

  @override
  String get ratingBadge => '4.9/5 Rating';

  @override
  String get verifiedPros => 'Verified Pros';

  @override
  String get chooseLanguageTitle => 'Choose your\nLanguage';

  @override
  String get chooseLanguageSubtitle =>
      'Select your preferred language to continue.';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageSinhala => 'සිංහල';

  @override
  String get languageTamil => 'தமிழ்';

  @override
  String get enterMobileNumberTitle => 'Enter your\nMobile Number';

  @override
  String get enterMobileNumberSubtitle =>
      'We will send you a 6-digit verification code to confirm your number.';

  @override
  String get phoneInputPlaceholder => 'Phone number';

  @override
  String get securityNotice => 'Your info is safe and secured with us';

  @override
  String get termsNoticePrefix => 'By continuing, you agree to JobHive\'s ';

  @override
  String get termsOfService => 'Terms of Service';

  @override
  String get andText => ' & ';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get sendCode => 'Send Code';

  @override
  String get verificationTitle => 'Enter 6-digit\nVerification Code';

  @override
  String get verificationSubtitle => 'Enter the 6-digit code sent to ';

  @override
  String get didNotReceiveCode => 'Didn\'t receive the code? ';

  @override
  String get resendCode => 'Resend Code';

  @override
  String resendCodeIn(int seconds) {
    return 'Resend code in ${seconds}s';
  }

  @override
  String get verifyAndContinue => 'Verify & Continue';

  @override
  String get codeSentSuccess => 'A new verification code was sent.';

  @override
  String get tabHome => 'Home';

  @override
  String get tabJobs => 'Jobs';

  @override
  String get tabSearch => 'Search';

  @override
  String get tabAlerts => 'Alerts';

  @override
  String get tabProfile => 'Profile';

  @override
  String get settingsAndSecurity => 'Settings & Security';

  @override
  String get accountSecurity => 'ACCOUNT SECURITY';

  @override
  String get changePassword => 'Change Password';

  @override
  String get changePasswordSubtitle => 'Update account password';

  @override
  String get twoFactorAuth => 'Two-Factor Authentication (2FA)';

  @override
  String get twoFactorEnabledSubtitle => 'SMS OTP Protection Enabled';

  @override
  String get twoFactorDisabledSubtitle => 'Extra layer of security for logins';

  @override
  String get biometricLogin => 'Biometric Login (Face ID / Touch ID)';

  @override
  String get biometricLoginSubtitle => 'Sign in quickly using biometrics';

  @override
  String get preferencesAndApp => 'PREFERENCES & APP';

  @override
  String get appLanguage => 'App Language';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get darkModeEnabled => 'Dark theme enabled';

  @override
  String get darkModeDisabled => 'Light theme enabled';

  @override
  String get pushNotifications => 'Push Notifications';

  @override
  String get pushNotificationsSubtitle =>
      'Service updates, job alerts, and receipts';

  @override
  String get logout => 'Log Out';

  @override
  String get bookService => 'Book Service';

  @override
  String get popularServices => 'Popular Services';

  @override
  String get allServices => 'All Services';

  @override
  String get myBookings => 'My Bookings';

  @override
  String get activeJobs => 'Active Jobs';

  @override
  String get noJobsFound => 'No jobs found';

  @override
  String get notifications => 'Notifications';

  @override
  String get noNotifications => 'No notifications yet';

  @override
  String get completeProfileTitle => 'Complete Profile';

  @override
  String get completeProfileSubtitle =>
      'Set up your customer profile to continue.';

  @override
  String get editProfileTitle => 'Edit Profile';

  @override
  String get firstName => 'First Name';

  @override
  String get lastName => 'Last Name';

  @override
  String get emailAddress => 'Email Address';

  @override
  String get gender => 'Gender';

  @override
  String get male => 'Male';

  @override
  String get female => 'Female';

  @override
  String get takePhoto => 'Take Photo';

  @override
  String get chooseFromGallery => 'Choose from Gallery';

  @override
  String get profileCompleted => 'Profile completed!';

  @override
  String get profileUpdated => 'Profile updated successfully!';

  @override
  String get personalInformation => 'Personal Information';

  @override
  String get phoneNumber => 'Phone Number';

  @override
  String get addPropertiesTitle => 'Add your Properties';

  @override
  String get addPropertiesSubtitle =>
      'Add your homes, offices, or other locations to order cleaning or repairs faster.';

  @override
  String get newProperty => 'New Property';

  @override
  String get newPropertySubtitle => 'Set up your home or workspace coordinates';

  @override
  String get addNewProperty => 'Add New Property';

  @override
  String get manageProperties => 'Manage Properties';

  @override
  String propertiesRegistered(int count) {
    return '$count properties registered';
  }

  @override
  String get noPropertiesAdded => 'No properties added yet';

  @override
  String get tapToRegisterFirstProperty =>
      'Tap to register your first property';

  @override
  String get locationType => 'Location Type';

  @override
  String get propertyName => 'Property Name';

  @override
  String get locationOnMap => 'Location on Map';

  @override
  String get coordinatesSelected => 'Coordinates Selected';

  @override
  String get tapToPinpointOnMap => 'Tap to pinpoint on map ➔';

  @override
  String get addressLine1 => 'Address Line 1';

  @override
  String get addressLine2Optional => 'Address Line 2 (Optional)';

  @override
  String get city => 'City';

  @override
  String get provinceState => 'Province / State';

  @override
  String get postalZipCode => 'Postal / ZIP Code';

  @override
  String get propertyPhoto => 'Property Photo';

  @override
  String get uploadPropertyPhoto => 'Upload Property Photo';

  @override
  String get uploadPropertyPhotoSubtitle =>
      'Select or take a high-resolution photo of your property.';

  @override
  String get propertyPhotoAttached => 'Property photo attached';

  @override
  String get uploadPropertyImage => 'Upload Property Image';

  @override
  String get tapToSelectPropertyPhoto =>
      'Tap to select or capture front photo (JPG, PNG)';

  @override
  String get saveLocation => 'Save Location';

  @override
  String get confirmLocation => 'Confirm Location';

  @override
  String get skip => 'Skip';

  @override
  String get skipAndFinish => 'Skip & Finish';

  @override
  String get finishRegistration => 'Finish Registration';

  @override
  String get typeHome => 'Home';

  @override
  String get typeOffice => 'Office';

  @override
  String get typeApartment => 'Apartment';

  @override
  String get typeOther => 'Other';

  @override
  String get defaultProperty => 'Default';

  @override
  String get setDefaultProperty => 'Set as Default';

  @override
  String get deletePropertyConfirm =>
      'Are you sure you want to delete this property?';

  @override
  String get goodMorning => 'Good Morning';

  @override
  String goodMorningUser(String name) {
    return 'Good Morning, $name';
  }

  @override
  String get homeSearchPlaceholder =>
      'Search for cleaning, repairs, plumbing...';

  @override
  String get addedProperties => 'Added Properties';

  @override
  String get manage => 'Manage';

  @override
  String get exploreServices => 'Explore Services';

  @override
  String get exploreAll => 'Explore All';

  @override
  String get viewAll => 'View All';

  @override
  String get ongoingJobs => 'Ongoing Jobs';

  @override
  String activeCount(int count) {
    return '$count Active';
  }

  @override
  String get noOngoingJobs => 'No Ongoing Jobs';

  @override
  String get noOngoingJobsSubtitle =>
      'Active assignments in progress will show up here.';

  @override
  String get exclusiveOffers => 'Exclusive Offers & Discounts';

  @override
  String get trackService => 'Track';

  @override
  String get serviceProgress => 'Service Progress';

  @override
  String couponCopied(String code) {
    return 'Coupon \"$code\" copied to clipboard!';
  }

  @override
  String offerApplied(String code) {
    return 'Offer code \"$code\" applied! Navigating to services...';
  }

  @override
  String get myBookingsAndJobs => 'My Bookings & Jobs';

  @override
  String get myBookingsSubtitle =>
      'Track requests, approve quotes & review active work';

  @override
  String get tabWaiting => 'Waiting';

  @override
  String get tabToApprove => 'To Approve';

  @override
  String get tabOngoing => 'Ongoing';

  @override
  String get tabCompleted => 'Completed';

  @override
  String get waitingRequests => 'waiting requests';

  @override
  String get quotesToApprove => 'quotes to approve';

  @override
  String get completedJobs => 'completed jobs';

  @override
  String noJobsInCategory(String category) {
    return 'No $category';
  }

  @override
  String get jobDetails => 'Job Details';

  @override
  String get jobStatus => 'Status';

  @override
  String get jobTimeline => 'Timeline';

  @override
  String get jobCancelled => 'Cancelled';

  @override
  String get jobCompletedStatus => 'Completed';

  @override
  String get awaitingQuotes => 'Awaiting Quotes';

  @override
  String get quotesAvailable => 'Quotes Available';

  @override
  String get pendingQuote => 'Pending Quote';

  @override
  String fromPrice(String price) {
    return 'From \$$price';
  }

  @override
  String quotesCount(int count) {
    return '$count Quote(s)';
  }

  @override
  String get cancelRequest => 'Cancel Request';

  @override
  String get cancelRequestConfirm =>
      'Are you sure you want to cancel this request?';

  @override
  String get acceptQuote => 'Accept Quote';

  @override
  String get declineQuote => 'Decline';

  @override
  String get contactProvider => 'Contact Provider';

  @override
  String get serviceLocator => 'Service Locator';

  @override
  String get serviceType => 'SERVICE TYPE';

  @override
  String get serviceTypePlaceholder =>
      'Search service type (e.g. Plumbing, Cleaning)';

  @override
  String get locationLabel => 'LOCATION';

  @override
  String get locationPlaceholder => 'Search location or area (e.g. Downtown)';

  @override
  String get nearMe => 'Near me';

  @override
  String get categoryAll => 'All';

  @override
  String get bookProvider => 'Book Provider';

  @override
  String contactingProvider(String name) {
    return 'Contacting $name...';
  }

  @override
  String get available => 'Available';

  @override
  String get busy => 'Busy';

  @override
  String reviews(int count) {
    return '$count reviews';
  }

  @override
  String get filterAll => 'All';

  @override
  String get filterUnread => 'Unread';

  @override
  String get filterJobs => 'Jobs';

  @override
  String get filterOffers => 'Offers';

  @override
  String get filterRewards => 'Rewards';

  @override
  String get filterUpdates => 'Updates';

  @override
  String get markAllAsRead => 'Mark all as read';

  @override
  String get notificationRemoved => 'Notification removed';

  @override
  String get tryAgain => 'Try Again';

  @override
  String get noNotificationsCategory => 'No notifications in this category';

  @override
  String get signOut => 'Sign Out';

  @override
  String get signOutConfirmTitle => 'Sign Out';

  @override
  String get signOutConfirmMessage =>
      'Are you sure you want to log out of your account?';

  @override
  String get manageProfile => 'Manage Profile';

  @override
  String get manageProfileSubtitle => 'Name, Email, Phone, Gender';

  @override
  String get paymentMethods => 'Payment Methods';

  @override
  String get noCardsSaved => 'No cards saved';

  @override
  String cardEnding(String brand, String digits) {
    return '$brand ending $digits';
  }

  @override
  String get rewardsAndWallet => 'Rewards & Wallet';

  @override
  String rewardsSubtitle(int points, String balance) {
    return '$points pts • \$$balance balance';
  }

  @override
  String get helpAndSupport => 'Help & 24/7 Support';

  @override
  String get helpAndSupportSubtitle => 'Emergency hotline, FAQ, Live Chat';

  @override
  String get settingsSecuritySubtitle => 'Language, Password, 2FA & Security';

  @override
  String get addNewCard => 'Add New Card';

  @override
  String get cardNumber => 'Card Number';

  @override
  String get expiryDate => 'Expiry Date';

  @override
  String get cvv => 'CVV';

  @override
  String get cardholderName => 'Cardholder Name';

  @override
  String get emergencyHotline => 'Emergency Hotline';

  @override
  String get faq => 'Frequently Asked Questions';

  @override
  String get liveChat => 'Live Chat Support';

  @override
  String get referralCode => 'Referral Code';

  @override
  String get shareReferral => 'Share with Friends';

  @override
  String get bookServiceTitle => 'Book Service';

  @override
  String get selectDateTime => 'Select Date & Time';

  @override
  String get serviceAddress => 'Service Address';

  @override
  String get paymentMethod => 'Payment Method';

  @override
  String get cashOnService => 'Cash on Service';

  @override
  String get creditDebitCard => 'Credit / Debit Card';

  @override
  String get notesDescription => 'Job Description & Notes';

  @override
  String get notesPlaceholder =>
      'Describe the problem or any special requirements...';

  @override
  String get confirmBooking => 'Confirm Booking';

  @override
  String get bookingSuccess => 'Booking request sent successfully!';

  @override
  String get alertsAndNotifications => 'Alerts & Notifications';

  @override
  String get alertsSubtitle =>
      'Stay updated on your ongoing bookings and offers';

  @override
  String get allCaughtUp =>
      'You are all caught up! When updates or offers arrive, you will see them here.';

  @override
  String get refreshFeed => 'Refresh Feed';

  @override
  String get failedToLoadNotifications => 'Failed to load notifications';

  @override
  String memberSince(String year) {
    return 'Member since $year';
  }

  @override
  String get signOutSubtitle => 'Log out of customer app account';
}
