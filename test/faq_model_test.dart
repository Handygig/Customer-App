import 'package:flutter_test/flutter_test.dart';
import 'package:customer_app/src/domain/entities/faq/faq_item.dart';

void main() {
  group('FaqItem Model Tests', () {
    test('should parse FaqItem from JSON successfully', () {
      final json = {
        'id': 10,
        'question': 'How do I pay?',
        'answer': 'Use credit card or wallet.',
        'category': 'Payments',
        'order': 3,
        'is_active': true,
      };

      final faq = FaqItem.fromJson(json);

      expect(faq.id, 10);
      expect(faq.question, 'How do I pay?');
      expect(faq.answer, 'Use credit card or wallet.');
      expect(faq.category, 'Payments');
      expect(faq.order, 3);
      expect(faq.isActive, true);
    });

    test('should handle string and integer variants gracefully', () {
      final json = {
        'id': '42',
        'question': 'Are technicians background checked?',
        'answer': 'Yes, 100% verified.',
        'category': 'Safety',
        'order': '1',
        'is_active': 1,
      };

      final faq = FaqItem.fromJson(json);

      expect(faq.id, 42);
      expect(faq.order, 1);
      expect(faq.isActive, true);
    });

    test('defaultFaqs contains all baseline questions', () {
      expect(FaqItem.defaultFaqs.length, greaterThanOrEqualTo(4));
      expect(
        FaqItem.defaultFaqs.any((f) => f.question.contains('book a home maintenance service')),
        isTrue,
      );
    });
  });
}
