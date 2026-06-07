import 'revenue_model.dart';
import 'revenue_service.dart';

class RevenueRepository {
  Future<RevenueReport> getRevenueReport({
    String? startDate,
    String? endDate,
  }) {
    return RevenueService.fetchRevenueReport(
      startDate: startDate,
      endDate: endDate,
    );
  }
}
