import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/di/injection.dart';
import '../../../../core/base/submit_state.dart';
import '../../../../core/base/view_state.dart';
import '../../domain/entities/service_entities.dart';

final class ServicesState extends Equatable {
  const ServicesState({
    this.data = const ViewLoading(),
    this.selectedVehicleId,
    this.booking = const SubmitState.idle(),
  });

  final ViewState<ServicesData> data;
  final String? selectedVehicleId;
  final SubmitState booking;

  ServicesState copyWith({
    ViewState<ServicesData>? data,
    String? selectedVehicleId,
    SubmitState? booking,
  }) =>
      ServicesState(
        data: data ?? this.data,
        selectedVehicleId: selectedVehicleId ?? this.selectedVehicleId,
        booking: booking ?? this.booking,
      );

  @override
  List<Object?> get props => [data, selectedVehicleId, booking];
}

final class ServicesViewModel extends Notifier<ServicesState> {
  @override
  ServicesState build() {
    Future.microtask(load);
    return const ServicesState();
  }

  Future<void> load() async {
    state = state.copyWith(data: const ViewLoading());
    final result = await ref.read(getServicesProvider).call();
    if (!ref.mounted) return;
    state = state.copyWith(
      data: result.when(success: (v) => ViewSuccess(v), failure: (f) => ViewFailure(f)),
    );
  }

  void selectVehicle(String id) => state = state.copyWith(selectedVehicleId: id);

  /// Returns the ride reference, or `null` on failure.
  Future<String?> book(VehicleType vehicle) async {
    if (state.booking.isSubmitting) return null;
    state = state.copyWith(booking: const SubmitState.submitting(), selectedVehicleId: vehicle.id);
    final result = await ref.read(requestRideProvider).call(vehicle);
    if (!ref.mounted) return null;
    state = state.copyWith(
      booking: result.when(
        success: (_) => const SubmitState.success(),
        failure: (f) => SubmitState.failed(f),
      ),
    );
    return result.valueOrNull;
  }
}

final servicesViewModelProvider =
    NotifierProvider.autoDispose<ServicesViewModel, ServicesState>(ServicesViewModel.new);
