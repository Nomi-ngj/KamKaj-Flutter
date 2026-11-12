import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/route_names.dart';
import '../../design_system/components/components.dart';

/// Shown for unknown routes / broken deep links.
class NotFoundPage extends StatelessWidget {
  const NotFoundPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppAppBar(),
      body: AppEmptyView(
        icon: Icons.travel_explore_rounded,
        title: 'Page not found',
        message: "The page you're looking for doesn't exist or has moved.",
        actionLabel: 'Go home',
        onAction: () => context.goNamed(RouteNames.home),
      ),
    );
  }
}
