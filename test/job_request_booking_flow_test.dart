import 'package:flutter_test/flutter_test.dart';
import 'package:customer_app/src/data/models/services/service_model.dart';
import 'package:customer_app/src/data/models/job_requests/job_request_model.dart';

void main() {
  group('Service Catalog Pricing-Free Tests', () {
    test('ServiceModel parses correctly without any price fields', () {
      final json = {
        'id': 10,
        'title': 'Plumbing Pipe Repair',
        'name': 'Plumbing Pipe Repair',
        'category_id': 2,
        'category': 'Plumbing',
        'description': 'Fix leaking pipes and pipe replacement',
        'image_url': 'https://example.com/plumbing.png',
        'is_active': true,
      };

      final service = ServiceModel.fromJson(json);

      expect(service.id, 10);
      expect(service.title, 'Plumbing Pipe Repair');
      expect(service.category, 'Plumbing');
      expect(service.isActive, true);
    });
  });

  group('Job Request Booking & Payment Method Tests', () {
    test('toStoreJson formats card payment with card_id', () {
      final preferredDate = DateTime(2026, 11, 15, 10, 30);
      final payload = JobRequestModel.toStoreJson(
        propertyId: 5,
        serviceCategoryId: 2,
        description: 'Kitchen sink faucet replacement',
        preferredDate: preferredDate,
        paymentMethod: 'card',
        cardId: 12,
      );

      expect(payload['property_id'], 5);
      expect(payload['service_category_id'], 2);
      expect(payload['description'], 'Kitchen sink faucet replacement');
      expect(payload['preferred_date'], '2026-11-15 10:30:00');
      expect(payload['payment_method'], 'card');
      expect(payload['card_id'], 12);
    });

    test('toStoreJson formats cash payment without card_id', () {
      final preferredDate = DateTime(2026, 11, 20, 14, 0);
      final payload = JobRequestModel.toStoreJson(
        propertyId: 8,
        serviceCategoryId: 3,
        description: 'House wall painting',
        preferredDate: preferredDate,
        paymentMethod: 'cash',
      );

      expect(payload['property_id'], 8);
      expect(payload['service_category_id'], 3);
      expect(payload['description'], 'House wall painting');
      expect(payload['payment_method'], 'cash');
      expect(payload.containsKey('card_id'), isFalse);
    });

    test('JobRequestModel parses payment_method and card correctly from JSON', () {
      final json = {
        'id': 101,
        'description': 'AC maintenance',
        'preferred_date': '2026-11-20T14:00:00.000Z',
        'status': 'pending',
        'payment_method': 'card',
        'card_id': 7,
        'card': {
          'id': 7,
          'card_type': 'visa',
          'masked_card_number': '**** **** **** 1234',
          'expiry_date': '08/29',
          'card_holder_name': 'Jane Doe',
          'is_default': true,
          'is_frozen': false,
        },
      };

      final model = JobRequestModel.fromJson(json);

      expect(model.id, 101);
      expect(model.paymentMethod, 'card');
      expect(model.isCard, isTrue);
      expect(model.isCash, isFalse);
      expect(model.cardId, 7);
      expect(model.card?.lastFourDigits, '1234');
    });
  });
}
