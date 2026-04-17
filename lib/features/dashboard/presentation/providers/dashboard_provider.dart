import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/injection_container.dart';
import '../../domain/interfaces/idashboard_repository.dart';
import '../../domain/models/dashboard_item.dart';

final dashboardItemsProvider = FutureProvider<List<DashboardItem>>((ref) async {
  final repository = sl<IDashboardRepository>();
  return await repository.getDashboardItems();
});
