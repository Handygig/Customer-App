class UserEntity {
  final int? id;
  final String? phoneNumber;
  final String? firebaseUid;
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? gender;
  final String? profileImage;
  final bool isProfileComplete;

  const UserEntity({
    this.id,
    this.phoneNumber,
    this.firebaseUid,
    this.firstName,
    this.lastName,
    this.email,
    this.gender,
    this.profileImage,
    required this.isProfileComplete,
  });

  String get fullName {
    return [firstName, lastName]
        .where((value) => value != null && value!.trim().isNotEmpty)
        .map((value) => value!.trim())
        .join(' ');
  }
}
