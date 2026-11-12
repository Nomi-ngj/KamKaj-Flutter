import 'package:flutter/material.dart';

import '../../design_system/components/components.dart';
import 'view_state.dart';

/// Renders the right widget for each [ViewState] so every screen handles
/// loading / empty / error / offline consistently.
class ViewStateBuilder<T> extends StatelessWidget {
  const ViewStateBuilder({
    super.key,
    required this.state,
    required this.builder,
    this.onRetry,
    this.emptyTitle = 'Nothing here yet',
    this.emptyMessage,
    this.emptyIcon = Icons.inbox_outlined,
  });

  final ViewState<T> state;
  final Widget Function(BuildContext context, T data) builder;
  final VoidCallback? onRetry;
  final String emptyTitle;
  final String? emptyMessage;
  final IconData emptyIcon;

  @override
  Widget build(BuildContext context) {
    final current = state;
    return switch (current) {
      ViewInitial<T>() || ViewLoading<T>() => const AppLoader(),
      ViewSuccess<T>(:final data) => builder(context, data),
      ViewRefreshing<T>(:final data) => builder(context, data),
      ViewEmpty<T>() => AppEmptyView(title: emptyTitle, message: emptyMessage, icon: emptyIcon),
      ViewFailure<T>() => AppErrorView(
          message: current.failure.message,
          onRetry: onRetry,
          icon: current.isOffline ? Icons.wifi_off_rounded : Icons.error_outline_rounded,
        ),
    };
  }
}
