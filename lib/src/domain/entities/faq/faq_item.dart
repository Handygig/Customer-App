class FaqItem {
  final int id;
  final String question;
  final String answer;
  final String category;
  final int order;
  final bool isActive;

  const FaqItem({
    required this.id,
    required this.question,
    required this.answer,
    this.category = 'General',
    this.order = 0,
    this.isActive = true,
  });

  factory FaqItem.fromJson(Map<String, dynamic> json) {
    return FaqItem(
      id: _parseInt(json['id']),
      question: (json['question'] ?? '').toString().trim(),
      answer: (json['answer'] ?? '').toString().trim(),
      category: (json['category'] ?? 'General').toString().trim(),
      order: _parseInt(json['order']),
      isActive: json['is_active'] == null ? true : (json['is_active'] == true || json['is_active'] == 1 || json['is_active'] == '1'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'answer': answer,
      'category': category,
      'order': order,
      'is_active': isActive,
    };
  }

  FaqItem copyWith({
    int? id,
    String? question,
    String? answer,
    String? category,
    int? order,
    bool? isActive,
  }) {
    return FaqItem(
      id: id ?? this.id,
      question: question ?? this.question,
      answer: answer ?? this.answer,
      category: category ?? this.category,
      order: order ?? this.order,
      isActive: isActive ?? this.isActive,
    );
  }

  static int _parseInt(dynamic val, [int fallback = 0]) {
    if (val == null) return fallback;
    if (val is num) return val.toInt();
    return int.tryParse(val.toString()) ?? fallback;
  }

  /// Default baseline FAQs to provide immediate offline availability.
  static const List<FaqItem> defaultFaqs = [
    FaqItem(
      id: 1,
      question: 'How do I book a home maintenance service?',
      answer:
          'Navigate to the Home or Search tab, select your required service (e.g. Plumbing, AC Repair), pick a convenient date & time slot, choose your property, and confirm payment.',
      category: 'Booking',
      order: 1,
    ),
    FaqItem(
      id: 2,
      question: 'Can I cancel or reschedule my booking?',
      answer:
          'Yes! Go to the Jobs tab, select your upcoming booking, and tap "Reschedule" or "Cancel Booking". Cancellations made 2 hours prior are 100% free of charge.',
      category: 'Booking',
      order: 2,
    ),
    FaqItem(
      id: 3,
      question: 'What if the technician doesn\'t arrive on time?',
      answer:
          'All service providers are GPS tracked in real-time. If there is a delay over 15 minutes, our 24/7 support team automatically reaches out and provides a \$10 service credit voucher.',
      category: 'Service & Safety',
      order: 3,
    ),
    FaqItem(
      id: 4,
      question: 'Are service technicians verified and insured?',
      answer:
          'Absolutely. Every professional undergoes background screening, identity verification, and carries comprehensive service liability coverage.',
      category: 'Safety & Verification',
      order: 4,
    ),
    FaqItem(
      id: 5,
      question: 'How do payments and service guarantees work?',
      answer:
          'Payments are processed securely via encrypted card transactions or wallet balance. We hold funds in escrow until the service is completed to your satisfaction, backed by our 100% Happiness Guarantee.',
      category: 'Payments',
      order: 5,
    ),
    FaqItem(
      id: 6,
      question: 'Can I request emergency or same-day repairs?',
      answer:
          'Yes, our 24/7 emergency dispatch line is available for urgent electrical, plumbing, or lockouts. Dispatch times average between 30 to 45 minutes.',
      category: 'Emergency',
      order: 6,
    ),
  ];
}
