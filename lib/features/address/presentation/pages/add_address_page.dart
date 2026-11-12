import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/validators.dart';
import '../../../../design_system/assets/app_images.dart';
import '../../../../design_system/components/components.dart';
import '../../../../design_system/tokens/tokens.dart';
import '../../domain/entities/address.dart';
import '../viewmodels/address_view_models.dart';
import '../widgets/address_card.dart';

/// Add New Address / Edit Address.
class AddAddressPage extends ConsumerStatefulWidget {
  const AddAddressPage({super.key, this.addressId});

  /// When set, the page edits that address.
  final String? addressId;

  @override
  ConsumerState<AddAddressPage> createState() => _AddAddressPageState();
}

class _AddAddressPageState extends ConsumerState<AddAddressPage> {
  final _formKey = GlobalKey<FormState>();
  final _street = TextEditingController();
  final _apartment = TextEditingController();
  final _notes = TextEditingController();
  String _city = '';

  bool get _isEditing => widget.addressId != null;

  @override
  void initState() {
    super.initState();
    final id = widget.addressId;
    if (id == null) return;
    final existing = ref.read(addressFormViewModelProvider.notifier).addressFor(id);
    if (existing == null) return;
    _street.text = existing.street;
    _apartment.text = existing.apartment ?? '';
    _notes.text = existing.driverNotes ?? '';
    _city = existing.city;
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => ref.read(addressFormViewModelProvider.notifier).selectType(existing.type),
    );
  }

  @override
  void dispose() {
    _street.dispose();
    _apartment.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final ok = await ref.read(addressFormViewModelProvider.notifier).save(
          street: _street.text,
          apartment: _apartment.text,
          notes: _notes.text,
          city: _city,
          editingId: widget.addressId,
        );
    if (!mounted) return;
    if (ok) {
      AppToast.show(context, _isEditing ? 'Address updated' : 'Address saved');
      context.pop();
    } else {
      final message = ref.read(addressFormViewModelProvider).submit.errorMessage;
      if (message != null) AppToast.show(context, message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(addressFormViewModelProvider);
    final viewModel = ref.read(addressFormViewModelProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppAppBar(
        title: _isEditing ? 'Edit Address' : 'Add New Address',
        backgroundColor: AppColors.surface,
      ),
      body: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          children: [
            const _MapSection(),
            Transform.translate(
              offset: const Offset(0, -AppSpacing.xxl),
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppRadius.sheetTop,
                  boxShadow: AppShadows.topBar,
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.page,
                    AppSpacing.md,
                    AppSpacing.page,
                    AppSpacing.xxl,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Container(
                            width: AppDimensions.dragHandleWidth,
                            height: AppDimensions.dragHandleHeight,
                            decoration: const BoxDecoration(
                              color: AppColors.border,
                              borderRadius: AppRadius.brPill,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xxl),
                        Text('Save as', style: AppTypography.subhead),
                        const SizedBox(height: AppSpacing.lg),
                        Row(
                          children: [
                            for (final type in AddressType.values) ...[
                              if (type != AddressType.values.first)
                                const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: AppChoiceChip(
                                  label: type.label,
                                  icon: addressTypeIcon(type),
                                  selected: state.type == type,
                                  onTap: () => viewModel.selectType(type),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xxxl),
                        Text('Location Details', style: AppTypography.titleMedium),
                        const SizedBox(height: AppSpacing.xxl),
                        AppTextField(
                          controller: _street,
                          style: AppTextFieldStyle.outlined,
                          label: 'Street Address',
                          hint: '123 Market Street',
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.streetAddressLine1],
                          validator: (v) => Validators.required(v, field: 'Street address'),
                        ),
                        const SizedBox(height: AppSpacing.xxl),
                        AppTextField(
                          controller: _apartment,
                          style: AppTextFieldStyle.outlined,
                          label: 'Apt, Suite, Floor (Optional)',
                          hint: 'E.g. Apt 4B',
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.streetAddressLine2],
                        ),
                        const SizedBox(height: AppSpacing.xxl),
                        AppTextField(
                          controller: _notes,
                          style: AppTextFieldStyle.outlined,
                          label: 'Driver Notes',
                          hint: 'E.g. Please leave by the side gate',
                          maxLines: 3,
                          minLines: 3,
                          keyboardType: TextInputType.multiline,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.page,
            AppSpacing.lg,
            AppSpacing.page,
            AppSpacing.lg + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: AppButton(
            label: 'Save Address',
            trailingIcon: Icons.check_rounded,
            variant: AppButtonVariant.secondary,
            size: AppButtonSize.large,
            isLoading: state.submit.isSubmitting,
            onPressed: _save,
          ),
        ),
      ),
    );
  }
}

class _MapSection extends StatelessWidget {
  const _MapSection();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppDimensions.mapHeight,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const AppAssetImage(
            path: AppImages.mapPlaceholder,
            fit: BoxFit.cover,
            semanticLabel: 'Map',
            placeholderIcon: Icons.map_outlined,
          ),
          const Center(
            child: Icon(
              Icons.location_on_rounded,
              size: AppDimensions.massiveIcon,
              color: AppColors.secondary,
              semanticLabel: 'Selected location',
            ),
          ),
          PositionedDirectional(
            top: AppSpacing.xxl,
            end: AppSpacing.xxl,
            child: AppCircleIconButton(
              icon: Icons.my_location_rounded,
              tooltip: 'Use my location',
              onPressed: () => AppToast.show(
                context,
                'Location services will be enabled with the maps integration.',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
