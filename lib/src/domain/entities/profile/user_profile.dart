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

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final rawFullName = (json['full_name'] ?? '').toString().trim();
    final parts = rawFullName.isNotEmpty ? rawFullName.split(RegExp(r'\s+')) : <String>[];
    final firstName = parts.isNotEmpty ? parts.first : '';
    final lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';

    final genderStr = (json['gender'] ?? '').toString().trim().toLowerCase();
    final gender = GenderType.values.firstWhere(
      (g) => g.name == genderStr,
      orElse: () => GenderType.male,
    );

    String memberYear = '2026';
    if (json['created_at'] != null) {
      try {
        memberYear = DateTime.parse(json['created_at'].toString()).year.toString();
      } catch (_) {}
    }

    return UserProfile(
      id: json['id']?.toString() ?? '',
      firstName: firstName,
      lastName: lastName,
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      gender: gender,
      profileImageUrl: json['profile_image']?.toString(),
      membershipTier: json['membership_tier']?.toString() ?? 'Gold Member',
      rewardPoints: (json['reward_points'] as num?)?.toInt() ?? 1250,
      walletBalance: (json['wallet_balance'] as num?)?.toDouble() ?? 45.00,
      referralCode: json['referral_code']?.toString() ?? 'HANDY2026',
      isTwoFactorEnabled: json['is_two_factor_enabled'] == true,
      languageCode: json['language_code']?.toString() ?? 'en',
      pushNotificationsEnabled: json['push_notifications_enabled'] ?? true,
      biometricsEnabled: json['biometrics_enabled'] ?? true,
      memberSinceYear: memberYear,
    );
  }
}
