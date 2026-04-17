import '../models/dashboard_item.dart';

abstract class IDashboardRepository {
  Future<List<DashboardItem>> getDashboardItems();
}
