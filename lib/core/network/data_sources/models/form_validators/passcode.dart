import 'package:assign_erp/core/constants/app_validators.dart';
import 'package:formz/formz.dart';

enum PasscodeValidationError { invalid }

class Passcode extends FormzInput<String, PasscodeValidationError> {
  /// {@macro Passcode}
  const Passcode.pure() : super.pure('');

  /// {@macro Passcode}
  const Passcode.dirty([super.value = '']) : super.dirty();

  @override
  PasscodeValidationError? validator(String? value) {
    return passcodeRegExp.hasMatch(value ?? '')
        ? null
        : PasscodeValidationError.invalid;
  }
}
