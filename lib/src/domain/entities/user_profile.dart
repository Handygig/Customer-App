enum GenderType { male, female, other }

class UserProfile {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final GenderType gender;
  final String? profileImageUrl;
  final String membershipTier;
  final int rewardPoints;
  final double walletBalance;
  final String referralCode;
  final bool isTwoFactorEnabled;
  final String languageCode;
  final bool pushNotificationsEnabled;
  final bool biometricsEnabled;
  final bool isDarkMode;
  final String memberSinceYear;

  const UserProfile({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.gender,
    this.profileImageUrl,
    required this.membershipTier,
    required this.rewardPoints,
    required this.walletBalance,
    required this.referralCode,
    required this.isTwoFactorEnabled,
    required this.languageCode,
    required this.pushNotificationsEnabled,
    required this.biometricsEnabled,
    this.isDarkMode = false,
    required this.memberSinceYear,
  });

  String get fullName => '$firstName $lastName';

  UserProfile copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    GenderType? gender,
    String? profileImageUrl,
    String? membershipTier,
    int? rewardPoints,
    double? walletBalance,
    String? referralCode,
    bool? isTwoFactorEnabled,
    String? languageCode,
    bool? pushNotificationsEnabled,
    bool? biometricsEnabled,
    bool? isDarkMode,
    String? memberSinceYear,
  }) {
    return UserProfile(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      gender: gender ?? this.gender,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      membershipTier: membershipTier ?? this.membershipTier,
      rewardPoints: rewardPoints ?? this.rewardPoints,
      walletBalance: walletBalance ?? this.walletBalance,
      referralCode: referralCode ?? this.referralCode,
      isTwoFactorEnabled: isTwoFactorEnabled ?? this.isTwoFactorEnabled,
      languageCode: languageCode ?? this.languageCode,
      pushNotificationsEnabled:
          pushNotificationsEnabled ?? this.pushNotificationsEnabled,
      biometricsEnabled: biometricsEnabled ?? this.biometricsEnabled,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      memberSinceYear: memberSinceYear ?? this.memberSinceYear,
    );
  }
}
