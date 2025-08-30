import 'package:assign_erp/core/constants/app_validators.dart';
import 'package:formz/formz.dart';

enum EmailValidationError { invalid }

class Email extends FormzInput<String, EmailValidationError> {
  const Email.pure() : super.pure('');
  const Email.dirty([super.value = '']) : super.dirty();

  @override
  EmailValidationError? validator(String? value) {
    return emailRegExp.hasMatch(value ?? '')
        ? null
        : EmailValidationError.invalid;
  }

  /*@override
  UsernameValidationError? validator(String value) {
    if (value.isEmpty) return UsernameValidationError.empty;
    return null;
  }*/
}
