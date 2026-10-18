import 'package:dartz/dartz.dart';
import 'package:customer_app/core/errors/failures.dart';
import 'package:customer_app/src/domain/entities/faq/faq_item.dart';

abstract class FaqRepository {
  Future<Either<Failure, List<FaqItem>>> getFaqs({
    String? category,
    String? search,
  });

  Future<Either<Failure, List<String>>> getCategories();
}
