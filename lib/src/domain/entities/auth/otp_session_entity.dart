class OtpSessionEntity {
  final String verificationId;
  final int? forceResendingToken;

  const OtpSessionEntity({
    required this.verificationId,
    this.forceResendingToken,
  });
}
