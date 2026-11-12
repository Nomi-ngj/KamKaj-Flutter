import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/di/injection.dart';
import '../../../../core/base/submit_state.dart';
import '../../../../core/base/view_state.dart';
import '../../../../core/errors/failure.dart';
import '../../../auth/presentation/viewmodels/session_view_model.dart';
import '../../domain/entities/address.dart';

/// Saved addresses, shared by Dashboard header, Checkout and Saved Addresses.
final class AddressesViewModel extends Notifier<ViewState<List<Address>>> {
  @override
  ViewState<List<Address>> build() {
    // Reload when the signed-in user changes (sign out / sign in).
    ref.watch(sessionProvider.select((s) => s.user?.id));
    Future.microtask(load);
    return const ViewLoading();
  }

  Future<void> load() async {
    final previous = state.dataOrNull;
    state = previous == null ? const ViewLoading() : ViewRefreshing(previous);
    final result = await ref.read(getAddressesProvider).call();
    if (!ref.mounted) return;
    state = result.when(
      success: _toState,
      failure: (f) => ViewFailure(f),
    );
  }

  /// Returns the failure, or `null` on success.
  Future<Failure?> setDefault(String id) async {
    final result = await ref.read(setDefaultAddressProvider).call(id);
    if (!ref.mounted) return null;
    return result.when(
      success: (_) {
        // Re-apply ordering rules (default first).
        load();
        return null;
      },
      failure: (f) => f,
    );
  }

  ViewState<List<Address>> _toState(List<Address> list) =>
      list.isEmpty ? const ViewEmpty() : ViewSuccess(list);
}

final addressesProvider =
    NotifierProvider<AddressesViewModel, ViewState<List<Address>>>(AddressesViewModel.new);

/// The default delivery address, if any.
final defaultAddressProvider = Provider<Address?>((ref) {
  final list = ref.watch(addressesProvider).dataOrNull ?? const <Address>[];
  return list.where((a) => a.isDefault).firstOrNull ?? list.firstOrNull;
});

// ── Add / edit address ──────────────────────────────────────────────────────

final class AddressFormState extends Equatable {
  const AddressFormState({this.type = AddressType.home, this.submit = const SubmitState.idle()});

  final AddressType type;
  final SubmitState submit;

  AddressFormState copyWith({AddressType? type, SubmitState? submit}) =>
      AddressFormState(type: type ?? this.type, submit: submit ?? this.submit);

  @override
  List<Object?> get props => [type, submit];
}

final class AddressFormViewModel extends Notifier<AddressFormState> {
  @override
  AddressFormState build() => const AddressFormState();

  /// Pre-fills the form when editing.
  Address? addressFor(String id) =>
      ref.read(addressesProvider).dataOrNull?.where((a) => a.id == id).firstOrNull;

  void selectType(AddressType type) => state = state.copyWith(type: type);

  Future<bool> save({
    required String street,
    String? apartment,
    String? notes,
    String city = '',
    String? editingId,
  }) async {
    if (state.submit.isSubmitting) return false;
    state = state.copyWith(submit: const SubmitState.submitting());
    final draft = AddressDraft(
      type: state.type,
      street: street,
      city: city,
      apartment: apartment,
      driverNotes: notes,
    );
    final result = await ref.read(saveAddressProvider).call(draft, id: editingId);
    if (!ref.mounted) return false;
    if (result.isSuccess) {
      state = state.copyWith(submit: const SubmitState.success());
      await ref.read(addressesProvider.notifier).load();
      return true;
    }
    state = state.copyWith(submit: SubmitState.failed(result.failureOrNull!));
    return false;
  }
}

final addressFormViewModelProvider =
    NotifierProvider.autoDispose<AddressFormViewModel, AddressFormState>(AddressFormViewModel.new);
