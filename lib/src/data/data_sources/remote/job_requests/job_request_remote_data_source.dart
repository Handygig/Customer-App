import 'package:customer_app/src/data/models/job_requests/job_request_model.dart';
import 'package:customer_app/src/data/models/job_requests/quotation_model.dart';

abstract class JobRequestRemoteDataSource {
  Future<List<JobRequestModel>> getJobRequests();
  Future<JobRequestModel> getJobRequest(int id);
  Future<JobRequestModel> createJobRequest({
    int? propertyId,
    required int serviceCategoryId,
    required String description,
    required DateTime preferredDate,
    String paymentMethod = 'card',
    int? cardId,
  });
  Future<void> cancelJobRequest(int id);
  Future<List<QuotationModel>> getJobRequestQuotations(int id);
  Future<void> acceptQuotation(int quotationId);
  Future<QuotationModel> simulateQuotation(int jobRequestId);
}
