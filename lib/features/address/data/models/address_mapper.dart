import '../../../../core/utils/json_reader.dart';
import '../../domain/entities/address.dart';

abstract final class AddressMapper {
  static Address fromJson(Map<String, Object?> json) => Address(
        id: json.readString('id'),
        type: AddressType.values.firstWhere(
          (t) => t.name == json.readStringOrNull('type'),
          orElse: () => AddressType.other,
        ),
        label: json.readStringOrNull('label') ?? '',
        street: json.readString('street'),
        city: json.readStringOrNull('city') ?? '',
        apartment: json.readStringOrNull('apartment'),
        driverNotes: json.readStringOrNull('driverNotes'),
        isDefault: json.readBool('isDefault'),
      );

  static Map<String, Object?> draftToJson(AddressDraft draft) => {
        'type': draft.type.name,
        'street': draft.street.trim(),
        'city': draft.city.trim(),
        if (draft.apartment?.trim().isNotEmpty ?? false) 'apartment': draft.apartment!.trim(),
        if (draft.driverNotes?.trim().isNotEmpty ?? false) 'driverNotes': draft.driverNotes!.trim(),
      };
}
