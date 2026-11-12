import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/base/view_state_builder.dart';
import '../../../../design_system/assets/app_images.dart';
import '../../../../design_system/components/components.dart';
import '../../../../design_system/tokens/tokens.dart';
import '../../domain/entities/service_entities.dart';
import '../viewmodels/services_view_model.dart';

/// "Home" frame (2453:233): Services carousel + Book A Ride Now.
class ServicesPage extends ConsumerWidget {
  const ServicesPage({super.key});

  static const _images = {
    'express_ride': AppImages.serviceExpressRide,
    'delivery_package': AppImages.serviceDeliveryPackage,
    'sedan': AppImages.vehicleSedan,
    'van': AppImages.vehicleVan,
    'truck': AppImages.vehicleTruck,
  };

  static String _image(String key) => _images[key] ?? AppImages.serviceExpressRide;

  Future<void> _confirmRide(BuildContext context, WidgetRef ref, VehicleType vehicle) async {
    ref.read(servicesViewModelProvider.notifier).selectVehicle(vehicle.id);
    final confirmed = await AppDialog.confirm(
      context,
      title: 'Book ${vehicle.name}?',
      message: '${vehicle.capacity}. A nearby driver will be matched to your default address.',
      confirmLabel: 'Book Now',
      icon: Icons.directions_car_filled_outlined,
    );
    if (!confirmed || !context.mounted) return;
    final rideId = await ref.read(servicesViewModelProvider.notifier).book(vehicle);
    if (!context.mounted) return;
    final error = ref.read(servicesViewModelProvider).booking.errorMessage;
    AppToast.show(context, rideId != null ? 'Ride requested! Looking for a driver…' : error ?? '');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(servicesViewModelProvider);

    return Scaffold(
      appBar: const AppAppBar(title: 'Services'),
      body: ViewStateBuilder<ServicesData>(
        state: state.data,
        onRetry: ref.read(servicesViewModelProvider.notifier).load,
        builder: (context, data) => ListView(
          padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
          children: [
            const AppAssetImage(
              path: AppImages.mapPlaceholder,
              height: AppDimensions.checkoutMapHeight,
              width: double.infinity,
              fit: BoxFit.cover,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(AppRadius.lg)),
              placeholderIcon: Icons.map_outlined,
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(AppSpacing.page, AppSpacing.xxl, AppSpacing.page, AppSpacing.md),
              child: AppSectionHeader(title: 'Services'),
            ),
            SizedBox(
              height: AppDimensions.serviceCardImageHeight + AppSpacing.giant,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page, vertical: AppSpacing.xs),
                itemCount: data.services.length,
                separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.lg),
                itemBuilder: (_, i) {
                  final service = data.services[i];
                  return SizedBox(
                    width: AppDimensions.serviceCardWidth,
                    child: AppCard(
                      padding: EdgeInsets.zero,
                      onTap: () => AppToast.show(context, '${service.name} is coming soon'),
                      child: Column(
                        children: [
                          Expanded(
                            child: AppAssetImage(
                              path: _image(service.imageKey),
                              width: AppDimensions.serviceCardWidth,
                              fit: BoxFit.cover,
                              semanticLabel: service.name,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: Text(service.name, style: AppTypography.caption1),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(AppSpacing.page, AppSpacing.xxl, AppSpacing.page, AppSpacing.md),
              child: AppSectionHeader(title: 'Book A Ride Now'),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
              child: Row(
                children: [
                  for (var i = 0; i < data.vehicles.length; i++) ...[
                    if (i > 0) const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: _VehicleCard(
                        vehicle: data.vehicles[i],
                        image: _image(data.vehicles[i].imageKey),
                        selected: state.selectedVehicleId == data.vehicles[i].id,
                        isBooking: state.booking.isSubmitting &&
                            state.selectedVehicleId == data.vehicles[i].id,
                        onTap: () => _confirmRide(context, ref, data.vehicles[i]),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VehicleCard extends StatelessWidget {
  const _VehicleCard({
    required this.vehicle,
    required this.image,
    required this.selected,
    required this.isBooking,
    required this.onTap,
  });

  final VehicleType vehicle;
  final String image;
  final bool selected;
  final bool isBooking;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      label: 'Book ${vehicle.name}',
      excludeSemantics: true,
      child: AppCard(
        onTap: isBooking ? null : onTap,
        color: AppColors.primarySoft,
        borderRadius: AppRadius.brMd,
        border: Border.all(color: selected ? AppColors.primary : AppColors.primaryBorder),
        shadows: const [],
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          children: [
            SizedBox(
              height: AppDimensions.vehicleCardHeight / 2,
              child: isBooking
                  ? const AppLoader()
                  : AppAssetImage(
                      path: image,
                      semanticLabel: vehicle.name,
                      placeholderIcon: Icons.directions_car_outlined,
                    ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              vehicle.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.caption2SemiBold.copyWith(color: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }
}
