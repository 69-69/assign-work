import 'package:assign_erp/core/constants/app_validators.dart';
import 'package:formz/formz.dart';

enum EmailOrMobileValidationError { invalid }

class EmailOrMobile extends FormzInput<String, EmailOrMobileValidationError> {
  const EmailOrMobile.pure() : super.pure('');

  const EmailOrMobile.dirty([super.value = '']) : super.dirty();

  @override
  EmailOrMobileValidationError? validator(String? value) {
    return emailRegExp.hasMatch(value ?? '') ||
            /* Check Phone number */
            (value!.length >= 9 && onlyNumbersRegExp.hasMatch(value))
        ? null
        : EmailOrMobileValidationError.invalid;
  }
}
