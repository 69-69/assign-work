import 'package:assign_erp/core/util/str_util.dart';
import 'package:formz/formz.dart';

enum AddressValidationError { invalid }

class Address extends FormzInput<String, AddressValidationError> {
  const Address.pure() : super.pure('');

  const Address.dirty([super.value = '']) : super.dirty();

  @override
  AddressValidationError? validator(String? value) {
    return value.isNullOrEmpty ? AddressValidationError.invalid : null;
  }
}
