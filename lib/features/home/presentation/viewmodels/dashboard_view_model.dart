import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/di/injection.dart';
import '../../../../core/base/view_state.dart';
import '../../../catalog/domain/entities/catalog_entities.dart';

final class DashboardViewModel extends Notifier<ViewState<DashboardData>> {
  @override
  ViewState<DashboardData> build() {
    Future.microtask(load);
    return const ViewLoading();
  }

  Future<void> load() async {
    final previous = state.dataOrNull;
    state = previous == null ? const ViewLoading() : ViewRefreshing(previous);
    final result = await ref.read(getDashboardProvider).call();
    if (!ref.mounted) return;
    state = result.when(
      success: (data) => data.isEmpty ? const ViewEmpty() : ViewSuccess(data),
      failure: (f) => ViewFailure(f),
    );
  }
}

final dashboardViewModelProvider =
    NotifierProvider<DashboardViewModel, ViewState<DashboardData>>(DashboardViewModel.new);
